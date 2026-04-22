-- Migration: add proposed_at generated column to match_requests for ordering

ALTER TABLE public.match_requests
  ADD COLUMN proposed_at timestamptz GENERATED ALWAYS AS (lower(proposed_window)) STORED;

-- Index for paginated feed queries ordered by window start time
CREATE INDEX match_requests_proposed_at_idx
  ON public.match_requests (proposed_at ASC);
