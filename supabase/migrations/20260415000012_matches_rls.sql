-- RLS policies for matches and match_participants.
-- Kept in a separate migration from the tables because the policies depend on
-- is_match_participant() defined in 20260415000011_is_match_participant_fn.sql.

-- ── matches ───────────────────────────────────────────────────────────────────

ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

-- Only participants can see a match
CREATE POLICY "matches: select as participant"
  ON public.matches
  FOR SELECT
  TO authenticated
  USING (public.is_match_participant(id));

-- Participants can update a match (status transitions validated by edge fns)
-- INSERT is intentionally blocked: only the propose_match edge function
-- (running with the service-role key) may create matches.
CREATE POLICY "matches: update as participant"
  ON public.matches
  FOR UPDATE
  TO authenticated
  USING (public.is_match_participant(id))
  WITH CHECK (public.is_match_participant(id));

-- ── match_participants ────────────────────────────────────────────────────────

ALTER TABLE public.match_participants ENABLE ROW LEVEL SECURITY;

-- Anyone in the match can see all participant rows for that match
CREATE POLICY "match_participants: select as participant"
  ON public.match_participants
  FOR SELECT
  TO authenticated
  USING (public.is_match_participant(match_id));

-- Users can update their own participant row (confirm / decline)
-- INSERT is intentionally blocked: only the propose_match edge function
-- (running with the service-role key) may create participant rows.
CREATE POLICY "match_participants: update own"
  ON public.match_participants
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Realtime ──────────────────────────────────────────────────────────────────

-- Live updates so both players see confirmation without polling
ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;
ALTER PUBLICATION supabase_realtime ADD TABLE public.match_participants;
