#!/usr/bin/env bash
# matches.sh — propose, confirm, and decline matches
#
# Usage: source curl/.env && bash curl/matches.sh
#
# Prerequisites:
#   - REQUEST_ID set to an open match_request created by a different user
#   - USER_JWT is the proposer's token

BASE="${SUPABASE_URL}/rest/v1"
FUNCTIONS="${SUPABASE_URL}/functions/v1"

echo "──────────────────────────────────────────"
echo "1. Propose a match (calls propose_match edge function)"
echo "──────────────────────────────────────────"
curl -si -X POST "$FUNCTIONS/propose_match" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -d "{
    \"request_id\": \"$REQUEST_ID\",
    \"scheduled_at\": \"2026-04-20T10:00:00Z\"
  }"

echo ""
echo "── Copy the returned match_id and set MATCH_ID in curl/.env ──"
echo ""

echo "──────────────────────────────────────────"
echo "2. List matches I am a participant in"
echo "──────────────────────────────────────────"
curl -si "$BASE/matches?select=*,match_participants(*)" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT"

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "3. Confirm a match (invited player — switch USER_JWT to the invited user's token)"
echo "──────────────────────────────────────────"
curl -si -X PATCH "$BASE/match_participants?match_id=eq.$MATCH_ID&user_id=eq.$USER_ID" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"status": "confirmed", "responded_at": "now()"}'

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "4. After all invitees confirm: update match status to confirmed"
echo "──────────────────────────────────────────"
curl -si -X PATCH "$BASE/matches?id=eq.$MATCH_ID" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"status": "confirmed", "updated_at": "now()"}'

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "5. Decline a match (invited player)"
echo "──────────────────────────────────────────"
curl -si -X PATCH "$BASE/match_participants?match_id=eq.$MATCH_ID&user_id=eq.$USER_ID" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"status": "declined", "responded_at": "now()"}'

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "6. Propose own request (should return 400)"
echo "──────────────────────────────────────────"
curl -si -X POST "$FUNCTIONS/propose_match" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -d "{
    \"request_id\": \"$REQUEST_ID\",
    \"scheduled_at\": \"2026-04-20T10:00:00Z\"
  }"

echo ""
