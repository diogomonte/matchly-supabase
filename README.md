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

Install the prerequisites via Homebrew:

```bash
brew install node
brew install supabase/tap/supabase
```

Docker Desktop must be installed separately — download it from [docker.com](https://www.docker.com/products/docker-desktop) and make sure it is running before starting the stack.

### 1. Install dependencies

```bash
npm install
```

### 2. Start the local Supabase stack

```bash
npm run supabase:start
```

This starts a local Supabase instance (PostgreSQL, PostgREST, GoTrue auth, Studio) via Docker. The first run pulls the necessary images — it may take a minute.

| Service | URL |
|---------|-----|
| API | `http://127.0.0.1:54321` |
| Studio (DB explorer) | `http://127.0.0.1:54323` |
| PostgreSQL | `127.0.0.1:54322` |
| Mailpit (OTP inbox) | `http://127.0.0.1:54324` |

### 3. Apply migrations and seed data

```bash
npm run supabase:reset
```

Wipes the local DB, replays all migrations, and runs `supabase/seed.sql`. After this you have 5 test users, 3 clubs, open match requests, and sample matches ready to use.

**RLS is disabled locally** (via `seed.sql`) so the REST API and edge functions are accessible without authentication — see [Local auth behaviour](#local-auth-behaviour) below.

### 4. Serve edge functions

In a second terminal:

```bash
npx supabase functions serve --no-verify-jwt --env-file supabase/.env
```

Edge functions are then available at `http://127.0.0.1:54321/functions/v1/<name>`.

### 5. Generate TypeScript types

```bash
npm run supabase:generate-types
```

Updates `src/types/supabase.ts` from the current local schema. Run this after any schema change.

### 6. Explore in Studio

Open [http://127.0.0.1:54323](http://127.0.0.1:54323) to browse tables, run queries, inspect RLS policies, and manage storage.

### Stop the stack

```bash
npm run supabase:stop
```

---

## Local auth behaviour

Authentication is intentionally disabled for local development so you can call every endpoint without a JWT:

| Layer | What's disabled | How |
|-------|----------------|-----|
| REST API | RLS on all tables | `seed.sql` runs `ALTER TABLE … DISABLE ROW LEVEL SECURITY` |
| Edge functions (gateway) | JWT signature check | `verify_jwt = false` in `config.toml` |
| Edge functions (in-code) | Auth header requirement | When `LOCAL_DEV=true` (set in `supabase/.env`) and no `Authorization` header is sent, functions act as seed user `aaaaaaaa-…-0001` (Marco Rossi) |

None of this affects the hosted project — `seed.sql` never runs in production, the `config.toml` local sections are ignored by `supabase deploy`, and `supabase/.env` is a local-only file.

### Test users

All test users use OTP code **`123456`** (no real SMS sent — codes are intercepted locally).

| Name | Phone | User ID |
|------|-------|---------|
| Marco Rossi *(default dev user)* | `+4511111111` | `aaaaaaaa-0000-0000-0000-000000000001` |
| Anna Larsen | `+4522222222` | `aaaaaaaa-0000-0000-0000-000000000002` |
| Lars Nielsen | `+4533333333` | `aaaaaaaa-0000-0000-0000-000000000003` |
| Sofie Andersen | `+4544444444` | `aaaaaaaa-0000-0000-0000-000000000004` |
| Tobias Møller | `+4555555555` | `aaaaaaaa-0000-0000-0000-000000000005` |

---

## Production setup

After the first `make deploy`, run these two commands once to enable phone OTP on the hosted project:

**1. Fill in your Twilio credentials**

```bash
cp .env.production.example .env.production
# edit .env.production with real Account SID, Messaging Service SID, Auth Token
```

Get the values from [console.twilio.com](https://console.twilio.com):
- **Account SID** — Dashboard home, starts with `AC`
- **Auth Token** — Dashboard home, click to reveal
- **Messaging Service SID** — Messaging → Services, starts with `MG`

**2. Upload secrets and push auth config**

```bash
make secrets          # uploads Twilio credentials to the hosted project
make configure-auth   # pushes config.toml auth settings (enables phone OTP)
```

These only need to be re-run if credentials change. Migrations and functions are deployed independently via `make deploy`.

---

## Mock server (no Supabase needed)

A WireMock server stubs the full API for frontend development without running the Supabase stack at all. See [`wiremock/README.md`](wiremock/README.md) for setup instructions.

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
│   ├── config.toml              # Local Supabase configuration (auth, SMS, edge fn JWT)
│   ├── seed.sql                 # Local dev seed data + RLS disable
│   ├── .env                     # Local edge function env vars (LOCAL_DEV=true)
│   ├── functions/               # Edge functions (Deno)
│   └── migrations/              # Versioned SQL migrations
├── wiremock/
│   ├── mappings/                # WireMock stub files (one per resource)
│   └── README.md                # How to run the mock server
├── docs/
│   ├── API.md                   # HTTP reference for all endpoints
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
