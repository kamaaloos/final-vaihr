-- Complete fix for all database issues
-- This addresses RLS policies, missing functions, and permissions

-- ==============================================
-- STEP 1: CREATE MISSING RPC FUNCTIONS
-- ==============================================

-- Create the missing upsert_user_status function
CREATE OR REPLACE FUNCTION public.upsert_user_status(
    p_is_online BOOLEAN,
    p_platform TEXT DEFAULT NULL,
    p_platform_version TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the user ID from the auth context
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Update the user_status table
    INSERT INTO user_status (
        user_id,
        is_online,
        platform,
        last_seen,
        updated_at
    ) VALUES (
        v_user_id,
        p_is_online,
        p_platform,
        NOW(),
        NOW()
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        is_online = EXCLUDED.is_online,
        platform = EXCLUDED.platform,
        last_seen = EXCLUDED.last_seen,
        updated_at = EXCLUDED.updated_at;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in upsert_user_status: %', SQLERRM;
        RAISE;
END;
$$;

-- Create the compatibility function
CREATE OR REPLACE FUNCTION public.upsert_user_status_compat(
    p_online BOOLEAN,
    p_platform TEXT DEFAULT NULL,
    p_platform_version TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the user ID from the auth context
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Update the user_status table
    INSERT INTO user_status (
        user_id,
        is_online,
        platform,
        last_seen,
        updated_at
    ) VALUES (
        v_user_id,
        p_online,
        p_platform,
        NOW(),
        NOW()
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        is_online = EXCLUDED.is_online,
        platform = EXCLUDED.platform,
        last_seen = EXCLUDED.last_seen,
        updated_at = EXCLUDED.updated_at;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in upsert_user_status_compat: %', SQLERRM;
        RAISE;
END;
$$;

-- Grant execute permissions on RPC functions
GRANT EXECUTE ON FUNCTION public.upsert_user_status TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_user_status_compat TO authenticated;

-- ==============================================
-- STEP 2: FIX USERS TABLE POLICIES
-- ==============================================

-- Disable RLS temporarily
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Drop all existing users policies
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all profiles" ON users;
DROP POLICY IF EXISTS "Service role has full access to users" ON users;
DROP POLICY IF EXISTS "users_all_access" ON users;
DROP POLICY IF EXISTS "jobs_all_access" ON jobs;
DROP POLICY IF EXISTS "Allow all authenticated access to users" ON users;
DROP POLICY IF EXISTS "Allow all authenticated access to jobs" ON jobs;

-- Re-enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create permissive users policies
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
-- STEP 3: FIX JOBS TABLE POLICIES
-- ==============================================

-- Disable RLS temporarily
ALTER TABLE jobs DISABLE ROW LEVEL SECURITY;

-- Drop all existing jobs policies
DROP POLICY IF EXISTS "Drivers can accept jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers can complete their jobs" ON jobs;
DROP POLICY IF EXISTS "jobs_delete_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_insert_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_select_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_update_policy" ON jobs;

-- Re-enable RLS
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- Create working jobs policies
CREATE POLICY "jobs_select_policy"
    ON jobs FOR SELECT
    TO authenticated
    USING (
        -- Allow admins to see all jobs
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow drivers to see open jobs and their own jobs
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'driver'
            AND (
                (jobs.status = 'open' AND jobs.driver_id IS NULL)
                OR jobs.driver_id = auth.uid()
            )
        )
        OR
        -- Allow users to see jobs they created
        admin_id = auth.uid()
    );

CREATE POLICY "jobs_insert_policy"
    ON jobs FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Allow admins to create jobs
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow users to create jobs where they are the admin
        admin_id = auth.uid()
    );

CREATE POLICY "jobs_update_policy"
    ON jobs FOR UPDATE
    TO authenticated
    USING (
        -- Allow admins to update any job
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow users to update jobs where they are the admin
        admin_id = auth.uid()
        OR
        -- Allow drivers to update jobs they can access
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
            driver_id = auth.uid()
        )
    )
    WITH CHECK (
        -- Allow admins to update any job
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow users to update jobs where they are the admin
        admin_id = auth.uid()
        OR
        -- Allow drivers to update jobs (FIXED: removed contradictory conditions)
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'driver'
        )
        AND (
            -- Allow drivers to accept open jobs
            (status = 'assigned' AND driver_id = auth.uid())
            OR
            -- Allow drivers to update their own jobs
            (driver_id = auth.uid() AND status IN ('in_progress', 'completed', 'cancelled'))
        )
    );

CREATE POLICY "jobs_delete_policy"
    ON jobs FOR DELETE
    TO authenticated
    USING (
        -- Allow admins to delete any job
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow users to delete jobs where they are the admin
        admin_id = auth.uid()
    );

-- ==============================================
-- STEP 4: GRANT ALL NECESSARY PERMISSIONS
-- ==============================================

-- Grant permissions to authenticated users
GRANT ALL ON users TO authenticated;
GRANT ALL ON jobs TO authenticated;
GRANT ALL ON user_status TO authenticated;

-- ==============================================
-- STEP 5: VERIFY THE SETUP
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
WHERE tablename IN ('users', 'jobs', 'user_status')
ORDER BY tablename, policyname;

-- Check RLS status
SELECT 
    'RLS Status:' as info,
    schemaname, 
    tablename, 
    rowsecurity 
FROM pg_tables 
WHERE tablename IN ('users', 'jobs', 'user_status');

-- Check that functions are created
SELECT 
    'Functions created:' as info,
    routine_name, 
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%upsert_user_status%';
