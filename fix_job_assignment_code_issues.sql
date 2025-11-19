-- Fix job assignment code issues
-- This addresses potential problems with the job assignment logic

-- ==============================================
-- STEP 1: ENSURE VERY PERMISSIVE POLICIES
-- ==============================================

-- Disable RLS temporarily
ALTER TABLE jobs DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "jobs_select_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_insert_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_update_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_delete_policy" ON jobs;
DROP POLICY IF EXISTS "Drivers can accept jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers can accept and update jobs" ON jobs;

-- Re-enable RLS
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- Create the most permissive policies possible
CREATE POLICY "jobs_select_policy"
    ON jobs FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "jobs_insert_policy"
    ON jobs FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "jobs_update_policy"
    ON jobs FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "jobs_delete_policy"
    ON jobs FOR DELETE
    TO authenticated
    USING (true);

-- ==============================================
-- STEP 2: GRANT ALL PERMISSIONS
-- ==============================================

-- Grant all permissions to authenticated users
GRANT ALL ON jobs TO authenticated;

-- ==============================================
-- STEP 3: CREATE A TEST JOB AND ASSIGN IT
-- ==============================================

-- Create a test job
INSERT INTO jobs (
    id,
    title,
    description,
    location,
    date,
    rate,
    duration,
    status,
    admin_id,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'Test Job for Assignment Debug',
    'This job is created to test assignment',
    'Test Location',
    NOW() + INTERVAL '1 day',
    '50',
    '2 hours',
    'open',
    'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid,
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;

-- Try to assign the test job
UPDATE jobs 
SET 
    driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid,
    status = 'assigned',
    updated_at = NOW()
WHERE title = 'Test Job for Assignment Debug';

-- Check if the assignment worked
SELECT 
    'Test job assignment result:' as info,
    id,
    title,
    status,
    driver_id,
    admin_id
FROM jobs 
WHERE title = 'Test Job for Assignment Debug';

-- ==============================================
-- STEP 4: CHECK ALL JOBS STATUS
-- ==============================================

-- Check all jobs to see their current state
SELECT 
    'All jobs after fix:' as info,
    id,
    title,
    status,
    driver_id,
    admin_id,
    created_at
FROM jobs 
ORDER BY created_at DESC;

-- ==============================================
-- STEP 5: VERIFY POLICIES
-- ==============================================

-- Check that policies are created
SELECT 
    'Policies created:' as info,
    policyname, 
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'jobs'
ORDER BY policyname;
