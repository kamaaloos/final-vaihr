-- Check Supabase version and auth configuration
-- This will help us understand the phone constraint issue

-- Check Supabase version
SELECT version();

-- Check if there are any custom auth functions or triggers
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'auth'
  AND routine_name LIKE '%phone%'
ORDER BY routine_name;

-- Check auth.users constraints
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    tc.is_deferrable,
    tc.initially_deferred
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'users' 
AND tc.table_schema = 'auth'
AND kcu.column_name = 'phone'
ORDER BY tc.constraint_name;

-- Check if there are any auth-related settings (Supabase doesn't have pg_settings)
-- This section is commented out as pg_settings is not available in Supabase
-- SELECT 
--     setting_name,
--     setting_value
-- FROM pg_settings 
-- WHERE setting_name LIKE '%auth%'
-- ORDER BY setting_name;
