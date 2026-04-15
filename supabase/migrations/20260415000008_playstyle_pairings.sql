-- playstyle_pairings: scoring lookup for the matching engine.
-- 7 playstyle tags: Aggressive, Consistent, Defensive, Social, Competitive, NetPlayer, Lefty
--
-- Score semantics (0–100):
--   90–100  Excellent pairing — complementary styles that cover the court well
--   70–89   Good pairing — compatible approaches, minor tension
--   50–69   Neutral — playable but no natural synergy
--   20–49   Poor pairing — mismatched goals or tempo
--    0–19   Very poor — likely frustrating for both players
--
-- All pairs are stored symmetrically: both (A,B) and (B,A) are inserted so
-- queries can always hit (style_a = X AND style_b = Y) without a CASE.

CREATE TABLE public.playstyle_pairings (
  style_a text NOT NULL,
  style_b text NOT NULL,
  score   int  NOT NULL,
  PRIMARY KEY (style_a, style_b),
  CONSTRAINT playstyle_pairings_score_range CHECK (score BETWEEN 0 AND 100)
);

ALTER TABLE public.playstyle_pairings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "playstyle_pairings: authenticated read"
  ON public.playstyle_pairings
  FOR SELECT
  TO authenticated
  USING (true);

-- Seed: all symmetric pairs (49 rows = 7 self-pairs + 21 cross-pairs × 2)
INSERT INTO public.playstyle_pairings (style_a, style_b, score) VALUES
  -- Self-pairs
  ('Aggressive',  'Aggressive',  70),
  ('Consistent',  'Consistent',  75),
  ('Defensive',   'Defensive',   40),
  ('Social',      'Social',      70),
  ('Competitive', 'Competitive', 95),
  ('NetPlayer',   'NetPlayer',   70),
  ('Lefty',       'Lefty',       65),

  -- Aggressive ×
  ('Aggressive',  'Consistent',  90),
  ('Consistent',  'Aggressive',  90),
  ('Aggressive',  'Defensive',   85),
  ('Defensive',   'Aggressive',  85),
  ('Aggressive',  'Social',      55),
  ('Social',      'Aggressive',  55),
  ('Aggressive',  'Competitive', 85),
  ('Competitive', 'Aggressive',  85),
  ('Aggressive',  'NetPlayer',   80),
  ('NetPlayer',   'Aggressive',  80),
  ('Aggressive',  'Lefty',       75),
  ('Lefty',       'Aggressive',  75),

  -- Consistent ×
  ('Consistent',  'Defensive',   70),
  ('Defensive',   'Consistent',  70),
  ('Consistent',  'Social',      65),
  ('Social',      'Consistent',  65),
  ('Consistent',  'Competitive', 80),
  ('Competitive', 'Consistent',  80),
  ('Consistent',  'NetPlayer',   75),
  ('NetPlayer',   'Consistent',  75),
  ('Consistent',  'Lefty',       70),
  ('Lefty',       'Consistent',  70),

  -- Defensive ×
  ('Defensive',   'Social',      60),
  ('Social',      'Defensive',   60),
  ('Defensive',   'Competitive', 50),
  ('Competitive', 'Defensive',   50),
  ('Defensive',   'NetPlayer',   80),
  ('NetPlayer',   'Defensive',   80),
  ('Defensive',   'Lefty',       65),
  ('Lefty',       'Defensive',   65),

  -- Social ×
  ('Social',      'Competitive', 20),
  ('Competitive', 'Social',      20),
  ('Social',      'NetPlayer',   60),
  ('NetPlayer',   'Social',      60),
  ('Social',      'Lefty',       65),
  ('Lefty',       'Social',      65),

  -- Competitive ×
  ('Competitive', 'NetPlayer',   85),
  ('NetPlayer',   'Competitive', 85),
  ('Competitive', 'Lefty',       75),
  ('Lefty',       'Competitive', 75),

  -- NetPlayer ×
  ('NetPlayer',   'Lefty',       75),
  ('Lefty',       'NetPlayer',   75);
