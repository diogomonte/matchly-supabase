-- Migration: create matchly tables (profiles, matches, match_players)

-- ============================================================================
-- Enums
-- ============================================================================

CREATE TYPE public.sport AS ENUM ('tennis', 'padel');

CREATE TYPE public.skill_level AS ENUM ('beginner', 'intermediate', 'advanced');

CREATE TYPE public.match_status AS ENUM ('open', 'confirmed', 'completed', 'cancelled');

CREATE TYPE public.participation_status AS ENUM ('pending', 'accepted', 'declined');

-- ============================================================================
-- Profiles
-- ============================================================================

CREATE TABLE public.profiles (
  id            uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  display_name  text,
  avatar_url    text,
  skill_level   public.skill_level DEFAULT 'beginner',
  preferred_sport public.sport,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Anyone can view profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can delete their own profile
CREATE POLICY "Users can delete their own profile"
  ON public.profiles FOR DELETE
  USING (auth.uid() = id);

-- ============================================================================
-- Matches
-- ============================================================================

CREATE TABLE public.matches (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sport         public.sport NOT NULL,
  status        public.match_status NOT NULL DEFAULT 'open',
  scheduled_at  timestamptz NOT NULL,
  location      text NOT NULL,
  max_players   int NOT NULL DEFAULT 4,
  created_by    uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT max_players_range CHECK (max_players BETWEEN 2 AND 8)
);

ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can view matches
CREATE POLICY "Matches are viewable by authenticated users"
  ON public.matches FOR SELECT
  TO authenticated
  USING (true);

-- Authenticated users can create matches
CREATE POLICY "Authenticated users can create matches"
  ON public.matches FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

-- Match creator can update their match
CREATE POLICY "Match creator can update their match"
  ON public.matches FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

-- Match creator can delete their match
CREATE POLICY "Match creator can delete their match"
  ON public.matches FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by);

-- ============================================================================
-- Match Players (junction table)
-- ============================================================================

CREATE TABLE public.match_players (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id      uuid NOT NULL REFERENCES public.matches (id) ON DELETE CASCADE,
  player_id     uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  status        public.participation_status NOT NULL DEFAULT 'pending',
  joined_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (match_id, player_id)
);

ALTER TABLE public.match_players ENABLE ROW LEVEL SECURITY;

-- Authenticated users can view match players
CREATE POLICY "Match players are viewable by authenticated users"
  ON public.match_players FOR SELECT
  TO authenticated
  USING (true);

-- Users can join matches (insert themselves)
CREATE POLICY "Users can join matches"
  ON public.match_players FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = player_id);

-- Users can update their own participation (accept/decline)
CREATE POLICY "Users can update their own participation"
  ON public.match_players FOR UPDATE
  TO authenticated
  USING (auth.uid() = player_id)
  WITH CHECK (auth.uid() = player_id);

-- Users can remove themselves from a match
CREATE POLICY "Users can leave matches"
  ON public.match_players FOR DELETE
  TO authenticated
  USING (auth.uid() = player_id);
