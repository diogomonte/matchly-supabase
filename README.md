# matchly

> Match players for tennis and padel — powered by [Supabase](https://supabase.com).

Features:

- 🗄️ **Database & REST/GraphQL APIs** — auto-generated from your schema via PostgREST
- 🔐 **Google (Gmail) OAuth** — sign-in with Google configured out of the box
- 🚀 **Database migrations** — versioned SQL migrations managed with the Supabase CLI
- 🔒 **Row Level Security** — RLS enabled by convention on every table
- 📦 **Typed TypeScript client** — auto-generated types from your database schema

---

## Prerequisites

| Tool | Version |
|------|---------|
| [Node.js](https://nodejs.org) | ≥ 18 |
| [Supabase CLI](https://supabase.com/docs/guides/cli) | ≥ 2.x |
| [Docker Desktop](https://www.docker.com/products/docker-desktop) | latest |

Install the Supabase CLI:

```bash
npm install -g supabase
# or via Homebrew
brew install supabase/tap/supabase
```

---

## Quick Start

### 1. Clone and install dependencies

```bash
git clone https://github.com/diogomonte/matchly-supabase.git
cd matchly-supabase
npm install
```

### 2. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env` and fill in your Supabase project credentials. For local development, the values from `supabase status` after starting the stack are used automatically.

### 3. Start the local Supabase stack

```bash
npm run supabase:start
```

This starts a local Supabase instance (PostgreSQL, PostgREST, GoTrue auth, Studio) using Docker. The first run will pull the necessary images.

After startup, the CLI prints your local credentials:

```
API URL:          http://127.0.0.1:54321
GraphQL URL:      http://127.0.0.1:54321/graphql/v1
DB URL:           postgresql://postgres:postgres@127.0.0.1:54322/postgres
Studio URL:       http://127.0.0.1:54323
Anon Key:         <anon-key>
Service Role Key: <service-role-key>
```

### 4. Create your first migration

```bash
supabase migration new create_my_table
```

Edit the generated SQL file in `supabase/migrations/`, then reset the local DB to apply it:

```bash
npm run supabase:reset
```

### 5. Generate TypeScript types

```bash
npm run supabase:generate-types
```

This updates `src/types/supabase.ts` with the latest database schema.

### 6. Use Supabase Studio

Open [http://127.0.0.1:54323](http://127.0.0.1:54323) in your browser to explore the database, run queries, and manage users.

---

## Authentication — Google (Gmail) OAuth

### Local development

1. Create a project in [Google Cloud Console](https://console.cloud.google.com/apis/credentials).
2. Add an OAuth 2.0 Client ID (Web application type).
3. Set **Authorized redirect URIs** to:
   ```
   http://127.0.0.1:54321/auth/v1/callback
   ```
4. Copy the **Client ID** and **Client Secret** into your `.env`:
   ```
   GOOGLE_CLIENT_ID=<your-client-id>
   GOOGLE_CLIENT_SECRET=<your-client-secret>
   ```
5. Restart the local stack:
   ```bash
   npm run supabase:stop && npm run supabase:start
   ```

### Production (hosted Supabase)

1. In your [Supabase Dashboard](https://app.supabase.com), go to **Authentication → Providers → Google**.
2. Enable the Google provider and paste your **Client ID** and **Client Secret**.
3. Set the **Redirect URL** shown in the dashboard as an authorized redirect URI in Google Cloud Console.

### Signing in from your app

```typescript
import { signInWithGoogle } from './src/lib/supabase'

// Redirect the user to Google's OAuth consent screen
await signInWithGoogle()
```

---

## Database Migrations

Migrations live in `supabase/migrations/` and are applied in filename order.

### Create a new migration

```bash
supabase migration new <migration-name>
# e.g. supabase migration new add_posts_table
```

Edit the generated SQL file in `supabase/migrations/`, then reset the local DB to apply it:

```bash
npm run supabase:reset
```

### Generate a migration from schema changes made in Studio

```bash
npm run supabase:diff -- --file <migration-name>
```

### Push to remote

```bash
npm run supabase:migrate
```

---

## Generating TypeScript Types

Keep your TypeScript types in sync with the database schema:

```bash
npm run supabase:generate-types
```

This updates `src/types/supabase.ts` with the latest database schema.

---

## Project Structure

```
matchly/
├── src/
│   ├── lib/
│   │   └── supabase.ts          # Supabase client + auth helpers
│   └── types/
│       └── supabase.ts          # Auto-generated TypeScript database types
├── supabase/
│   ├── config.toml              # Supabase local project configuration (incl. Google OAuth)
│   ├── seed.sql                 # Seed data for local development
│   └── migrations/              # Your SQL migrations go here
├── .env.example                 # Environment variable template
└── package.json
```

---

## Available Scripts

| Script | Description |
|--------|-------------|
| `npm run supabase:start` | Start the local Supabase stack |
| `npm run supabase:stop` | Stop the local Supabase stack |
| `npm run supabase:status` | Show local stack status and credentials |
| `npm run supabase:reset` | Reset the local DB and re-run all migrations |
| `npm run supabase:migrate` | Push pending migrations to the remote project |
| `npm run supabase:diff` | Diff local schema against the shadow database |
| `npm run supabase:generate-types` | Regenerate TypeScript types from the local schema |

---

## License

MIT
