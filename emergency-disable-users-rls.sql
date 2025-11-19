-- EMERGENCY: Temporarily disable RLS on users table to allow registration
-- Run this in your Supabase SQL Editor

-- ==============================================
-- TEMPORARILY DISABLE RLS ON USERS TABLE
-- ==============================================

-- Disable RLS on users table
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- ==============================================
-- VERIFY RLS IS DISABLED
-- ==============================================

-- Check if RLS is disabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';













