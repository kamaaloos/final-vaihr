-- Check for triggers and functions that might be failing during user creation
-- The error is happening at supabase.auth.signUp level, not RLS policies

-- Check for triggers on auth.users table
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing,
    action_orientation
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth'
ORDER BY trigger_name;

-- Check for functions that might be called during user creation
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND (
    routine_name LIKE '%user%' 
    OR routine_name LIKE '%auth%'
    OR routine_name LIKE '%signup%'
    OR routine_name LIKE '%register%'
)
ORDER BY routine_name;

-- Check for any custom functions in the auth schema
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'auth'
ORDER BY routine_name;

-- Check if there are any constraints that might be failing
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    tc.table_name,
    tc.table_schema,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'users' 
AND tc.table_schema = 'auth'
ORDER BY tc.constraint_name;
