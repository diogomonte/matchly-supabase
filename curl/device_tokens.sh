#!/usr/bin/env bash
# device_tokens.sh — register and remove push notification tokens
#
# Usage: source curl/.env && bash curl/device_tokens.sh

BASE="${SUPABASE_URL}/rest/v1"

echo "──────────────────────────────────────────"
echo "1. Register an Android (FCM) token"
echo "──────────────────────────────────────────"
curl -si -X POST "$BASE/device_tokens" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation,resolution=merge-duplicates" \
  -d "{
    \"user_id\": \"$USER_ID\",
    \"platform\": \"android\",
    \"token\": \"fcm-test-token-android-$(date +%s)\"
  }"

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "2. Register an iOS (APNs) token"
echo "──────────────────────────────────────────"
curl -si -X POST "$BASE/device_tokens" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation,resolution=merge-duplicates" \
  -d "{
    \"user_id\": \"$USER_ID\",
    \"platform\": \"ios\",
    \"token\": \"apns-test-token-ios-$(date +%s)\"
  }"

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "3. List my tokens"
echo "──────────────────────────────────────────"
curl -si "$BASE/device_tokens?user_id=eq.$USER_ID&select=id,platform,token,updated_at" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT"

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "4. Delete a token by id (replace TOKEN_ID)"
echo "──────────────────────────────────────────"
TOKEN_ID="<replace-with-id-from-step-3>"
curl -si -X DELETE "$BASE/device_tokens?id=eq.$TOKEN_ID" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT"

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "5. RLS check: register token for another user (should be rejected)"
echo "──────────────────────────────────────────"
curl -si -X POST "$BASE/device_tokens" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "00000000-0000-0000-0000-000000000000",
    "platform": "android",
    "token": "should-be-rejected"
  }'

echo ""
