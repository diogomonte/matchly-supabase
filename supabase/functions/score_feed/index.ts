/**
 * score_feed — ranked match-request feed for the calling user.
 *
 * Returns:
 *   own  — caller's own open requests ordered by proposed_at ASC (no scoring)
 *   feed — other users' open requests scored by compatibility, top 50
 *
 * Feed score formula:
 *   total = 0.5 × level_score + 0.25 × playstyle_score + 0.25 × reliability_score
 *
 * Hard filters applied to feed before scoring (cheaper):
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

// Local dev: when no Authorization header is provided and the stack is running
// on 127.0.0.1, fall back to this seed user so the API is usable without auth.
const LOCAL_DEV_USER_ID = 'aaaaaaaa-0000-0000-0000-000000000001'

const REQUEST_SELECT = `
  id,
  creator_id,
  club_id,
  proposed_window,
  proposed_at,
  status,
  created_at,
  creator:public_profiles!creator_id(
    id,
    display_name,
    photo_url,
    calibrated_level,
    playstyle_tags,
    reliability_score,
    intent
  )
`

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS })
  }

  const start = Date.now()

  // ── Auth ──────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization')
  const isLocal = Deno.env.get('LOCAL_DEV') === 'true'
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
  const isAnonKeyBearer = authHeader === `Bearer ${anonKey}`

  let userId: string
  let supabase: ReturnType<typeof createClient>

  if (isLocal && (!authHeader || isAnonKeyBearer)) {
    userId = LOCAL_DEV_USER_ID
    supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )
  } else {
    if (!authHeader) return json({ error: 'Missing Authorization header' }, 401)
    supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) return json({ error: 'Unauthorized' }, 401)
    userId = user.id
  }

  // ── Caller profile + soft blocks (parallel) ───────────────────────────────
  const [profileResult, blocksResult] = await Promise.all([
    supabase
      .from('profiles')
      .select('id, calibrated_level, playstyle_tags, intent, reliability_score')
      .eq('id', userId)
      .single(),
    supabase
      .from('soft_blocks')
      .select('blocked_id')
      .eq('blocker_id', userId)
      .gt('expires_at', new Date().toISOString()),
  ])

  if (profileResult.error || !profileResult.data) {
    return json({ error: 'Profile not found' }, 404)
  }
  const me = profileResult.data
  const blockedIds = new Set<string>(
    (blocksResult.data ?? []).map((b: { blocked_id: string }) => b.blocked_id),
  )

  // ── Own open requests + others' open requests (parallel) ──────────────────
  let othersQuery = supabase
    .from('match_requests')
    .select(REQUEST_SELECT)
    .eq('status', 'open')
    .neq('creator_id', userId)
    .limit(200)

  const [ownResult, othersResult, pairingsResult] = await Promise.all([
    supabase
      .from('match_requests')
      .select(REQUEST_SELECT)
      .eq('status', 'open')
      .eq('creator_id', userId)
      .order('proposed_at', { ascending: true }),
    othersQuery,
    supabase
      .from('playstyle_pairings')
      .select('style_a, style_b, score'),
  ])

  if (ownResult.error) {
    console.error('score_feed: own-requests query failed', ownResult.error)
    return json({ error: 'Failed to load own requests' }, 500)
  }

  if (othersResult.error) {
    console.error('score_feed: feed query failed', othersResult.error)
    return json({ error: 'Failed to load feed' }, 500)
  }

  // ── Playstyle pairing lookup ──────────────────────────────────────────────
  const pairings = new Map<string, number>()
  for (const p of pairingsResult.data ?? []) {
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

  // ── Score + filter feed ───────────────────────────────────────────────────
  const myLevel = me.calibrated_level ?? 3.0
  const myTags: string[] = me.playstyle_tags ?? []
  const myIntent: string | null = me.intent

  const scoredFeed = (othersResult.data ?? [])
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

  const own = ownResult.data ?? []

  const elapsed = Date.now() - start
  console.log(
    `score_feed: own=${own.length} feed=${scoredFeed.length} in ${elapsed}ms for user ${userId}`,
  )

  return json({
    data: { own, feed: scoredFeed },
    meta: { elapsed_ms: elapsed },
  })
})
