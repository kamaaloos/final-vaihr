-- Debug and fix job assignment issues
-- This will help us identify and fix the remaining problems

-- ==============================================
-- STEP 1: CHECK CURRENT STATE
-- ==============================================

-- Check current jobs and their status
SELECT 
    'Current jobs:' as info,
    id,
    title,
    status,
    driver_id,
    admin_id,
    created_at
FROM jobs 
ORDER BY created_at DESC 
LIMIT 10;

-- Check if there are any jobs with status 'assigned' but driver_id is NULL
SELECT 
    'Jobs with assigned status but NULL driver_id:' as info,
    id,
    title,
    status,
    driver_id,
    admin_id
FROM jobs 
WHERE status = 'assigned' 
AND driver_id IS NULL;

-- Check current RLS policies
SELECT 
    'Current policies:' as info,
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'jobs'
ORDER BY policyname;

-- ==============================================
-- STEP 2: CREATE VERY PERMISSIVE POLICIES FOR TESTING
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

-- Create very permissive policies for testing
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
-- STEP 3: TEST JOB ASSIGNMENT MANUALLY
-- ==============================================

-- Try to manually assign a job to test if the policies work
-- First, let's see what jobs exist
SELECT 
    'Available jobs for testing:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE status = 'open' 
AND driver_id IS NULL
LIMIT 3;

-- If there are jobs, let's try to assign one manually
-- (Uncomment and modify the job ID and driver ID as needed)
/*
UPDATE jobs 
SET 
    driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid,
    status = 'assigned',
    updated_at = NOW()
WHERE id = 'JOB_ID_HERE'::uuid;

-- Check if the assignment worked
SELECT 
    'After manual assignment:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;
*/

-- ==============================================
-- STEP 4: CHECK IF THE ISSUE IS WITH STATUS VALUES
-- ==============================================

-- Check what status values are actually being used
SELECT 
    'Status values in use:' as info,
    status,
    COUNT(*) as count
FROM jobs 
GROUP BY status
ORDER BY count DESC;

-- Check if there's a mismatch between 'open' vs 'new' status
SELECT 
    'Jobs with different statuses:' as info,
    status,
    driver_id,
    COUNT(*) as count
FROM jobs 
GROUP BY status, driver_id
ORDER BY status, driver_id;

-- ==============================================
-- STEP 5: CREATE A SIMPLE TEST
-- ==============================================

-- Create a test job to verify the assignment works
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
    'Test Job for Assignment',
    'This is a test job to verify assignment works',
    'Test Location',
    NOW() + INTERVAL '1 day',
    '50',
    '2 hours',
    'open',
    'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid,
    NOW(),
    NOW()
) ON CONFLICT DO NOTHING;

-- Check if the test job was created
SELECT 
    'Test job created:' as info,
    id,
    title,
    status,
    driver_id,
    admin_id
FROM jobs 
WHERE title = 'Test Job for Assignment';

-- ==============================================
-- STEP 6: VERIFY THE SETUP
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
WHERE tablename = 'jobs'
ORDER BY policyname;

-- Check RLS status
SELECT 
    'RLS Status:' as info,
    schemaname, 
    tablename, 
    rowsecurity 
FROM pg_tables 
WHERE tablename = 'jobs';
