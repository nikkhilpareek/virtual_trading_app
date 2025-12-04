-- DANGER: This will delete ALL your holding lots
-- Only run this if you want to completely reset the lot system
-- After running this, only NEW purchases will create lots

-- Delete ALL lots for the current user
-- Replace 'YOUR_USER_ID' with your actual user ID from auth.users table

DELETE FROM holding_lots 
WHERE user_id = 'YOUR_USER_ID';

-- OR to delete ALL lots in the entire system (be careful!):
-- DELETE FROM holding_lots;

-- To find your user ID first, run:
-- SELECT id, email FROM auth.users;
