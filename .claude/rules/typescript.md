---
paths:
  - "src/**/*.ts"
---

# TypeScript Rules

## Module syntax

- Use ES module syntax exclusively: `import/export`, never `require()`
- Use `import type { Foo }` for type-only imports (not values)
- Named imports are preferred: `import { createClient } from '@supabase/supabase-js'`

## Supabase client usage

- Always use the typed client: `createClient<Database>(url, key)` with `Database` from `src/types/supabase.ts`
- Never instantiate a second Supabase client — import the singleton from `src/lib/supabase.ts`
- Always destructure results: `const { data, error } = await supabase.from(...)`
- Check `error` before using `data`:
  ```ts
  const { data, error } = await supabase.from('profiles').select('*')
  if (error) throw error
  ```

## Auth helpers

- Use the helpers exported from `src/lib/supabase.ts` (`signInWithGoogle`, `signOut`, `getSession`, `getProfile`, `updateProfile`) rather than calling `supabase.auth.*` directly in application code
- Add new helpers to `src/lib/supabase.ts` — keep auth/data access logic centralised there

## Type safety

- `src/types/supabase.ts` is auto-generated — never edit it manually, never import individual row types by re-defining them; use `Database['public']['Tables']['table_name']['Row']` or add a local alias
- Keep all database operations fully typed; avoid `any` in Supabase query chains
