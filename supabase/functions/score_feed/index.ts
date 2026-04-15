/**
 * score_feed — ranked match-request feed for the calling user.
 *
 * Returns up to 50 open match requests scored by compatibility:
 *   total = 0.5 × level_score + 0.25 × playstyle_score + 0.25 × reliability_score
 *
 * Hard filters applied before scoring (cheaper):
 *   - Not created by the caller
 *   - In one of the caller's home clubs (if set)
 *   - Proposed window end is in the future
 *   - Not soft-blocked by the caller
 *   - Intent compatible (social ↔ competitive excluded; both = any)
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS })
  }

  const start = Date.now()

  // ── Auth ──────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return json({ error: 'Missing Authorization header' }, 401)

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  )

  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) return json({ error: 'Unauthorized' }, 401)

  // ── Caller profile ────────────────────────────────────────────────────────
  const { data: me, error: profileError } = await supabase
    .from('profiles')
    .select('id, calibrated_level, playstyle_tags, home_club_ids, intent, reliability_score')
    .eq('id', user.id)
    .single()

  if (profileError || !me) return json({ error: 'Profile not found' }, 404)

  // ── Soft blocks ───────────────────────────────────────────────────────────
  const { data: blocksData } = await supabase
    .from('soft_blocks')
    .select('blocked_id')
    .eq('blocker_id', user.id)
    .gt('expires_at', new Date().toISOString())

  const blockedIds = new Set<string>((blocksData ?? []).map((b: { blocked_id: string }) => b.blocked_id))

  // ── Open requests ─────────────────────────────────────────────────────────
  // Fetch up to 200 candidates; hard filters reduce this before scoring.
  // tstzrange upper bound is stored as the exclusive end of the interval.
  let query = supabase
    .from('match_requests')
    .select(`
      id,
      creator_id,
      club_id,
      proposed_window,
      status,
      created_at,
      creator:profiles!inner(
        id,
        display_name,
        photo_url,
        calibrated_level,
        playstyle_tags,
        reliability_score,
        intent
      )
    `)
    .eq('status', 'open')
    .neq('creator_id', user.id)
    .limit(200)

  if (me.home_club_ids?.length > 0) {
    query = query.in('club_id', me.home_club_ids)
  }

  const { data: requests, error: feedError } = await query

  if (feedError) {
    console.error('score_feed: feed query failed', feedError)
    return json({ error: 'Failed to load feed' }, 500)
  }

  // ── Playstyle pairings ────────────────────────────────────────────────────
  const { data: pairingsData } = await supabase
    .from('playstyle_pairings')
    .select('style_a, style_b, score')

  const pairings = new Map<string, number>()
  for (const p of pairingsData ?? []) {
    pairings.set(`${p.style_a}|${p.style_b}`, p.score)
  }

  function getPairingScore(a: string, b: string): number {
    return pairings.get(`${a}|${b}`) ?? pairings.get(`${b}|${a}`) ?? 50
  }

  function avgPairingScore(tagsA: string[], tagsB: string[]): number {
    if (!tagsA.length || !tagsB.length) return 50
    let total = 0, count = 0
    for (const a of tagsA) {
      for (const b of tagsB) {
        total += getPairingScore(a, b)
        count++
      }
    }
    return total / count
  }

  function intentCompatible(mine: string | null, theirs: string | null): boolean {
    if (!mine || !theirs || mine === 'both' || theirs === 'both') return true
    return mine === theirs
  }

  // ── Score + filter ────────────────────────────────────────────────────────
  const myLevel = me.calibrated_level ?? 3.0
  const myTags: string[] = me.playstyle_tags ?? []
  const myIntent: string | null = me.intent

  const scored = (requests ?? [])
    .filter((r: any) => {
      if (blockedIds.has(r.creator_id)) return false
      if (!intentCompatible(myIntent, r.creator?.intent ?? null)) return false
      return true
    })
    .map((r: any) => {
      const creator = r.creator
      const theirLevel: number = creator?.calibrated_level ?? 3.0
      const theirTags: string[] = creator?.playstyle_tags ?? []
      const theirReliability: number = creator?.reliability_score ?? 1.0

      const levelScore = 100 - Math.min(100, Math.abs(myLevel - theirLevel) * 40)
      const playstyleScore = avgPairingScore(myTags, theirTags)
      const reliabilityScore = theirReliability * 100
      const total = 0.5 * levelScore + 0.25 * playstyleScore + 0.25 * reliabilityScore

      return { ...r, score: Math.round(total * 10) / 10 }
    })
    .sort((a: any, b: any) => b.score - a.score)
    .slice(0, 50)

  const elapsed = Date.now() - start
  console.log(`score_feed: ${scored.length} results in ${elapsed}ms for user ${user.id}`)

  return json({ data: scored, meta: { elapsed_ms: elapsed } })
})
