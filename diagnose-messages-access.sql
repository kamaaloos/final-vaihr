-- Diagnose messages table access issues
-- Run this in your Supabase SQL Editor

-- 1. Check RLS policies on messages table
SELECT 
    'RLS Policies on messages table:' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'messages' AND schemaname = 'public';

-- 2. Check if RLS is enabled on messages table
SELECT 
    'RLS Status on messages table:' as info,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'messages' AND schemaname = 'public';

-- 3. Test direct access to messages table (as service role)
SELECT 
    'Direct access test:' as info,
    COUNT(*) as total_messages,
    COUNT(text) as messages_with_text
FROM public.messages;

-- 4. Check if there are multiple messages tables
SELECT 
    'All messages tables:' as info,
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE tablename LIKE '%message%'
ORDER BY schemaname, tablename;

-- 5. Check current user permissions
SELECT 
    'Current user info:' as info,
    current_user,
    session_user,
    current_database();

-- 6. Test a simple query that should work
SELECT 
    'Simple test query:' as info,
    id,
    chat_id,
    sender_id,
    created_at
FROM public.messages 
LIMIT 1;
