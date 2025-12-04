-- Add is_active column to holding_lots table
-- Run this in Supabase SQL Editor

-- Add the column (default true for new records)
ALTER TABLE holding_lots 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Set all existing records to active
UPDATE holding_lots 
SET is_active = true 
WHERE is_active IS NULL;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_holding_lots_is_active 
ON holding_lots(user_id, asset_symbol, is_active);

-- Update the existing index to include is_active
DROP INDEX IF EXISTS idx_holding_lots_user_symbol;
CREATE INDEX idx_holding_lots_user_symbol 
ON holding_lots(user_id, asset_symbol, is_active, purchase_date);
