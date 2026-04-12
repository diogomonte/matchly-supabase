---
name: supabase-context
description: Background knowledge about this project's Supabase schema, auth flow, RLS policies, and storage setup. Load when answering questions about the database, auth, profiles, or storage.
user-invocable: false
---

# serene-supabase: Schema & Architecture Context

## profiles table

```sql
CREATE TABLE public.profiles (
  id         UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  updated_at TIMESTAMPTZ,
  username   TEXT UNIQUE CHECK (char_length(username) >= 3),
  full_name  TEXT,
  avatar_url TEXT,
  website    TEXT
);
```

- Every authenticated user gets one profile row automatically (see trigger below)
- `id` matches `auth.users.id` — it is the auth UID, not a separate PK
- `username` must be at least 3 characters and globally unique

## Auto-create profile trigger

When a new user signs up, this trigger fires and creates their profile row:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

- `full_name` and `avatar_url` are populated from Google OAuth metadata automatically
- The trigger runs as `SECURITY DEFINER`, so it bypasses RLS on insert

## RLS policies for profiles

| Operation | Policy | Using clause |
|---|---|---|
| SELECT | Public read | `true` |
| INSERT | Own row only | `auth.uid() = id` |
| UPDATE | Own row only | `auth.uid() = id` |

## Google OAuth flow

1. Client calls `signInWithGoogle()` → redirects to Google
2. Google redirects to `<SUPABASE_URL>/auth/v1/callback`
3. Supabase creates/updates `auth.users` row and issues a JWT session
4. `on_auth_user_created` trigger fires if it's a new user → creates `profiles` row
5. Client can now call `getSession()` to retrieve the session and `getProfile(userId)` to read profile data

## avatars storage bucket

- Bucket name: `avatars` (private)
- Policies:
  - SELECT: public (anyone can read avatars)
  - INSERT: authenticated users only
  - UPDATE: owner only — checked via `storage.foldername(name)[1] = auth.uid()::text`

## TypeScript client helpers (src/lib/supabase.ts)

| Export | Description |
|---|---|
| `supabase` | Singleton typed `SupabaseClient<Database>` |
| `signInWithGoogle()` | Triggers Google OAuth redirect |
| `signOut()` | Clears the session |
| `getSession()` | Returns the current `Session \| null` |
| `getProfile(userId)` | Selects profile row by `id` |
| `updateProfile(userId, updates)` | Updates `username`, `full_name`, `avatar_url`, `website`, `updated_at` |

## Local development ports

| Service | Port |
|---|---|
| Supabase API | 54321 |
| PostgreSQL | 54322 |
| Studio (dashboard) | 54323 |
| Inbucket (email) | 54324 |

Site URL for local auth redirects: `http://127.0.0.1:3000`
