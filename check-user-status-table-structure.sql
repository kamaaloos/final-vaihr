-- Check user_status table structure
-- Run this in your Supabase SQL Editor

-- Check columns in user_status table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_status' 
AND table_schema = 'public'
ORDER BY column_name;













