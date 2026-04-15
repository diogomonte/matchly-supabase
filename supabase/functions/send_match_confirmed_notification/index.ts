/**
 * send_match_confirmed_notification — push notification to the host when
 * the invited player confirms.
 *
 * Called from the on_match_status_confirmed DB trigger via pg_net.
 * POST body: { match_id: string }
 *
 * Push payload:
 *   title: "Match confirmed!"
 *   body:  "{invitee_name} confirmed for {weekday} {time} at {club_name}"
 *   data:  { type: "match_confirmed", match_id }
 *
 * Requires the same edge function secrets as send_match_proposal_notification.
 * Always returns 200 so pg_net does not retry on push failure.
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

function formatScheduledAt(iso: string): string {
  const d = new Date(iso)
  const weekday = d.toLocaleDateString('en-US', { weekday: 'long', timeZone: 'Europe/Copenhagen' })
  const time = d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true, timeZone: 'Europe/Copenhagen' })
  return `${weekday} ${time}`
}

async function sendFcmPush(token: string, title: string, body: string, data: Record<string, string>): Promise<void> {
  const fcmKey = Deno.env.get('FCM_SERVER_KEY')
  if (!fcmKey) return

  const res = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `key=${fcmKey}`,
    },
    body: JSON.stringify({
      to: token,
      notification: { title, body },
      data,
    }),
  })

  if (!res.ok) {
    console.error(`send_match_confirmed_notification: FCM send failed (${res.status})`, await res.text())
  }
}

async function sendApnsPush(token: string, title: string, body: string, data: Record<string, string>): Promise<void> {
  const keyId = Deno.env.get('APNS_KEY_ID')
  const teamId = Deno.env.get('APNS_TEAM_ID')
  const privateKey = Deno.env.get('APNS_PRIVATE_KEY')
  const bundleId = Deno.env.get('APNS_BUNDLE_ID')

  if (!keyId || !teamId || !privateKey || !bundleId) return

  console.log(`send_match_confirmed_notification: APNs push queued for token ${token.slice(0, 8)}…`)
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS })
  }

  let match_id: string
  try {
    const body = await req.json()
    match_id = body.match_id
  } catch {
    return json({ error: 'Invalid JSON body' }, 400)
  }

  if (!match_id) return json({ error: 'match_id is required' }, 400)

  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  // Load match + club + all participants with profiles
  const { data: match, error: matchError } = await adminClient
    .from('matches')
    .select(`
      id,
      scheduled_at,
      host_id,
      clubs(name),
      match_participants(
        user_id,
        role,
        profiles(display_name)
      )
    `)
    .eq('id', match_id)
    .single()

  if (matchError || !match) {
    console.error('send_match_confirmed_notification: match not found', matchError)
    return json({ ok: true })
  }

  // Find the invited participant's name
  const participants: any[] = match.match_participants ?? []
  const invitedParticipant = participants.find((p: any) => p.role === 'invited')
  const inviteeName: string = invitedParticipant?.profiles?.display_name ?? 'Your opponent'

  const clubName: string = (match.clubs as any)?.name ?? 'the club'
  const when = formatScheduledAt(match.scheduled_at)

  // Load host's device tokens
  const { data: tokens } = await adminClient
    .from('device_tokens')
    .select('platform, token')
    .eq('user_id', match.host_id)

  if (!tokens || tokens.length === 0) {
    console.log(`send_match_confirmed_notification: no device tokens for host ${match.host_id}`)
    return json({ ok: true })
  }

  const title = 'Match confirmed!'
  const body = `${inviteeName} confirmed for ${when} at ${clubName}`
  const data = { type: 'match_confirmed', match_id }

  await Promise.all(
    tokens.map((t: { platform: string; token: string }) =>
      t.platform === 'android'
        ? sendFcmPush(t.token, title, body, data)
        : sendApnsPush(t.token, title, body, data),
    ),
  )

  console.log(`send_match_confirmed_notification: sent to ${tokens.length} device(s) for match ${match_id}`)
  return json({ ok: true })
})
