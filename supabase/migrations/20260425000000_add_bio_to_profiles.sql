-- Migration: add bio column to profiles

ALTER TABLE public.profiles
  ADD COLUMN bio text CHECK (char_length(bio) <= 100);
