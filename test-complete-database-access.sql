-- Test complete database access after all fixes
-- Run this in your Supabase SQL Editor

-- ==============================================
-- TEST ALL TABLE ACCESS
-- ==============================================

-- Test users table access
SELECT 'users' as table_name, COUNT(*) as record_count FROM public.users
UNION ALL
SELECT 'jobs' as table_name, COUNT(*) as record_count FROM public.jobs
UNION ALL
SELECT 'user_status' as table_name, COUNT(*) as record_count FROM public.user_status
UNION ALL
SELECT 'profiles' as table_name, COUNT(*) as record_count FROM public.profiles
UNION ALL
SELECT 'chats' as table_name, COUNT(*) as record_count FROM public.chats
UNION ALL
SELECT 'messages' as table_name, COUNT(*) as record_count FROM public.messages
UNION ALL
SELECT 'notifications' as table_name, COUNT(*) as record_count FROM public.notifications;

-- ==============================================
-- TEST VIEWS ACCESS
-- ==============================================

-- Test jobs_with_admin view
SELECT 'jobs_with_admin' as view_name, COUNT(*) as record_count FROM public.jobs_with_admin
UNION ALL
SELECT 'chat_list' as view_name, COUNT(*) as record_count FROM public.chat_list
UNION ALL
SELECT 'chat_relationships' as view_name, COUNT(*) as record_count FROM public.chat_relationships;

-- ==============================================
-- TEST RPC FUNCTIONS
-- ==============================================

-- Test if upsert_user_status function exists and is callable
SELECT routine_name, routine_type, data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%upsert_user_status%'
ORDER BY routine_name;

-- ==============================================
-- TEST FOREIGN KEY RELATIONSHIPS
-- ==============================================

-- Check foreign key constraints
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name = 'jobs'
AND tc.table_schema = 'public';

-- ==============================================
-- TEST RLS POLICIES
-- ==============================================

-- Check RLS status for all tables
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'jobs', 'user_status', 'profiles', 'chats', 'messages', 'notifications')
ORDER BY tablename;

-- Check policies for users table
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public'
ORDER BY policyname;













