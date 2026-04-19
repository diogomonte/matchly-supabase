# Matchly — Supabase deployment Makefile
#
# Prerequisites:
#   - supabase CLI installed  (brew install supabase/tap/supabase)
#   - Logged in               (supabase login)
#   - Project linked          (make link)
#
# Usage:
#   make link          # link this repo to a hosted Supabase project
#   make deploy        # full production deploy (migrate + functions)
#   make migrate       # push pending DB migrations only
#   make functions     # deploy all edge functions only
#   make types         # regenerate TypeScript types from local schema
#   make dev           # start the full local dev stack
#   make dev-functions # serve edge functions locally (run alongside make dev)
#   make reset         # wipe local DB and reseed
#   make status        # show local stack URLs and keys

# ── Config ────────────────────────────────────────────────────────────────────

# Read the project ref from .supabase-project if it exists, otherwise require
# it to be passed as an env var: make link PROJECT_REF=<ref>
-include .supabase-project
export PROJECT_REF

# ── Colours ───────────────────────────────────────────────────────────────────
BOLD  := \033[1m
RESET := \033[0m
GREEN := \033[32m
CYAN  := \033[36m
RED   := \033[31m

# ── Phony targets ─────────────────────────────────────────────────────────────
.PHONY: help link deploy migrate functions types dev dev-functions reset status check-link

# Default target
help:
	@echo ""
	@echo "$(BOLD)Matchly — Supabase deployment$(RESET)"
	@echo ""
	@echo "$(BOLD)Setup$(RESET)"
	@echo "  $(CYAN)make link$(RESET)           Link repo to a hosted Supabase project"
	@echo ""
	@echo "$(BOLD)Deploy$(RESET)"
	@echo "  $(CYAN)make deploy$(RESET)         Full deploy: migrate DB + all edge functions"
	@echo "  $(CYAN)make migrate$(RESET)        Push pending DB migrations only"
	@echo "  $(CYAN)make functions$(RESET)      Deploy all edge functions only"
	@echo "  $(CYAN)make secrets$(RESET)        Upload .env.production secrets to hosted project"
	@echo "  $(CYAN)make configure-auth$(RESET) Push config.toml auth settings (enables phone OTP)"
	@echo ""
	@echo "$(BOLD)Local dev$(RESET)"
	@echo "  $(CYAN)make dev$(RESET)            Start local Supabase stack (Docker)"
	@echo "  $(CYAN)make dev-functions$(RESET)  Serve edge functions locally (second terminal)"
	@echo "  $(CYAN)make reset$(RESET)          Wipe local DB and re-apply migrations + seed"
	@echo "  $(CYAN)make status$(RESET)         Show local service URLs and API keys"
	@echo ""
	@echo "$(BOLD)Codegen$(RESET)"
	@echo "  $(CYAN)make types$(RESET)          Regenerate src/types/supabase.ts from local schema"
	@echo ""

# ── Setup ─────────────────────────────────────────────────────────────────────

## Link to a hosted Supabase project.
## Usage: make link PROJECT_REF=abcdefghijklmnop
link:
ifndef PROJECT_REF
	$(error PROJECT_REF is not set. Usage: make link PROJECT_REF=<your-project-ref>)
endif
	@echo "$(BOLD)Linking to project $(PROJECT_REF)…$(RESET)"
	supabase link --project-ref $(PROJECT_REF)
	@echo "PROJECT_REF=$(PROJECT_REF)" > .supabase-project
	@echo "$(GREEN)✓ Linked. Project ref saved to .supabase-project$(RESET)"

# Guard: fail fast if the project isn't linked yet
check-link:
ifndef PROJECT_REF
	$(error Not linked to a Supabase project. Run: make link PROJECT_REF=<ref>)
endif

# ── Deploy ────────────────────────────────────────────────────────────────────

## Full production deploy: push migrations then deploy all edge functions.
deploy: check-link migrate functions
	@echo ""
	@echo "$(GREEN)$(BOLD)✓ Deploy complete$(RESET)"
	@echo "  First time? Run: make secrets && make configure-auth"

## Upload edge function secrets to the hosted project.
## Reads from .env.production. Note: this stores Deno runtime env vars for
## edge functions — it does NOT configure auth provider credentials.
## Auth provider credentials (Twilio) are pushed via make configure-auth.
secrets: check-link
	@test -f .env.production || (echo "$(RED).env.production not found. Copy .env.production.example and fill in real values.$(RESET)" && exit 1)
	@echo "$(BOLD)Uploading edge function secrets to hosted project…$(RESET)"
	supabase secrets set --env-file .env.production
	@echo "$(GREEN)✓ Secrets uploaded$(RESET)"

## Enable phone OTP on the hosted project via the Supabase Management API.
## Reads TWILIO_* and SUPABASE_ACCESS_TOKEN from .env.production.
## Get your access token at: https://supabase.com/dashboard/account/tokens
configure-auth: check-link
	@test -f .env.production || (echo "$(RED).env.production not found. Copy .env.production.example and fill in values.$(RESET)" && exit 1)
	@echo "$(BOLD)Configuring phone OTP on hosted project via Management API…$(RESET)"
	@set -a && . ./.env.production && set +a && \
	RESULT=$$(curl -sf -X PATCH "https://api.supabase.com/v1/projects/$(PROJECT_REF)/config/auth" \
	  -H "Authorization: Bearer $$SUPABASE_ACCESS_TOKEN" \
	  -H "Content-Type: application/json" \
	  -d "{\"sms_provider\":\"twilio\",\"sms_twilio_account_sid\":\"$$TWILIO_ACCOUNT_SID\",\"sms_twilio_auth_token\":\"$$TWILIO_AUTH_TOKEN\",\"sms_twilio_message_service_sid\":\"$$TWILIO_MESSAGE_SERVICE_SID\",\"phone_autoconfirm\":false}" 2>&1) || \
	  (echo "$(RED)API call failed: $$RESULT$(RESET)" && exit 1)
	@echo "$(GREEN)✓ Phone OTP enabled — check Authentication → Providers → Phone in the dashboard$(RESET)"

## Push all pending migrations to the hosted project.
migrate: check-link
	@echo "$(BOLD)Pushing DB migrations…$(RESET)"
	supabase db push
	@echo "$(GREEN)✓ Migrations pushed$(RESET)"

## Deploy every edge function found in supabase/functions/.
functions: check-link
	@echo "$(BOLD)Deploying edge functions…$(RESET)"
	@for dir in supabase/functions/*/; do \
		fn=$$(basename "$$dir"); \
		echo "  → $$fn"; \
		supabase functions deploy "$$fn"; \
	done
	@echo "$(GREEN)✓ Functions deployed$(RESET)"

# ── Local dev ─────────────────────────────────────────────────────────────────

## Start the local Supabase stack.
## Sources supabase/.env so the auth container picks up the TWILIO_* vars
## and phone login is not disabled locally.
dev:
	@echo "$(BOLD)Starting local Supabase stack…$(RESET)"
	@set -a && . ./supabase/.env && set +a && supabase start

## Serve edge functions locally (run in a second terminal alongside make dev).
dev-functions:
	@echo "$(BOLD)Serving edge functions (no JWT verification)…$(RESET)"
	supabase functions serve --no-verify-jwt --env-file supabase/.env

## Wipe the local DB and re-apply all migrations and seed data.
reset:
	@echo "$(BOLD)Resetting local database…$(RESET)"
	@set -a && . ./supabase/.env && set +a && supabase db reset
	@echo "$(GREEN)✓ Database reset with seed data$(RESET)"

## Print local service URLs and API keys.
status:
	supabase status

# ── Codegen ───────────────────────────────────────────────────────────────────

## Regenerate TypeScript types from the current local schema.
types:
	@echo "$(BOLD)Generating TypeScript types…$(RESET)"
	supabase gen types typescript --local > src/types/supabase.ts
	@echo "$(GREEN)✓ src/types/supabase.ts updated$(RESET)"
