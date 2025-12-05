-- Adds risk management fields to holdings table (nullable)
-- Ensure this is run on your Supabase database
ALTER TABLE public.holdings
  ADD COLUMN IF NOT EXISTS stop_loss numeric,
  ADD COLUMN IF NOT EXISTS bracket_lower numeric,
  ADD COLUMN IF NOT EXISTS bracket_upper numeric;
