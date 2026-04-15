#!/usr/bin/env bash
# match_requests.sh — create, list, and cancel match requests
#
# Usage: source curl/.env && bash curl/match_requests.sh
#
# Set CLUB_ID in .env before running (copy an id from clubs.sh output).

BASE="${SUPABASE_URL}/rest/v1"

echo "──────────────────────────────────────────"
echo "1. Create an open match request"
echo "──────────────────────────────────────────"
curl -si -X POST "$BASE/match_requests" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"creator_id\": \"$USER_ID\",
    \"club_id\": \"$CLUB_ID\",
    \"proposed_window\": \"[2026-04-20 09:00:00+00, 2026-04-20 11:00:00+00)\"
  }"

echo ""
echo "── Copy the returned id and set REQUEST_ID in curl/.env ──"
echo ""

echo "──────────────────────────────────────────"
echo "2. List all open requests (what the feed shows)"
echo "──────────────────────────────────────────"
curl -si "$BASE/match_requests?status=eq.open&select=*,creator:public_profiles!creator_id(*)" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT"

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "3. List my own requests (all statuses)"
echo "──────────────────────────────────────────"
curl -si "$BASE/match_requests?creator_id=eq.$USER_ID&select=*&order=created_at.desc" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT"

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "4. Cancel a request (set REQUEST_ID in .env first)"
echo "──────────────────────────────────────────"
curl -si -X PATCH "$BASE/match_requests?id=eq.$REQUEST_ID" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"status": "cancelled"}'

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "5. RLS check: update another user's request (should be rejected)"
echo "──────────────────────────────────────────"
SOMEONE_ELSES_REQUEST="00000000-0000-0000-0000-000000000000"
curl -si -X PATCH "$BASE/match_requests?id=eq.$SOMEONE_ELSES_REQUEST" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -d '{"status": "cancelled"}'

echo ""
