#!/usr/bin/env bash
# ============================================================================
# Template Initialization Script
# ============================================================================
# Run this script after creating a new repository from the template to replace
# all placeholder values with your project-specific configuration.
#
# Usage:
#   chmod +x scripts/init.sh
#   ./scripts/init.sh
#
# The script will prompt you for each value interactively.
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Template defaults (update these if you fork the template itself)
# ---------------------------------------------------------------------------
TEMPLATE_PROJECT_NAME="serene-supabase"
TEMPLATE_GITHUB_OWNER_REPO="diogomonte/serene-supabase"

# ---------------------------------------------------------------------------
# Cross-platform sed -i (macOS vs Linux)
# ---------------------------------------------------------------------------
_sed_i() {
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { echo -e "${CYAN}ℹ ${NC}$1"; }
success() { echo -e "${GREEN}✔ ${NC}$1"; }
warn()    { echo -e "${YELLOW}⚠ ${NC}$1"; }
error()   { echo -e "${RED}✖ ${NC}$1"; }

prompt_value() {
  local var_name="$1"
  local description="$2"
  local default_value="${3:-}"
  local value

  if [[ -n "$default_value" ]]; then
    echo -en "${CYAN}? ${NC}${description} ${YELLOW}[${default_value}]${NC}: "
    read -r value
    value="${value:-$default_value}"
  else
    echo -en "${CYAN}? ${NC}${description}: "
    read -r value
  fi

  eval "$var_name=\"$value\""
}

# ---------------------------------------------------------------------------
# Locate project root (one level up from scripts/)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       Supabase Template — Project Initialization       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
info "This script replaces template placeholders with your project values."
info "Press Enter to accept defaults shown in [brackets]."
echo ""

# ---------------------------------------------------------------------------
# Gather values
# ---------------------------------------------------------------------------
prompt_value PROJECT_NAME "Project name (kebab-case, e.g. my-app)" "$(basename "$PROJECT_ROOT")"
prompt_value PROJECT_DESC "Short project description" "A Supabase-powered application"
prompt_value GITHUB_OWNER "GitHub owner (user or org)"
prompt_value GITHUB_REPO  "GitHub repository name" "$PROJECT_NAME"

echo ""
info "Summary:"
echo "  Project name : $PROJECT_NAME"
echo "  Description  : $PROJECT_DESC"
echo "  GitHub       : $GITHUB_OWNER/$GITHUB_REPO"
echo ""

echo -en "${CYAN}? ${NC}Proceed with replacement? ${YELLOW}[Y/n]${NC}: "
read -r CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  warn "Aborted."
  exit 0
fi

echo ""

# ---------------------------------------------------------------------------
# Replace placeholders in files
# ---------------------------------------------------------------------------
replace_all() {
  local search="$1"
  local replace="$2"

  # Target specific file types to avoid modifying binaries or git objects
  while IFS= read -r -d '' file; do
    _sed_i "s|${search}|${replace}|g" "$file"
  done < <(find "$PROJECT_ROOT" \
    -not -path '*/.git/*' \
    -not -path '*/node_modules/*' \
    -not -path '*/dist/*' \
    -not -path '*/build/*' \
    -not -path '*/scripts/init.sh' \
    -type f \
    \( -name '*.md' -o -name '*.ts' -o -name '*.js' -o -name '*.json' -o -name '*.toml' \
       -o -name '*.sql' -o -name '*.html' -o -name '*.env*' -o -name '*.yaml' -o -name '*.yml' \) \
    -print0)
}

info "Replacing placeholders..."

# GitHub owner/repo (must run BEFORE project name replacement)
replace_all "$TEMPLATE_GITHUB_OWNER_REPO" "$GITHUB_OWNER/$GITHUB_REPO"
success "Replaced GitHub references"

# Project name (after GitHub owner/repo to avoid partial matches)
replace_all "$TEMPLATE_PROJECT_NAME" "$PROJECT_NAME"
success "Replaced project name"

# ---------------------------------------------------------------------------
# Clean up template-only files
# ---------------------------------------------------------------------------
info "Cleaning up template files..."

if [[ -f "$PROJECT_ROOT/TEMPLATE_PROMPT.md" ]]; then
  rm "$PROJECT_ROOT/TEMPLATE_PROMPT.md"
  success "Removed TEMPLATE_PROMPT.md"
fi

echo ""
success "Initialization complete! 🎉"
echo ""
info "Next steps:"
echo "  1. Review the changes: git diff"
echo "  2. Set up environment:  cp .env.example .env && edit .env"
echo "  3. Install dependencies: npm install"
echo "  4. Start local Supabase: npm run supabase:start"
echo "  5. Create your first migration: supabase migration new create_my_table"
echo "  6. Generate types: npm run supabase:generate-types"
echo "  7. Commit your changes:  git add -A && git commit -m 'Initialize project from template'"
echo ""
