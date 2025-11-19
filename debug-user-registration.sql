-- Debug user registration issues
-- Check what might be blocking user creation

-- Check if there are any triggers on auth.users that might be failing
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth';

-- Check if there are any constraints on the users table
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'users' 
AND table_schema = 'public';

-- Check if there are any functions that might be called during user creation
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name LIKE '%user%' 
AND routine_schema = 'public';

-- Check the current RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('users', 'user_status');

-- Check if there are any policies that might block INSERT
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND cmd = 'INSERT';
