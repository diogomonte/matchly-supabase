#!/usr/bin/env bash
# deploy_functions.sh — deploy all Supabase Edge Functions to the linked project.
#
# Usage:
#   ./supabase/scripts/deploy_functions.sh
#
# Prerequisites:
#   - supabase CLI installed and authenticated (`supabase login`)
#   - Project linked (`supabase link --project-ref <ref>`)
#
# Each function in supabase/functions/ is deployed in turn.
# The script exits immediately on any failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTIONS_DIR="$SCRIPT_DIR/../functions"

if [ ! -d "$FUNCTIONS_DIR" ]; then
  echo "No functions directory found at $FUNCTIONS_DIR" >&2
  exit 1
fi

FUNCTIONS=()
for dir in "$FUNCTIONS_DIR"/*/; do
  [ -d "$dir" ] && FUNCTIONS+=("$(basename "$dir")")
done

if [ ${#FUNCTIONS[@]} -eq 0 ]; then
  echo "No edge functions found in $FUNCTIONS_DIR" >&2
  exit 0
fi

echo "Deploying ${#FUNCTIONS[@]} edge function(s)..."

for fn in "${FUNCTIONS[@]}"; do
  echo "  → $fn"
  supabase functions deploy "$fn"
done

echo ""
echo "All functions deployed successfully."
echo ""
echo "Verify with a test invocation:"
echo "  curl -i --request POST \\"
echo "    --url \"\$(supabase status --output json | jq -r .API_URL)/functions/v1/score_feed\" \\"
echo "    --header \"Authorization: Bearer <anon_or_user_jwt>\""
