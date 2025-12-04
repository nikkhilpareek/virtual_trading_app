-- Check and fix RLS policies for is_active column updates
-- Run this in Supabase SQL Editor

-- First, check if the column exists and has data
SELECT id, asset_symbol, quantity, is_active, user_id 
FROM holding_lots 
LIMIT 10;

-- Check existing policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'holding_lots';

-- Drop and recreate the update policy to ensure it allows is_active updates
DROP POLICY IF EXISTS "Users can update their own holding lots" ON holding_lots;

CREATE POLICY "Users can update their own holding lots"
ON holding_lots
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Verify the policy was created
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'holding_lots' AND cmd = 'UPDATE';
