-- Add intent to public_profiles so the score_feed join can filter by intent compatibility.
-- intent is not sensitive (competitive/social/both) and is required by the scoring algorithm.

CREATE OR REPLACE VIEW public.public_profiles AS
SELECT
  id,
  display_name,
  photo_url,
  calibrated_level,
  playstyle_tags,
  home_club_ids,
  reliability_score,
  intent
FROM public.profiles;

GRANT SELECT ON public.public_profiles TO authenticated;
