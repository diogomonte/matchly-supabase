-- is_match_participant: SECURITY DEFINER helper used by RLS policies on
-- matches and match_participants.
--
-- Without this, a SELECT policy on match_participants that checks
-- "is the caller in this match?" would recursively reference itself
-- and either fail or infinite-loop. SECURITY DEFINER lets it bypass
-- RLS internally and answer the question cleanly.
--
-- Used by:
--   matches          SELECT/UPDATE policy: is_match_participant(matches.id)
--   match_participants SELECT policy:     is_match_participant(match_participants.match_id)

CREATE OR REPLACE FUNCTION public.is_match_participant(_match_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.match_participants
    WHERE match_id = _match_id
      AND user_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.is_match_participant(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.is_match_participant(uuid) TO authenticated;
