#!/usr/bin/env bash
# clubs.sh — list clubs (read-only, authenticated)
#
# Usage: source curl/.env && bash curl/clubs.sh

BASE="${SUPABASE_URL}/rest/v1"

echo "──────────────────────────────────────────"
echo "1. List all clubs"
echo "──────────────────────────────────────────"
curl -si "$BASE/clubs?select=*&order=name.asc" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT"

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "2. Get a single club by id (set CLUB_ID in .env first)"
echo "──────────────────────────────────────────"
curl -si "$BASE/clubs?id=eq.$CLUB_ID&select=*" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Accept: application/vnd.pgrst.object+json"

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "3. Insert rejected by RLS (clubs are read-only for users)"
echo "──────────────────────────────────────────"
curl -si -X POST "$BASE/clubs" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -d '{"name":"Fake Club","city":"Copenhagen","lat":55.0,"lng":12.0}'

echo ""
