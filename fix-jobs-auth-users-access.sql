-- Fix jobs table access to auth.users
-- Run this in your Supabase SQL Editor

-- ==============================================
-- CHECK CURRENT JOBS TABLE STRUCTURE
-- ==============================================

-- Check foreign key constraints on jobs table
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

-- Check if jobs_with_admin view exists and its structure
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'jobs_with_admin' 
AND table_schema = 'public';

-- ==============================================
-- FIX JOBS TABLE FOREIGN KEY RELATIONSHIPS
-- ==============================================

-- Drop existing foreign key constraints that reference auth.users
ALTER TABLE public.jobs DROP CONSTRAINT IF EXISTS jobs_admin_id_fkey;
ALTER TABLE public.jobs DROP CONSTRAINT IF EXISTS jobs_driver_id_fkey;
ALTER TABLE public.jobs DROP CONSTRAINT IF EXISTS fk_jobs_admin;
ALTER TABLE public.jobs DROP CONSTRAINT IF EXISTS fk_jobs_driver;

-- Add foreign key constraints that reference public.users instead
ALTER TABLE public.jobs 
ADD CONSTRAINT jobs_admin_id_fkey 
FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE public.jobs 
ADD CONSTRAINT jobs_driver_id_fkey 
FOREIGN KEY (driver_id) REFERENCES public.users(id) ON DELETE SET NULL;

-- ==============================================
-- RECREATE JOBS_WITH_ADMIN VIEW
-- ==============================================

-- Drop existing view
DROP VIEW IF EXISTS public.jobs_with_admin;

-- Create new view that references public.users
CREATE VIEW public.jobs_with_admin AS
SELECT 
    j.*,
    u.email as admin_email,
    u.name as admin_name,
    u.avatar_url as admin_avatar_url
FROM public.jobs j
LEFT JOIN public.users u ON j.admin_id = u.id;

-- Grant access to the view
GRANT SELECT ON public.jobs_with_admin TO authenticated;

-- ==============================================
-- FIX JOBS TABLE RLS POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins can see all jobs" ON public.jobs;
DROP POLICY IF EXISTS "Drivers see new jobs and their own jobs" ON public.jobs;
DROP POLICY IF EXISTS "Admins can create jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can view jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can insert jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can update jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can delete jobs" ON public.jobs;

-- Create permissive policies for jobs table
CREATE POLICY "jobs_select_policy"
    ON public.jobs FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "jobs_insert_policy"
    ON public.jobs FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "jobs_update_policy"
    ON public.jobs FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "jobs_delete_policy"
    ON public.jobs FOR DELETE
    TO authenticated
    USING (true);

-- ==============================================
-- TEST ACCESS
-- ==============================================

-- Test jobs table access
SELECT COUNT(*) as job_count FROM public.jobs;

-- Test jobs_with_admin view access
SELECT COUNT(*) as jobs_with_admin_count FROM public.jobs_with_admin;

-- Test if we can access users through jobs
SELECT j.id, j.title, u.name as admin_name 
FROM public.jobs j 
LEFT JOIN public.users u ON j.admin_id = u.id 
LIMIT 5;













