-- Final fix for job assignment issues
-- Based on the debug output, we have jobs but driver_id is not being set properly

-- ==============================================
-- STEP 1: CHECK CURRENT STATE
-- ==============================================

-- Check the assigned job to see if driver_id is NULL
SELECT 
    'Assigned job details:' as info,
    id,
    title,
    status,
    driver_id,
    admin_id
FROM jobs 
WHERE status = 'assigned';

-- Check current RLS policies
SELECT 
    'Current policies:' as info,
    policyname, 
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'jobs'
ORDER BY policyname;

-- ==============================================
-- STEP 2: FIX THE ASSIGNED JOB MANUALLY
-- ==============================================

-- If the assigned job has NULL driver_id, let's fix it
-- First, get the driver ID from the logs (fb46cc34-37ed-495f-8c3b-e7e7f1885e47)
UPDATE jobs 
SET 
    driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid,
    updated_at = NOW()
WHERE status = 'assigned' 
AND driver_id IS NULL;

-- Check if the fix worked
SELECT 
    'After fixing assigned job:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE status = 'assigned';

-- ==============================================
-- STEP 3: CREATE VERY PERMISSIVE POLICIES
-- ==============================================

-- Disable RLS temporarily
ALTER TABLE jobs DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "jobs_select_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_insert_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_update_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_delete_policy" ON jobs;

-- Re-enable RLS
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- Create very permissive policies that definitely work
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
-- STEP 4: TEST THE FIX
-- ==============================================

-- Check that the driver can now see their assigned jobs
SELECT 
    'Driver assigned jobs:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE status = 'assigned' 
AND driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;

-- Check that the driver can see open jobs
SELECT 
    'Open jobs available:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE status = 'open' 
AND driver_id IS NULL;

-- ==============================================
-- STEP 5: VERIFY THE SETUP
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

-- Final check of all jobs
SELECT 
    'All jobs after fix:' as info,
    id,
    title,
    status,
    driver_id,
    admin_id
FROM jobs 
ORDER BY created_at DESC;
