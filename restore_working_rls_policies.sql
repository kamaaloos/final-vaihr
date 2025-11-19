-- Restore the original working RLS policies
-- This restores the policies that were working before, with a fix for job assignment

-- ==============================================
-- STEP 1: CLEAN SLATE - DROP ALL EXISTING POLICIES
-- ==============================================

-- Disable RLS temporarily
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE jobs DISABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all profiles" ON users;
DROP POLICY IF EXISTS "Service role has full access to users" ON users;
DROP POLICY IF EXISTS "Admins can see all jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers see new jobs and their own jobs" ON jobs;
DROP POLICY IF EXISTS "Admins can create jobs" ON jobs;
DROP POLICY IF EXISTS "Admins can update jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers can accept new jobs" ON jobs;
DROP POLICY IF EXISTS "users_allow_all" ON users;
DROP POLICY IF EXISTS "jobs_allow_all" ON jobs;
DROP POLICY IF EXISTS "Allow all authenticated access to users" ON users;
DROP POLICY IF EXISTS "Allow all authenticated access to jobs" ON jobs;

-- ==============================================
-- STEP 2: RESTORE ORIGINAL WORKING POLICIES
-- ==============================================

-- Re-enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- USERS TABLE POLICIES (Original Working)
-- ==============================================

CREATE POLICY "Users can view their own profile"
    ON users FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow authenticated users to insert own profile"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
    ON users FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Service role has full access to users"
    ON users
    FOR ALL
    USING (true);

-- ==============================================
-- JOBS TABLE POLICIES (Original Working + Fix)
-- ==============================================

CREATE POLICY "Admins can see all jobs"
    ON jobs FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Drivers see new jobs and their own jobs"
    ON jobs FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'driver'
            AND (
                (jobs.status = 'open' AND jobs.driver_id IS NULL)
                OR jobs.driver_id = auth.uid()
            )
        )
    );

CREATE POLICY "Admins can create jobs"
    ON jobs FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can update jobs"
    ON jobs FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- FIXED: Drivers can accept jobs policy
CREATE POLICY "Drivers can accept jobs"
    ON jobs FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'driver'
        )
        AND (
            -- Allow drivers to accept open jobs
            (jobs.status = 'open' AND jobs.driver_id IS NULL)
            OR
            -- Allow drivers to update their own jobs
            jobs.driver_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'driver'
        )
        AND (
            -- Allow drivers to accept open jobs (FIXED: removed contradictory condition)
            (status = 'assigned' AND driver_id = auth.uid())
            OR
            -- Allow drivers to update their own jobs
            (driver_id = auth.uid() AND status IN ('in_progress', 'completed', 'cancelled'))
        )
    );

-- ==============================================
-- GRANT NECESSARY PERMISSIONS
-- ==============================================

GRANT SELECT, UPDATE, INSERT ON users TO authenticated;
GRANT SELECT, UPDATE, INSERT, DELETE ON jobs TO authenticated;

-- ==============================================
-- VERIFY THE SETUP
-- ==============================================

-- Check that policies are created
SELECT 
    'Policies created:' as info,
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd
FROM pg_policies 
WHERE tablename IN ('users', 'jobs')
ORDER BY tablename, policyname;

-- Check RLS status
SELECT 
    'RLS Status:' as info,
    schemaname, 
    tablename, 
    rowsecurity 
FROM pg_tables 
WHERE tablename IN ('users', 'jobs');
