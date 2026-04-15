-- match_requests: availability windows that users post to find a match.
-- Status machine: open → matched / cancelled / expired.

CREATE TABLE public.match_requests (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id       uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  club_id          uuid NOT NULL REFERENCES public.clubs (id),
  proposed_window  tstzrange NOT NULL,
  status           text NOT NULL DEFAULT 'open',
  created_at       timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.match_requests
  ADD CONSTRAINT match_requests_status_values
    CHECK (status IN ('open', 'matched', 'cancelled', 'expired'));

-- Feed query: filter by club + status, range-order by window
CREATE INDEX match_requests_feed_idx
  ON public.match_requests (club_id, status, proposed_window);

-- "My requests" query: filter by creator + status
CREATE INDEX match_requests_creator_idx
  ON public.match_requests (creator_id, status);

ALTER TABLE public.match_requests ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can see open requests
CREATE POLICY "match_requests: select open"
  ON public.match_requests
  FOR SELECT
  TO authenticated
  USING (status = 'open');

-- Users can always see their own requests regardless of status
CREATE POLICY "match_requests: select own"
  ON public.match_requests
  FOR SELECT
  TO authenticated
  USING (auth.uid() = creator_id);

-- Users can only insert requests as themselves
CREATE POLICY "match_requests: insert own"
  ON public.match_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = creator_id);

-- Users can only update their own requests
CREATE POLICY "match_requests: update own"
  ON public.match_requests
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = creator_id)
  WITH CHECK (auth.uid() = creator_id);

-- Users can only delete their own requests
CREATE POLICY "match_requests: delete own"
  ON public.match_requests
  FOR DELETE
  TO authenticated
  USING (auth.uid() = creator_id);

-- Enable Realtime for live feed updates (Task 3a.6)
-- INSERT events let other users see new requests immediately.
-- UPDATE events let clients drop requests whose status leaves 'open'.
ALTER PUBLICATION supabase_realtime ADD TABLE public.match_requests;
