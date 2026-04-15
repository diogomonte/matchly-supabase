# matchly-supabase

Supabase backend for **Matchly** — a padel player matchmaking app. Players post match requests, a compatibility scoring engine ranks candidates, and they confirm matches with one tap. Launch city: Copenhagen.

---

## Running Locally

### Prerequisites

| Tool | Version |
|------|---------|
| [Node.js](https://nodejs.org) | ≥ 18 |
| [Docker Desktop](https://www.docker.com/products/docker-desktop) | latest (must be running) |
| [Supabase CLI](https://supabase.com/docs/guides/cli) | ≥ 2.x |

Install the Supabase CLI if you don't have it:

```bash
brew install supabase/tap/supabase
# or
npm install -g supabase
```

### 1. Install dependencies

```bash
npm install
```

### 2. Start the local Supabase stack

```bash
npm run supabase:start
```

This starts a local Supabase instance (PostgreSQL, PostgREST, GoTrue auth, Studio) via Docker. The first run pulls the necessary images — it may take a minute.

Local services once running:

| Service | URL |
|---------|-----|
| API | `http://127.0.0.1:54321` |
| Studio (DB explorer) | `http://127.0.0.1:54323` |
| PostgreSQL | `127.0.0.1:54322` |

### 3. Apply migrations and seed data

```bash
npm run supabase:reset
```

This wipes the local database and replays all migrations in `supabase/migrations/` in order, then runs `supabase/seed.sql`. After this you'll have:

- `clubs` table seeded with 3 Copenhagen padel clubs
- `profiles` table with full Phase 2 schema (levels, playstyle tags, home clubs, reliability score)
- `public_profiles` view (safe subset, excludes phone / self_rated_level / intent)
- `profile-photos` storage bucket with public read and owner-scoped write policies

### 4. Generate TypeScript types

```bash
npm run supabase:generate-types
```

Updates `src/types/supabase.ts` from the current local schema. Run this after any schema change.

### 5. Explore in Studio

Open [http://127.0.0.1:54323](http://127.0.0.1:54323) to browse tables, run queries, inspect RLS policies, and manage storage.

### Stop the stack

```bash
npm run supabase:stop
```

---

## Project Structure

```
matchly-supabase/
├── src/
│   ├── lib/
│   │   └── supabase.ts          # Typed Supabase client singleton + auth helpers
│   └── types/
│       └── supabase.ts          # Auto-generated — never edit by hand
├── supabase/
│   ├── config.toml              # Local Supabase configuration
│   ├── seed.sql                 # Local dev seed data
│   └── migrations/              # Versioned SQL migrations
├── docs/
│   ├── PRODUCT.md               # Product definition and matching algorithm
│   ├── data_model.md            # Authoritative schema reference
│   └── PHASE_*.md               # Phase-by-phase implementation plans
└── package.json
```

---

## Available Scripts

| Script | Description |
|--------|-------------|
| `npm run supabase:start` | Start the local Supabase stack |
| `npm run supabase:stop` | Stop the local Supabase stack |
| `npm run supabase:reset` | Wipe local DB and re-apply all migrations + seed |
| `npm run supabase:migrate` | Push pending migrations to the hosted Supabase project |
| `npm run supabase:diff` | Diff local schema against the shadow DB (generates migration SQL) |
| `npm run supabase:generate-types` | Regenerate `src/types/supabase.ts` from current schema |

---

## Database Conventions

- Migration files: `YYYYMMDDHHMMSS_description.sql`, one logical change per file
- Every table has RLS enabled; explicit SELECT / INSERT / UPDATE / DELETE policies
- Never edit a migration already pushed to production — create a new one instead
- After any schema change: run `npm run supabase:generate-types`

---

## License

MIT
