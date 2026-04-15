-- public_profiles: safe subset of profiles for other users to read.
-- Deliberately excludes: phone, self_rated_level, intent, timestamps.

CREATE OR REPLACE VIEW public.public_profiles AS
SELECT
  id,
  display_name,
  photo_url,
  calibrated_level,
  playstyle_tags,
  home_club_ids,
  reliability_score
FROM public.profiles;

GRANT SELECT ON public.public_profiles TO authenticated;
