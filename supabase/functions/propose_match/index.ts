/**
 * propose_match — create a match from an open request.
 *
 * POST body: { request_id: string, scheduled_at: string (ISO 8601) }
 *
 * Validates:
 *   - Caller is authenticated (JWT)
 *   - match_request exists and status = 'open'
 *   - Caller is not the request creator
 *   - scheduled_at falls inside the proposed_window tstzrange
 *
 * Transactionally:
 *   1. Inserts into matches (status = 'pending')
 *   2. Inserts two match_participants rows (host: confirmed, invited: pending)
 *   3. Updates match_requests.status = 'matched'
 *
 * Uses the service-role key for writes because RLS intentionally blocks
 * direct INSERT on matches / match_participants from the client.
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
  let anonClient: ReturnType<typeof createClient>

  if (isLocal && (!authHeader || isAnonKeyBearer)) {
    userId = LOCAL_DEV_USER_ID
    anonClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )
  } else {
    if (!authHeader) return json({ error: 'Missing Authorization header' }, 401)
    anonClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user }, error: authError } = await anonClient.auth.getUser()
    if (authError || !user) return json({ error: 'Unauthorized' }, 401)
    userId = user.id
  }

  // ── Parse body ──────────────────────────────────────────────────────────────
  let request_id: string
  let scheduled_at: string
  try {
    const body = await req.json()
    request_id = body.request_id
    scheduled_at = body.scheduled_at
  } catch {
    return json({ error: 'Invalid JSON body' }, 400)
  }

  if (!request_id || !scheduled_at) {
    return json({ error: 'request_id and scheduled_at are required' }, 400)
  }

  const scheduledDate = new Date(scheduled_at)
  if (isNaN(scheduledDate.getTime())) {
    return json({ error: 'scheduled_at is not a valid ISO 8601 date' }, 400)
  }

  // ── Load + validate the match request ──────────────────────────────────────
  // Use anon client so RLS applies — caller can only read open requests
  const { data: matchRequest, error: requestError } = await anonClient
    .from('match_requests')
    .select('id, creator_id, club_id, proposed_window, status')
    .eq('id', request_id)
    .single()

  if (requestError || !matchRequest) return json({ error: 'Match request not found' }, 404)
  if (matchRequest.status !== 'open') return json({ error: 'Match request is no longer open' }, 409)
  if (matchRequest.creator_id === userId) return json({ error: 'Cannot propose a match on your own request' }, 400)

  // Validate scheduled_at is inside the tstzrange window.
  // proposed_window is returned as a string like '[2026-04-20 09:00:00+00,2026-04-20 11:00:00+00)'
  const windowStr: string = matchRequest.proposed_window as string
  const rangeMatch = windowStr.match(/[\[\(](.+?),(.+?)[\]\)]/)
  if (rangeMatch) {
    const windowStart = new Date(rangeMatch[1].trim())
    const windowEnd = new Date(rangeMatch[2].trim())
    if (scheduledDate < windowStart || scheduledDate >= windowEnd) {
      return json({ error: 'scheduled_at must be inside the proposed window' }, 400)
    }
  }

  // ── Transaction via service-role client ────────────────────────────────────
  // Service-role bypasses INSERT RLS (by design — only edge fns create matches).
  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  // 1. Insert match
  const { data: newMatch, error: matchError } = await adminClient
    .from('matches')
    .insert({
      request_id: matchRequest.id,
      host_id: userId,
      club_id: matchRequest.club_id,
      scheduled_at,
      format: 'singles',
      status: 'pending',
    })
    .select('id')
    .single()

  if (matchError || !newMatch) {
    console.error('propose_match: failed to insert match', matchError)
    return json({ error: 'Failed to create match' }, 500)
  }

  const matchId = newMatch.id

  // 2. Insert both participant rows
  const { error: participantError } = await adminClient
    .from('match_participants')
    .insert([
      {
        match_id: matchId,
        user_id: userId,
        team: 1,
        role: 'host',
        status: 'confirmed',
      },
      {
        match_id: matchId,
        user_id: matchRequest.creator_id,
        team: 2,
        role: 'invited',
        status: 'pending',
      },
    ])

  if (participantError) {
    console.error('propose_match: failed to insert participants', participantError)
    // Best-effort cleanup — delete the orphaned match row
    await adminClient.from('matches').delete().eq('id', matchId)
    return json({ error: 'Failed to create match participants' }, 500)
  }

  // 3. Mark request as matched
  const { error: updateError } = await adminClient
    .from('match_requests')
    .update({ status: 'matched' })
    .eq('id', request_id)

  if (updateError) {
    console.error('propose_match: failed to update match_request status', updateError)
    // Non-fatal: match was created. Log and continue.
  }

  console.log(`propose_match: match ${matchId} created by user ${userId} for request ${request_id}`)

  return json({ data: { match_id: matchId } }, 201)
})
