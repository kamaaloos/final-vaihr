-- Check database relationships and dependencies before cleaning policies

-- ==============================================
-- CHECK TABLE STRUCTURE AND RELATIONSHIPS
-- ==============================================

-- Check users table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check user_status table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'user_status' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ==============================================
-- CHECK FOREIGN KEY RELATIONSHIPS
-- ==============================================

-- Check foreign keys FROM user_status table
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name IN ('users', 'user_status')
AND tc.table_schema = 'public';

-- Check foreign keys TO users table (other tables referencing users)
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND ccu.table_name = 'users'
AND tc.table_schema = 'public';

-- ==============================================
-- CHECK INDEXES
-- ==============================================

-- Check indexes on users table
SELECT 
    indexname, 
    indexdef
FROM pg_indexes 
WHERE tablename = 'users' 
AND schemaname = 'public';

-- Check indexes on user_status table
SELECT 
    indexname, 
    indexdef
FROM pg_indexes 
WHERE tablename = 'user_status' 
AND schemaname = 'public';

-- ==============================================
-- CHECK TRIGGERS
-- ==============================================

-- Check triggers on users table
SELECT 
    trigger_name, 
    event_manipulation, 
    action_timing, 
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'public';

-- Check triggers on user_status table
SELECT 
    trigger_name, 
    event_manipulation, 
    action_timing, 
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'user_status' 
AND event_object_schema = 'public';

-- ==============================================
-- CHECK FUNCTIONS THAT MIGHT DEPEND ON POLICIES
-- ==============================================

-- Check if there are any functions that might reference these tables
SELECT 
    routine_name, 
    routine_type, 
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_definition LIKE '%users%'
OR routine_definition LIKE '%user_status%';
