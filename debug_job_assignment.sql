-- Debug script to check what's happening with job assignments
-- Run this in Supabase SQL Editor to see the current state

-- Check current jobs and their driver_id values
SELECT 
    id,
    title,
    status,
    driver_id,
    admin_id,
    created_at,
    updated_at
FROM jobs 
ORDER BY created_at DESC 
LIMIT 10;

-- Check if there are any jobs with status 'assigned' but driver_id is NULL
SELECT 
    id,
    title,
    status,
    driver_id,
    admin_id
FROM jobs 
WHERE status = 'assigned' 
AND driver_id IS NULL;

-- Check the current RLS policies
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
WHERE tablename IN ('users', 'jobs')
ORDER BY tablename, policyname;

-- Check if RLS is enabled
SELECT 
    schemaname, 
    tablename, 
    rowsecurity 
FROM pg_tables 
WHERE tablename IN ('users', 'jobs');
