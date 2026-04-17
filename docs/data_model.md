# Data Model

All tables live in the `public` schema unless otherwise noted. RLS is enabled on every table. Default policy is deny-all; access is granted via explicit policies.

---

## Tables

### `profiles`

Tied 1:1 to `auth.users`. Auto-created via trigger on signup.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | FK to `auth.users.id` |
| `phone` | text | From auth, never exposed to other users |
| `display_name` | text | |
| `photo_url` | text | Supabase Storage URL |
| `self_rated_level` | numeric(2,1) | 1.0–5.0 |
| `calibrated_level` | numeric(2,1) | Starts = self_rated, updated by feedback (Phase 4) |
| `playstyle_tags` | text[] | Max 3, from fixed enum |
| `intent` | text | `competitive` \| `social` \| `both` |
| `reliability_score` | numeric(3,2) | 0.00–1.00, default 1.00 |
| `created_at` | timestamptz | default now() |
| `updated_at` | timestamptz | default now() |

**Constraints:**
- `self_rated_level` BETWEEN 1.0 AND 5.0
- `calibrated_level` BETWEEN 1.0 AND 5.0
- `array_length(playstyle_tags, 1) <= 3`
- `array_length(home_club_ids, 1) <= 2`
- `intent IN ('competitive', 'social', 'both')`

**RLS:**
- SELECT own row: `auth.uid() = id`
- UPDATE own row: `auth.uid() = id`
- INSERT: handled by trigger only
- Other users read via `public_profiles` view, never this table directly

---

### `public_profiles` (view)

Safe view exposing only what other users should see. Used by the feed and proposal screens.

```sql
CREATE VIEW public_profiles AS
SELECT
  id,
  display_name,
  photo_url,
  calibrated_level,
  playstyle_tags,
  home_club_ids,
  reliability_score
FROM profiles;
```

**RLS:** any authenticated user can SELECT.

**Excluded from view:** `phone`, `self_rated_level`, `intent`, timestamps.

---

### `clubs`

Fixed list, seeded manually for the launch city. No user-facing "add club" feature in MVP.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `name` | text | |
| `city` | text | |
| `lat` | numeric(9,6) | |
| `lng` | numeric(9,6) | |
| `created_at` | timestamptz | |

**RLS:** read-only for all authenticated users.

**Seed:** Copenhagen launch clubs (3 entries).

---

### `match_requests`

A user saying *I want to play at this club in this window.*

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `creator_id` | uuid | FK to `profiles.id` |
| `club_id` | uuid | FK to `clubs.id` |
| `proposed_window` | tstzrange | e.g. Sat 09:00–11:00 |
| `status` | text | `open` \| `matched` \| `cancelled` \| `expired` |
| `created_at` | timestamptz | |

**Indexes:**
- `(club_id, status, proposed_window)` for feed queries
- `(creator_id, status)` for "my requests"

**RLS:**
- INSERT: `auth.uid() = creator_id`
- UPDATE/DELETE own: `auth.uid() = creator_id`
- SELECT open requests: any authenticated user where `status = 'open'`
- SELECT own requests: any status

---

### `matches`

A proposed or confirmed match. Modeled to support both **singles (2 players)** and **doubles (4 players)** from day one, even though the MVP only ships singles. This avoids a painful migration in Phase 5 when doubles is added.

The match itself only stores the *event* (when, where, format, overall status). The participants live in `match_participants`.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `request_id` | uuid | FK to `match_requests.id`, nullable for direct invites |
| `host_id` | uuid | FK to `profiles.id`. The player who created the match. |
| `club_id` | uuid | FK to `clubs.id` |
| `scheduled_at` | timestamptz | Specific time inside the original window |
| `format` | text | `singles` \| `doubles` |
| `status` | text | `pending` \| `confirmed` \| `declined` \| `cancelled` \| `completed` |
| `created_at` | timestamptz | default now() |
| `updated_at` | timestamptz | default now() |

**Constraints:**
- `format IN ('singles', 'doubles')`
- `status IN ('pending', 'confirmed', 'declined', 'cancelled', 'completed')`
- A `singles` match must have exactly 2 rows in `match_participants` (1 per team) — enforced by trigger
- A `doubles` match must have exactly 4 rows in `match_participants` (2 per team) — enforced by trigger

**Status state machine:**
- Created with `host_id` participant as `confirmed`, all invitees as `pending`.
- All invitees confirm → `matches.status = confirmed`, push to host.
- Any invitee declines → `matches.status = declined`, push to host (with optional "find a replacement" prompt in Phase 5).
- Host cancels at any time before `completed` → `matches.status = cancelled`.
- After `scheduled_at` passes and all confirmed → eligible to be marked `completed` (Phase 4 post-match feedback flow).

State transitions are enforced by the `respond_to_match` and `cancel_match` Edge Functions, not by Postgres triggers — easier to test, log, and evolve.

**Indexes:**
- `(host_id, status)` for "matches I'm hosting"
- `(scheduled_at) WHERE status = 'confirmed'` for upcoming-match queries

**RLS:**
- SELECT: visible if you're a participant (uses helper function — see below)
- UPDATE: only via Edge Functions (status transitions are server-controlled)
- INSERT: only via the `propose_match` / `create_match` Edge Functions

---

### `match_participants`

One row per player in a match. Tracks per-player status (a 4-player doubles match can have one confirmed, two pending, one declined — and the model handles it natively).

| Column | Type | Notes |
|---|---|---|
| `match_id` | uuid | FK to `matches.id`, ON DELETE CASCADE |
| `user_id` | uuid | FK to `profiles.id` |
| `team` | smallint | `1` or `2` |
| `role` | text | `host` \| `invited` |
| `status` | text | `pending` \| `confirmed` \| `declined` |
| `joined_at` | timestamptz | default now() |
| `responded_at` | timestamptz | nullable, set when status leaves `pending` |

**Primary key:** (`match_id`, `user_id`) — a player can only be in a match once.

**Constraints:**
- `team IN (1, 2)`
- `role IN ('host', 'invited')`
- `status IN ('pending', 'confirmed', 'declined')`
- Exactly one `host` per match (enforced by partial unique index)

**Indexes:**
- `(user_id, status)` for "matches I'm in" queries (the most common query in the app)
- `(match_id)` for loading a match's full participant list

**RLS:**
- SELECT: visible to anyone in the same match (uses helper function)
- UPDATE: own row only (`auth.uid() = user_id`), and only allowed via the `respond_to_match` Edge Function in practice
- INSERT: only via Edge Functions

---

### Helper function: `is_match_participant`

A `SECURITY DEFINER` function that avoids RLS recursion when policies on `matches` and `match_participants` need to ask "is this user in this match?"

```sql
CREATE OR REPLACE FUNCTION public.is_match_participant(_match_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.match_participants
    WHERE match_id = _match_id AND user_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.is_match_participant(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.is_match_participant(uuid) TO authenticated;
```

**Why this exists:** without it, the SELECT policy on `match_participants` would self-reference the same table and either fail or recurse. The `SECURITY DEFINER` lets it bypass RLS internally and answer the participation question cleanly. This is a standard Supabase pattern.

**Used by:**
- `matches` SELECT policy: `is_match_participant(matches.id)`
- `match_participants` SELECT policy: `is_match_participant(match_participants.match_id)`

---

### MVP simplification

The MVP only ships **singles matches** (`format = 'singles'`). The schema fully supports doubles, but the app UI, Edge Functions, and matching logic in Phase 3c only handle the 2-player case. Doubles support is added in Phase 5 by:

1. Updating the "create match" UI to allow inviting 1–3 additional players.
2. Adjusting the `propose_match` / `create_match` Edge Function to write 4 participant rows.
3. Adding the "find a 4th" flow that converts an open slot in a doubles match into a `match_request` filtered by compatibility with the existing 3 players.

No schema changes required.

---

### `playstyle_pairings`

Lookup table for the matching score. Hand-coded ~30 entries.

| Column | Type | Notes |
|---|---|---|
| `style_a` | text | |
| `style_b` | text | |
| `score` | int | 0–100 |

**Primary key:** (`style_a`, `style_b`).

**Examples:**
- (`Aggressive`, `Consistent`) → 90
- (`Aggressive`, `Aggressive`) → 70
- (`Defensive`, `Defensive`) → 40
- (`Social`, `Competitive`) → 20

**RLS:** read-only for all authenticated users.

---

### `soft_blocks`

Hide users you've thumbs-downed (Phase 4 feedback feeds this; MVP creates the table empty for forward compatibility).

| Column | Type | Notes |
|---|---|---|
| `blocker_id` | uuid | FK to `profiles.id` |
| `blocked_id` | uuid | FK to `profiles.id` |
| `expires_at` | timestamptz | Default `now() + 60 days` |

**Primary key:** (`blocker_id`, `blocked_id`).

**RLS:** users manage their own blocks (`auth.uid() = blocker_id`).

---

### `device_tokens`

Push notification routing.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid | FK to `profiles.id` |
| `platform` | text | `android` \| `ios` |
| `token` | text | FCM or APNs token |
| `updated_at` | timestamptz | |

**Unique:** (`user_id`, `token`).

**RLS:** `auth.uid() = user_id` for all operations.

---

## Triggers

### `on_auth_user_created`
On insert into `auth.users`, insert a row into `profiles` with the user's id and phone.

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, phone)
  VALUES (NEW.id, NEW.phone);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### `on_match_participant_invited`
On insert into `match_participants` where `role = 'invited'` and `status = 'pending'`, trigger an edge function to push a notification to that user.

### `on_match_participant_responded`
On update of `match_participants.status` from `pending` to `confirmed` or `declined`, trigger an edge function that:
1. Updates the parent `matches.status` if all invitees have now confirmed (→ `confirmed`) or anyone declined (→ `declined`).
2. Pushes a notification to the host (and to other confirmed participants in doubles).

---

## Edge functions

### `score_feed`
**Input:** caller's JWT (no body needed; user_id derived from JWT).
**Output:** sorted list of open match requests with compatibility scores.

**Logic:**
1. Load caller's profile.
2. Query open match requests in caller's home clubs, time window not in past, not from caller.
3. Apply hard filters: not soft-blocked, intent compatible.
4. For each remaining request, compute:
   ```
   level_score      = 100 - min(100, abs(my_level - their_level) * 40)
   playstyle_score  = avg of pairing scores between my tags and theirs
   reliability_score = their_reliability * 100
   total = 0.5*level + 0.25*playstyle + 0.25*reliability
   ```
5. Sort by total desc, return top N.

**Performance target:** under 500ms for a feed of 100 candidates.

### `propose_match`
**Input:** `{ request_id: string, scheduled_at: string }`
**Output:** the created `match` with its participants.

**Logic:**
1. Validate caller from JWT.
2. Load `match_request`, verify status is `open` and `scheduled_at` is inside the window.
3. In a transaction:
   - Insert into `matches` with `host_id = caller`, `format = 'singles'`, `status = 'pending'`.
   - Insert two rows into `match_participants`:
      - Caller: `team = 1`, `role = 'host'`, `status = 'confirmed'`.
      - Request creator: `team = 2`, `role = 'invited'`, `status = 'pending'`.
   - Update `match_requests.status = 'matched'`.

In Phase 5, the doubles variant (`create_doubles_match`) inserts 4 participant rows instead of 2 and accepts an array of invited user ids.

### `respond_to_match`
**Input:** `{ match_id: string, response: 'confirmed' | 'declined' }`
**Output:** updated participant row + new overall match status.

**Logic:**
1. Validate caller from JWT and verify they are an invited participant in that match.
2. Update their `match_participants.status` and set `responded_at`.
3. If declined → set `matches.status = 'declined'`.
4. If confirmed and all other invitees are also confirmed → set `matches.status = 'confirmed'`.
5. Trigger handles the push notification.

### `cancel_match`
**Input:** `{ match_id: string }`
**Output:** updated match.

**Logic:**
1. Validate caller is the host.
2. Set `matches.status = 'cancelled'`.
3. Push to all other participants.

### `send_match_invite_notification`
Triggered by `on_match_participant_invited`. Looks up the invited user's device tokens and sends a push via FCM/APNs with deep link to the proposal screen.

### `send_match_status_change_notification`
Triggered by `on_match_participant_responded`. Sends a push to the host (and other participants in doubles) summarizing the new match state.

---

## Storage buckets

### `profile-photos`
- Public read.
- Authenticated upload to own folder only: path must start with `{auth.uid()}/`.
- Max file size: 2MB.
- Allowed types: image/jpeg, image/png, image/webp.

---

## Migration order

Migrations should be applied in this order. Each is a separate file in `/supabase/migrations`:

1. `0001_init.sql` — extensions (uuid-ossp, pgcrypto)
2. `0002_clubs.sql` — clubs table + seed
3. `0003_profiles.sql` — profiles table + trigger + RLS
4. `0004_public_profiles_view.sql` — view + RLS
5. `0005_match_requests.sql` — table + indexes + RLS
6. `0006_matches.sql` — `matches` + `match_participants` tables + constraints
7. `0007_is_match_participant_fn.sql` — `SECURITY DEFINER` helper function
8. `0008_matches_rls.sql` — RLS policies on `matches` and `match_participants` (depends on the helper fn)
9. `0009_playstyle_pairings.sql` — table + seed
10. `0010_soft_blocks.sql` — table + RLS
11. `0011_device_tokens.sql` — table + RLS
12. `0012_storage_profile_photos.sql` — bucket + policies
13. `0013_edge_function_score_feed.sql` — function deployment marker
14. `0014_push_triggers.sql` — match insert/update triggers

> The split between `0006` (tables) and `0008` (RLS policies) is intentional: the policies depend on the helper function in `0007`, and keeping schema and policies in separate files makes both easier to review.