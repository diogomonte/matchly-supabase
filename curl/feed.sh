#!/usr/bin/env bash
# feed.sh — scored match feed via the score_feed edge function
#
# Usage: source curl/.env && bash curl/feed.sh
#
# Prerequisites:
#   - At least two users with profiles (display_name, calibrated_level, playstyle_tags, home_club_ids)
#   - At least one open match_request from user B visible to user A
#   - USER_JWT is set to user A's token

FUNCTIONS="${SUPABASE_URL}/functions/v1"

echo "──────────────────────────────────────────"
echo "1. Get scored feed for the authenticated user"
echo "──────────────────────────────────────────"
curl -si -X POST "$FUNCTIONS/score_feed" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json"

echo ""
echo ""
echo "── Response fields ──────────────────────"
echo "  data[]              — up to 50 scored requests, sorted by score desc"
echo "  data[].score        — compatibility score 0–100"
echo "  data[].creator      — public_profiles data of the request creator"
echo "  meta.elapsed_ms     — server-side execution time"
echo ""
