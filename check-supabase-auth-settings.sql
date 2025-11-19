-- Check Supabase auth configuration
-- This will help us understand what's causing the phone constraint issue

-- Check if there are any auth-related functions or triggers
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'auth'
ORDER BY routine_name;

-- Check auth.users table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'auth'
ORDER BY ordinal_position;

-- Check if there are any custom auth functions
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%auth%'
ORDER BY routine_name;
