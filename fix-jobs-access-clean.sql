-- Fix jobs table access permissions
-- Run this in your Supabase SQL Editor

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













