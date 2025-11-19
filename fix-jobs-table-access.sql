-- Fix jobs table access permissions
-- Run this in your Supabase SQL Editor

-- ==============================================
-- CHECK JOBS TABLE RLS STATUS
-- ==============================================

-- Check if jobs table has RLS enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'jobs' AND schemaname = 'public';

-- Check current policies on jobs table
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
WHERE tablename = 'jobs' AND schemaname = 'public'
ORDER BY policyname;

-- ==============================================
-- FIX JOBS TABLE RLS POLICIES
-- ==============================================

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can insert jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can update jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can delete jobs" ON public.jobs;
DROP POLICY IF EXISTS "Admins can view all jobs" ON public.jobs;
DROP POLICY IF EXISTS "Admins can insert jobs" ON public.jobs;
DROP POLICY IF EXISTS "Admins can update jobs" ON public.jobs;
DROP POLICY IF EXISTS "Admins can delete jobs" ON public.jobs;
DROP POLICY IF EXISTS "Drivers can view jobs" ON public.jobs;
DROP POLICY IF EXISTS "Drivers can update jobs" ON public.jobs;

-- Create comprehensive RLS policies for jobs table
CREATE POLICY "Users can view jobs"
    ON public.jobs FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users can insert jobs"
    ON public.jobs FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Users can update jobs"
    ON public.jobs FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Users can delete jobs"
    ON public.jobs FOR DELETE
    TO authenticated
    USING (true);

-- ==============================================
-- VERIFY JOBS TABLE ACCESS
-- ==============================================

-- Test if we can access jobs table
SELECT COUNT(*) as job_count FROM public.jobs;

-- Check if jobs_with_admin view is accessible
SELECT COUNT(*) as jobs_with_admin_count FROM public.jobs_with_admin;

-- ==============================================
-- CHECK RELATED TABLES
-- ==============================================

-- Check if all related tables have proper RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('jobs', 'users', 'profiles', 'user_status', 'chats', 'messages')
ORDER BY tablename;
