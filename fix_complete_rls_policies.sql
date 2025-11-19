-- Complete fix for RLS policies that are preventing job assignment
-- This addresses both the jobs table and users table permission issues

-- ==============================================
-- FIX USERS TABLE POLICIES
-- ==============================================

-- Drop all existing users table policies
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON users;
DROP POLICY IF EXISTS "Allow authenticated users access" ON users;
DROP POLICY IF EXISTS "Admins can view all profiles" ON users;
DROP POLICY IF EXISTS "Service role has full access to users" ON users;
DROP POLICY IF EXISTS "Users can view own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;

-- Create permissive policies for users table
-- Allow authenticated users to read user data (needed for role checks)
CREATE POLICY "Allow authenticated users to read users"
    ON users FOR SELECT
    TO authenticated
    USING (true);

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Allow users to insert their own profile (for registration)
CREATE POLICY "Users can insert their own profile"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- ==============================================
-- FIX JOBS TABLE POLICIES
-- ==============================================

-- Drop existing jobs policies
DROP POLICY IF EXISTS "jobs_update_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_select_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_insert_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_delete_policy" ON jobs;
DROP POLICY IF EXISTS "Drivers can accept jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers can accept and update jobs" ON jobs;
DROP POLICY IF EXISTS "Admins can see all jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers see new jobs and their own jobs" ON jobs;
DROP POLICY IF EXISTS "Admins can create jobs" ON jobs;
DROP POLICY IF EXISTS "Admins can update jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers can accept new jobs" ON jobs;

-- Create comprehensive jobs policies

-- SELECT policy - allow users to see appropriate jobs
CREATE POLICY "jobs_select_policy" ON jobs
    FOR SELECT
    TO authenticated
    USING (
        -- Allow admins to see all jobs
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow drivers to see open jobs and their own jobs
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND raw_user_meta_data->>'role' = 'driver'
            AND (
                (jobs.status = 'open' AND jobs.driver_id IS NULL)
                OR jobs.driver_id = auth.uid()
            )
        )
        OR
        -- Allow users to see jobs they created
        admin_id = auth.uid()
    );

-- INSERT policy - allow admins and users to create jobs
CREATE POLICY "jobs_insert_policy" ON jobs
    FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Allow admins to create jobs
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow users to create jobs where they are the admin
        admin_id = auth.uid()
    );

-- UPDATE policy - FIXED to allow proper job assignment
CREATE POLICY "jobs_update_policy" ON jobs
    FOR UPDATE
    TO authenticated
    USING (
        -- Allow admins to update any job
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow users to update jobs where they are the admin
        admin_id = auth.uid()
        OR
        -- Allow drivers to update jobs they can access
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND raw_user_meta_data->>'role' = 'driver'
        )
        AND (
            -- Allow drivers to accept open jobs
            (jobs.status = 'open' AND jobs.driver_id IS NULL)
            OR
            -- Allow drivers to update their own jobs
            driver_id = auth.uid()
        )
    )
    WITH CHECK (
        -- Allow admins to update any job
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow users to update jobs where they are the admin
        admin_id = auth.uid()
        OR
        -- Allow drivers to update jobs (FIXED: removed contradictory conditions)
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND raw_user_meta_data->>'role' = 'driver'
        )
        AND (
            -- Allow drivers to accept open jobs
            (status = 'assigned' AND driver_id = auth.uid())
            OR
            -- Allow drivers to update their own jobs
            (driver_id = auth.uid() AND status IN ('in_progress', 'completed', 'cancelled'))
        )
    );

-- DELETE policy - allow admins and job creators to delete jobs
CREATE POLICY "jobs_delete_policy" ON jobs
    FOR DELETE
    TO authenticated
    USING (
        -- Allow admins to delete any job
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow users to delete jobs where they are the admin
        admin_id = auth.uid()
    );

-- ==============================================
-- ENSURE RLS IS ENABLED
-- ==============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- GRANT NECESSARY PERMISSIONS
-- ==============================================

-- Grant permissions to authenticated users
GRANT SELECT, UPDATE, INSERT ON users TO authenticated;
GRANT SELECT, UPDATE, INSERT, DELETE ON jobs TO authenticated;

-- ==============================================
-- VERIFY SETUP
-- ==============================================

-- Check that policies are created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename IN ('users', 'jobs')
ORDER BY tablename, policyname;
