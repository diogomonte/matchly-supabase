-- Phase 2: extend profiles with the full schema required for matching.

ALTER TABLE public.profiles
  ADD COLUMN display_name      text,
  ADD COLUMN photo_url         text,
  ADD COLUMN home_club_ids     uuid[],
  ADD COLUMN self_rated_level  numeric(2, 1),
  ADD COLUMN calibrated_level  numeric(2, 1),
  ADD COLUMN playstyle_tags    text[],
  ADD COLUMN intent            text,
  ADD COLUMN reliability_score numeric(3, 2) NOT NULL DEFAULT 1.00;

-- Constraints from the data model
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_self_rated_level_range
    CHECK (self_rated_level IS NULL OR self_rated_level BETWEEN 1.0 AND 5.0),
  ADD CONSTRAINT profiles_calibrated_level_range
    CHECK (calibrated_level IS NULL OR calibrated_level BETWEEN 1.0 AND 5.0),
  ADD CONSTRAINT profiles_playstyle_tags_max3
    CHECK (playstyle_tags IS NULL OR array_length(playstyle_tags, 1) <= 3),
  ADD CONSTRAINT profiles_home_club_ids_max2
    CHECK (home_club_ids IS NULL OR array_length(home_club_ids, 1) <= 2),
  ADD CONSTRAINT profiles_intent_values
    CHECK (intent IS NULL OR intent IN ('competitive', 'social', 'both')),
  ADD CONSTRAINT profiles_reliability_score_range
    CHECK (reliability_score BETWEEN 0.00 AND 1.00);
