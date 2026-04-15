#!/usr/bin/env bash
# auth.sh — phone OTP sign-up / sign-in
#
# Usage: source curl/.env && bash curl/auth.sh
#
# Flow:
#   1. Request OTP  →  Supabase sends a 6-digit code (check Inbucket at http://127.0.0.1:54324)
#   2. Verify OTP   →  returns access_token (set USER_JWT= in .env)

BASE="${SUPABASE_URL}/auth/v1"
PHONE="+4512345678"   # change to any E.164 phone number
OTP="123456"          # replace with the code from Inbucket after step 1

echo "──────────────────────────────────────────"
echo "1. Send OTP to $PHONE"
echo "──────────────────────────────────────────"
curl -si -X POST "$BASE/otp" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"phone\": \"$PHONE\"}"

echo ""
echo ""
echo "──────────────────────────────────────────"
echo "2. Verify OTP (replace OTP= with the code from Inbucket http://127.0.0.1:54324)"
echo "──────────────────────────────────────────"
curl -si -X POST "$BASE/verify" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"phone\": \"$PHONE\", \"token\": \"$OTP\", \"type\": \"sms\"}"

echo ""
echo ""
echo "── Copy access_token from the response above and set USER_JWT in curl/.env ──"

echo ""
echo "──────────────────────────────────────────"
echo "3. Get current user (requires USER_JWT)"
echo "──────────────────────────────────────────"
curl -si "$BASE/user" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $USER_JWT"
