#!/usr/bin/env bash
# profiles.sh — read and update your own profile
#
# Usage: source curl/.env && bash curl/profiles.sh

BASE="${SUPABASE_URL}/rest/v1"

echo "──────────────────────────────────────────"
echo "1. Read own profile (full row)"
echo "──────────────────────────────────────────"
curl -si "$BASE/profiles?select=*" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT"

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "2. Update profile (display_name, level, tags, intent)"
echo "──────────────────────────────────────────"
curl -si -X PATCH "$BASE/profiles?id=eq.$USER_ID" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{
    "display_name": "Marco Rossi",
    "self_rated_level": 3.5,
    "playstyle_tags": ["Aggressive", "NetPlayer"],
    "intent": "competitive"
  }'

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "3. Read public_profiles view (safe subset — what other users see)"
echo "──────────────────────────────────────────"
curl -si "$BASE/public_profiles?select=*" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT"

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "4. Read a specific user's public profile by id"
echo "──────────────────────────────────────────"
curl -si "$BASE/public_profiles?id=eq.$USER_ID&select=*" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT"

echo ""
