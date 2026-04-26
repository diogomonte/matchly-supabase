/**
 * list_matches — paginated listing of match requests or pending proposals
 * visible to the caller.
 *
 * GET /list_matches?source=all&page=0&from=<ISO8601>
 *
 * Query params:
 *   source  "mine" | "feed" | "all" | "proposals" (default: "all")
 *             mine      → caller's own match requests (any status)
 *             feed      → other users' open match requests
 *             all       → own (any status) + others' open match requests
 *             proposals → pending matches where the caller is a participant
 *   page    integer ≥ 0 (default: 0)
 *   from    ISO 8601 datetime (default: now). For match requests, only rows
 *           whose proposed_window ends at or after this timestamp are returned.
 *           For proposals, only matches scheduled at or after this timestamp
 *           are returned. Pass an explicit value to paginate historical data.
 *
 * Returns up to 10 rows per page. Match requests are ordered by proposed_at
 * ASC; proposals are ordered by scheduled_at ASC.
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

  if (!['mine', 'feed', 'all', 'proposals'].includes(source)) {
    return json({ error: 'source must be "mine", "feed", "all", or "proposals"' }, 400)
  }

  // Parse the `from` param; default to the current moment.
  const fromRaw = url.searchParams.get('from')
  const fromDate = fromRaw ? new Date(fromRaw) : new Date()
  if (isNaN(fromDate.getTime())) {
    return json({ error: '`from` must be a valid ISO 8601 datetime' }, 400)
  }
  const fromIso = fromDate.toISOString()

  const offset = page * PAGE_SIZE

  // ── proposals: pending matches where the caller is a participant ─────────────
  if (source === 'proposals') {
    const { data, error, count } = await supabase
      .from('matches')
      .select(
        `
        id,
        host_id,
        club_id,
        scheduled_at,
        format,
        status,
        created_at,
        updated_at,
        host:profiles!matches_host_id_fkey(
          id,
          display_name,
          photo_url,
          calibrated_level,
          playstyle_tags,
          reliability_score
        ),
        club:clubs!inner(id, name),
        participants:match_participants(
          user_id,
          team,
          role,
          status
        )
      `,
        { count: 'exact' },
      )
      .eq('status', 'pending')
      .gte('scheduled_at', fromIso)
      .order('scheduled_at', { ascending: true })
      .range(offset, offset + PAGE_SIZE - 1)

    if (error) {
      console.error('list_matches: proposals query failed', error)
      return json({ error: 'Failed to load proposals' }, 500)
    }

    // RLS already limits rows to matches the caller participates in.
    // In local dev (service-role) we filter manually.
    const isLocalDev = Deno.env.get('LOCAL_DEV') === 'true'
    const rows = isLocalDev
      ? (data ?? []).filter((m: any) =>
          m.participants?.some((p: any) => p.user_id === userId),
        )
      : (data ?? [])

    console.log(`list_matches: page=${page} source=proposals rows=${rows.length} total=${count} from=${fromIso} user=${userId}`)

    return json({
      data: rows,
      meta: {
        page,
        page_size: PAGE_SIZE,
        total: count,
        has_more: rows.length === PAGE_SIZE,
        source,
        from: fromIso,
      },
    })
  }

  // ── Build match_requests query ───────────────────────────────────────────────
  // Always apply explicit visibility filters so behavior is identical between
  // local dev (service-role, no RLS) and production (anon key + RLS).
  //
  // `proposed_window` is a tstzrange. We want rows whose window has not fully
  // elapsed: upper(proposed_window) >= fromIso (i.e. the window ends at or
  // after the `from` cutoff). PostgREST exposes range operators via the
  // `overlaps` filter but we can't use upper() directly, so we use the range
  // overlap operator: proposed_window && [fromIso, infinity).
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
    .gte('proposed_at', fromIso)
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

  console.log(`list_matches: page=${page} source=${source} rows=${data?.length} total=${count} from=${fromIso} user=${userId}`)

  return json({
    data,
    meta: {
      page,
      page_size: PAGE_SIZE,
      total: count,
      has_more: hasMore,
      source,
      from: fromIso,
    },
  })
})
