/**
 * list_matches — paginated listing of match requests visible to the caller.
 *
 * GET /list_matches?source=all&page=0
 *
 * Query params:
 *   source  "mine" | "feed" | "all" (default: "all")
 *             mine → caller's own requests (any status)
 *             feed → other users' open requests
 *             all  → own (any status) + others' open
 *   page    integer ≥ 0 (default: 0)
 *
 * Returns up to 10 match requests per page ordered by proposed_at ASC
 * (earliest window start first). Each row includes the creator's public
 * profile fields and the club name.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const PAGE_SIZE = 10

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  })
}

// Local dev: when no Authorization header is provided fall back to seed user.
const LOCAL_DEV_USER_ID = 'aaaaaaaa-0000-0000-0000-000000000001'

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS })
  }

  // ── Auth ────────────────────────────────────────────────────────────────────
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

  // ── Query params ────────────────────────────────────────────────────────────
  const url = new URL(req.url)
  const source = url.searchParams.get('source') ?? 'all'
  const page = Math.max(0, parseInt(url.searchParams.get('page') ?? '0', 10) || 0)

  if (!['mine', 'feed', 'all'].includes(source)) {
    return json({ error: 'source must be "mine", "feed", or "all"' }, 400)
  }

  const offset = page * PAGE_SIZE

  // ── Build query ─────────────────────────────────────────────────────────────
  // Always apply explicit visibility filters so behavior is identical between
  // local dev (service-role, no RLS) and production (anon key + RLS).
  let query = supabase
    .from('match_requests')
    .select(
      `
      id,
      creator_id,
      club_id,
      proposed_window,
      proposed_at,
      status,
      created_at,
      creator:profiles!inner(
        id,
        display_name,
        photo_url,
        calibrated_level,
        playstyle_tags,
        reliability_score
      ),
      club:clubs!inner(
        id,
        name
      )
    `,
      { count: 'exact' },
    )
    .order('proposed_at', { ascending: true })
    .range(offset, offset + PAGE_SIZE - 1)

  if (source === 'mine') {
    query = query.eq('creator_id', userId)
  } else if (source === 'feed') {
    query = query.eq('status', 'open').neq('creator_id', userId)
  } else {
    // 'all': own requests (any status) OR other users' open requests
    query = query.or(
      `creator_id.eq.${userId},and(status.eq.open,creator_id.neq.${userId})`,
    )
  }

  const { data, error, count } = await query

  if (error) {
    console.error('list_matches: query failed', error)
    return json({ error: 'Failed to load matches' }, 500)
  }

  const hasMore = (data?.length ?? 0) === PAGE_SIZE

  console.log(`list_matches: page=${page} source=${source} rows=${data?.length} total=${count} user=${userId}`)

  return json({
    data,
    meta: {
      page,
      page_size: PAGE_SIZE,
      total: count,
      has_more: hasMore,
      source,
    },
  })
})
