-- Migration: update playstyle tags to tennis values and repopulate playstyle_pairings

-- Clear existing padel-era pairings and repopulate with 11 tennis playstyle tags:
-- Power Hitter, Spin Master, Net Rusher, Counterpuncher, Tactical Player,
-- Big Server, Retriever, All-Court, Aggressive Baseliner, Moonballer, Slice Artist

TRUNCATE TABLE public.playstyle_pairings;

INSERT INTO public.playstyle_pairings (style_a, style_b, score) VALUES

  -- Self pairings
  ('Power Hitter',         'Power Hitter',         70),
  ('Spin Master',          'Spin Master',           75),
  ('Net Rusher',           'Net Rusher',            70),
  ('Counterpuncher',       'Counterpuncher',        75),
  ('Tactical Player',      'Tactical Player',       80),
  ('Big Server',           'Big Server',            65),
  ('Retriever',            'Retriever',             70),
  ('All-Court',            'All-Court',             85),
  ('Aggressive Baseliner', 'Aggressive Baseliner',  70),
  ('Moonballer',           'Moonballer',            55),
  ('Slice Artist',         'Slice Artist',          60),

  -- Power Hitter ×
  ('Power Hitter',         'Spin Master',           75),
  ('Spin Master',          'Power Hitter',          75),
  ('Power Hitter',         'Net Rusher',            80),
  ('Net Rusher',           'Power Hitter',          80),
  ('Power Hitter',         'Counterpuncher',        85),
  ('Counterpuncher',       'Power Hitter',          85),
  ('Power Hitter',         'Tactical Player',       80),
  ('Tactical Player',      'Power Hitter',          80),
  ('Power Hitter',         'Big Server',            75),
  ('Big Server',           'Power Hitter',          75),
  ('Power Hitter',         'Retriever',             80),
  ('Retriever',            'Power Hitter',          80),
  ('Power Hitter',         'All-Court',             85),
  ('All-Court',            'Power Hitter',          85),
  ('Power Hitter',         'Aggressive Baseliner',  70),
  ('Aggressive Baseliner', 'Power Hitter',          70),
  ('Power Hitter',         'Moonballer',            60),
  ('Moonballer',           'Power Hitter',          60),
  ('Power Hitter',         'Slice Artist',          70),
  ('Slice Artist',         'Power Hitter',          70),

  -- Spin Master ×
  ('Spin Master',          'Net Rusher',            75),
  ('Net Rusher',           'Spin Master',           75),
  ('Spin Master',          'Counterpuncher',        80),
  ('Counterpuncher',       'Spin Master',           80),
  ('Spin Master',          'Tactical Player',       85),
  ('Tactical Player',      'Spin Master',           85),
  ('Spin Master',          'Big Server',            70),
  ('Big Server',           'Spin Master',           70),
  ('Spin Master',          'Retriever',             75),
  ('Retriever',            'Spin Master',           75),
  ('Spin Master',          'All-Court',             85),
  ('All-Court',            'Spin Master',           85),
  ('Spin Master',          'Aggressive Baseliner',  80),
  ('Aggressive Baseliner', 'Spin Master',           80),
  ('Spin Master',          'Moonballer',            65),
  ('Moonballer',           'Spin Master',           65),
  ('Spin Master',          'Slice Artist',          80),
  ('Slice Artist',         'Spin Master',           80),

  -- Net Rusher ×
  ('Net Rusher',           'Counterpuncher',        85),
  ('Counterpuncher',       'Net Rusher',            85),
  ('Net Rusher',           'Tactical Player',       85),
  ('Tactical Player',      'Net Rusher',            85),
  ('Net Rusher',           'Big Server',            80),
  ('Big Server',           'Net Rusher',            80),
  ('Net Rusher',           'Retriever',             75),
  ('Retriever',            'Net Rusher',            75),
  ('Net Rusher',           'All-Court',             85),
  ('All-Court',            'Net Rusher',            85),
  ('Net Rusher',           'Aggressive Baseliner',  75),
  ('Aggressive Baseliner', 'Net Rusher',            75),
  ('Net Rusher',           'Moonballer',            55),
  ('Moonballer',           'Net Rusher',            55),
  ('Net Rusher',           'Slice Artist',          70),
  ('Slice Artist',         'Net Rusher',            70),

  -- Counterpuncher ×
  ('Counterpuncher',       'Tactical Player',       90),
  ('Tactical Player',      'Counterpuncher',        90),
  ('Counterpuncher',       'Big Server',            65),
  ('Big Server',           'Counterpuncher',        65),
  ('Counterpuncher',       'Retriever',             75),
  ('Retriever',            'Counterpuncher',        75),
  ('Counterpuncher',       'All-Court',             85),
  ('All-Court',            'Counterpuncher',        85),
  ('Counterpuncher',       'Aggressive Baseliner',  80),
  ('Aggressive Baseliner', 'Counterpuncher',        80),
  ('Counterpuncher',       'Moonballer',            70),
  ('Moonballer',           'Counterpuncher',        70),
  ('Counterpuncher',       'Slice Artist',          80),
  ('Slice Artist',         'Counterpuncher',        80),

  -- Tactical Player ×
  ('Tactical Player',      'Big Server',            75),
  ('Big Server',           'Tactical Player',       75),
  ('Tactical Player',      'Retriever',             80),
  ('Retriever',            'Tactical Player',       80),
  ('Tactical Player',      'All-Court',             90),
  ('All-Court',            'Tactical Player',       90),
  ('Tactical Player',      'Aggressive Baseliner',  80),
  ('Aggressive Baseliner', 'Tactical Player',       80),
  ('Tactical Player',      'Moonballer',            70),
  ('Moonballer',           'Tactical Player',       70),
  ('Tactical Player',      'Slice Artist',          85),
  ('Slice Artist',         'Tactical Player',       85),

  -- Big Server ×
  ('Big Server',           'Retriever',             70),
  ('Retriever',            'Big Server',            70),
  ('Big Server',           'All-Court',             80),
  ('All-Court',            'Big Server',            80),
  ('Big Server',           'Aggressive Baseliner',  80),
  ('Aggressive Baseliner', 'Big Server',            80),
  ('Big Server',           'Moonballer',            55),
  ('Moonballer',           'Big Server',            55),
  ('Big Server',           'Slice Artist',          65),
  ('Slice Artist',         'Big Server',            65),

  -- Retriever ×
  ('Retriever',            'All-Court',             85),
  ('All-Court',            'Retriever',             85),
  ('Retriever',            'Aggressive Baseliner',  75),
  ('Aggressive Baseliner', 'Retriever',             75),
  ('Retriever',            'Moonballer',            70),
  ('Moonballer',           'Retriever',             70),
  ('Retriever',            'Slice Artist',          75),
  ('Slice Artist',         'Retriever',             75),

  -- All-Court ×
  ('All-Court',            'Aggressive Baseliner',  80),
  ('Aggressive Baseliner', 'All-Court',             80),
  ('All-Court',            'Moonballer',            70),
  ('Moonballer',           'All-Court',             70),
  ('All-Court',            'Slice Artist',          85),
  ('Slice Artist',         'All-Court',             85),

  -- Aggressive Baseliner ×
  ('Aggressive Baseliner', 'Moonballer',            60),
  ('Moonballer',           'Aggressive Baseliner',  60),
  ('Aggressive Baseliner', 'Slice Artist',          75),
  ('Slice Artist',         'Aggressive Baseliner',  75),

  -- Moonballer ×
  ('Moonballer',           'Slice Artist',          65),
  ('Slice Artist',         'Moonballer',            65);
