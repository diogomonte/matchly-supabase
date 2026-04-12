---
paths:
  - "supabase/**"
  - "src/**"
---

# Supabase Rules

## Migrations

- Migration filenames MUST follow: `YYYYMMDDHHMMSS_description.sql` (e.g. `20260321120000_add_posts_table.sql`)
- Generate migrations with `npm run supabase:diff` rather than writing from scratch when possible
- One logical change per migration file — do not bundle unrelated schema changes
- Never edit a migration that has already been pushed to production; create a new one instead
- After creating or editing a migration, always remind the user to run `npm run supabase:generate-types`

## Row-Level Security

- EVERY new table must have RLS enabled:
  ```sql
  ALTER TABLE public.table_name ENABLE ROW LEVEL SECURITY;
  ```
- Always create explicit policies for each operation you intend to allow (SELECT, INSERT, UPDATE, DELETE)
- Use `auth.uid()` to scope policies to the authenticated user
- Default to restrictive: if a policy isn't defined, the operation is denied

## Storage

- New storage buckets follow the pattern in `supabase/migrations/20240101000000_initial_schema.sql`
- Buckets have three standard policies: public SELECT, authenticated INSERT, owner-only UPDATE/DELETE
- Use `storage.foldername(name)[1]` to extract the user ID from the storage path for owner checks

## Seed data

- `supabase/seed.sql` is for local development only — example rows, test users
- Never put seed data in migration files
- Seed data is wiped and reapplied on every `npm run supabase:reset`
