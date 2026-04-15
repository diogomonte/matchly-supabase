-- soft_blocks: hides players a user has thumbs-downed from their feed.
-- Populated in Phase 4 (post-match feedback). Created empty here so the
-- score_feed edge function can query it without errors from day one.

CREATE TABLE public.soft_blocks (
  blocker_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  blocked_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '60 days'),
  PRIMARY KEY (blocker_id, blocked_id)
);

ALTER TABLE public.soft_blocks ENABLE ROW LEVEL SECURITY;

-- Users manage their own blocks only
CREATE POLICY "soft_blocks: select own"
  ON public.soft_blocks
  FOR SELECT
  TO authenticated
  USING (auth.uid() = blocker_id);

CREATE POLICY "soft_blocks: insert own"
  ON public.soft_blocks
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "soft_blocks: delete own"
  ON public.soft_blocks
  FOR DELETE
  TO authenticated
  USING (auth.uid() = blocker_id);
