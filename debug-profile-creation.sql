-- Debug profile creation and fetchUserData issue
-- Run this in your Supabase SQL Editor

-- ==============================================
-- CHECK IF PROFILE EXISTS
-- ==============================================

-- Check if the user profile exists
SELECT 
    'User Profile Check' as test_type,
    id,
    email,
    name,
    role,
    email_verified,
    created_at
FROM users 
WHERE id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47';

-- ==============================================
-- CHECK RLS POLICIES ON USERS TABLE
-- ==============================================

-- Check current RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
ORDER BY policyname;

-- ==============================================
-- CHECK IF RLS IS ENABLED
-- ==============================================

-- Check if RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';













