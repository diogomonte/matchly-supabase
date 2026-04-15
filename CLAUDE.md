# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Matchly** — a padel player matchmaking app. Players post match requests, a compatibility scoring engine ranks candidates, and they confirm matches with one tap. Launch city: Copenhagen. See `docs/PRODUCT.md` for full product definition.

## Commands

```bash
npm run supabase:start          # start local Supabase stack (Docker required)
npm run supabase:stop           # stop local stack
npm run supabase:reset          # wipe local DB and reapply all migrations + seed
npm run supabase:migrate        # push pending migrations to hosted Supabase
npm run supabase:diff           # diff local schema vs shadow DB (use to generate migration SQL)
npm run supabase:generate-types # regenerate src/types/supabase.ts from current schema
```

Local services when stack is running:
- API: `http://127.0.0.1:54321`
- Studio: `http://127.0.0.1:54323`
- PostgreSQL: `127.0.0.1:54322`

## Architecture

| Path | Purpose |
|---|---|
| `src/lib/supabase.ts` | Singleton typed Supabase client + auth helpers |
| `src/types/supabase.ts` | **Auto-generated** — never edit by hand |
| `supabase/migrations/` | Versioned SQL migrations |
| `supabase/seed.sql` | Local dev seed data only |
| `docs/data_model.md` | Authoritative schema reference (tables, RLS, triggers, edge functions) |
| `docs/PRODUCT.md` | Product definition, matching algorithm, MVP scope |
| `docs/PHASE_*.md` | Phase-by-phase implementation plans |

### Data model overview

Core tables (full spec in `docs/data_model.md`):
- **`profiles`** — 1:1 with `auth.users`, auto-created via trigger. Has `self_rated_level`, `calibrated_level`, `playstyle_tags` (max 3), `home_club_ids` (max 2), `intent`, `reliability_score`.
- **`public_profiles`** — view exposing safe subset of profiles (excludes phone, self_rated_level, intent).
- **`clubs`** — fixed seed list, read-only for users.
- **`match_requests`** — open availability windows. Status: `open` → `matched` / `cancelled` / `expired`.
- **`matches`** — proposed/confirmed match events. Supports singles + doubles from day one. Status machine: `pending` → `confirmed` / `declined` / `cancelled` / `completed`.
- **`match_participants`** — one row per player per match; tracks per-player `status` independently.
- **`playstyle_pairings`** — lookup table for the scoring engine (~30 entries).
- **`soft_blocks`**, **`device_tokens`** — forward-compat tables (populated in Phase 4).

### RLS pattern

All tables have RLS enabled. User-scoped policies use `auth.uid()`. The `is_match_participant(_match_id uuid)` function is a `SECURITY DEFINER` helper that lets `matches` and `match_participants` policies ask "is the caller in this match?" without recursive RLS.

### Edge functions

| Function | Purpose |
|---|---|
| `score_feed` | Compute compatibility scores for open requests; returns sorted feed |
| `propose_match` | Creates a match + 2 participant rows in a transaction |
| `respond_to_match` | Handles confirm/decline; updates match status |
| `cancel_match` | Host-only cancellation |
| `send_match_invite_notification` | Push to invited player (triggered by DB) |
| `send_match_status_change_notification` | Push to host on participant response |

Score formula: `0.5 * level_score + 0.25 * playstyle_score + 0.25 * reliability_score`

## TypeScript conventions

- ES modules only (`import/export`), never `require()`
- `import type` for type-only imports
- All Supabase calls use `createClient<Database>` with types from `src/types/supabase.ts`
- Never instantiate a second Supabase client — import the singleton from `src/lib/supabase.ts`
- Always destructure `{ data, error }` and check `error` before using `data`
- Use `Database['public']['Tables']['table_name']['Row']` for row types; don't redefine them
- No additional runtime dependencies without explicit approval

## Database conventions

- Migration filenames: `YYYYMMDDHHMMSS_description.sql`
- One logical change per migration file
- Never edit a migration already pushed to production — create a new one
- Every new table: `ALTER TABLE public.table_name ENABLE ROW LEVEL SECURITY;`
- Define explicit SELECT, INSERT, UPDATE, DELETE policies for every table
- Storage bucket policies follow the pattern: public SELECT, authenticated INSERT, owner-only UPDATE/DELETE (owner checked via `storage.foldername(name)[1]`)
- After any schema change: run `npm run supabase:generate-types`

## Available skills

- `/add-migration <description>` — scaffold a new migration file with correct timestamp and RLS boilerplate
- `/supabase-context` — load full schema + auth flow context (background, not user-invocable)
