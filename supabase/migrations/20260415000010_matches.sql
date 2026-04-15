-- matches + match_participants: the core of the MVP matching loop.
-- RLS is applied in 20260415000012_matches_rls.sql (depends on the
-- is_match_participant helper in 20260415000011_is_match_participant_fn.sql).

-- ── matches ───────────────────────────────────────────────────────────────────

CREATE TABLE public.matches (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id   uuid        REFERENCES public.match_requests (id) ON DELETE SET NULL,
  host_id      uuid        NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  club_id      uuid        NOT NULL REFERENCES public.clubs (id),
  scheduled_at timestamptz NOT NULL,
  format       text        NOT NULL DEFAULT 'singles',
  status       text        NOT NULL DEFAULT 'pending',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.matches
  ADD CONSTRAINT matches_format_values
    CHECK (format IN ('singles', 'doubles'));

ALTER TABLE public.matches
  ADD CONSTRAINT matches_status_values
    CHECK (status IN ('pending', 'confirmed', 'declined', 'cancelled', 'completed'));

-- "matches I'm hosting" query
CREATE INDEX matches_host_status_idx
  ON public.matches (host_id, status);

-- upcoming confirmed matches (hot path for the upcoming strip in the app)
CREATE INDEX matches_scheduled_confirmed_idx
  ON public.matches (scheduled_at) WHERE status = 'confirmed';

-- ── match_participants ────────────────────────────────────────────────────────

CREATE TABLE public.match_participants (
  match_id     uuid      NOT NULL REFERENCES public.matches (id) ON DELETE CASCADE,
  user_id      uuid      NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  team         smallint  NOT NULL,
  role         text      NOT NULL,
  status       text      NOT NULL DEFAULT 'pending',
  joined_at    timestamptz NOT NULL DEFAULT now(),
  responded_at timestamptz,

  PRIMARY KEY (match_id, user_id)
);

ALTER TABLE public.match_participants
  ADD CONSTRAINT match_participants_team_values
    CHECK (team IN (1, 2));

ALTER TABLE public.match_participants
  ADD CONSTRAINT match_participants_role_values
    CHECK (role IN ('host', 'invited'));

ALTER TABLE public.match_participants
  ADD CONSTRAINT match_participants_status_values
    CHECK (status IN ('pending', 'confirmed', 'declined'));

-- Enforce exactly one host row per match
CREATE UNIQUE INDEX match_participants_one_host_idx
  ON public.match_participants (match_id) WHERE role = 'host';

-- "matches I'm in" — most common query in the app
CREATE INDEX match_participants_user_status_idx
  ON public.match_participants (user_id, status);

-- load full participant list for a match
CREATE INDEX match_participants_match_id_idx
  ON public.match_participants (match_id);
