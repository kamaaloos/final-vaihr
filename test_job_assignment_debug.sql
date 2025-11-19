-- Test job assignment to debug the issue
-- This will help us see what's happening when jobs are assigned

-- ==============================================
-- STEP 1: CHECK CURRENT STATE
-- ==============================================

-- Check all jobs and their current state
SELECT 
    'Current jobs state:' as info,
    id,
    title,
    status,
    driver_id,
    admin_id,
    created_at
FROM jobs 
ORDER BY created_at DESC;

-- ==============================================
-- STEP 2: TEST MANUAL JOB ASSIGNMENT
-- ==============================================

-- Try to assign an open job to the driver
-- First, let's see what open jobs exist
SELECT 
    'Open jobs available:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE status = 'open' 
AND driver_id IS NULL;

-- Now let's try to assign one of the open jobs
-- (Replace the job ID with an actual open job ID from above)
UPDATE jobs 
SET 
    driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid,
    status = 'assigned',
    updated_at = NOW()
WHERE id = (
    SELECT id FROM jobs 
    WHERE status = 'open' 
    AND driver_id IS NULL 
    LIMIT 1
);

-- Check if the assignment worked
SELECT 
    'After manual assignment:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;

-- ==============================================
-- STEP 3: CHECK RLS POLICIES
-- ==============================================

-- Check what policies are currently active
SELECT 
    'Current RLS policies:' as info,
    policyname, 
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'jobs'
ORDER BY policyname;

-- ==============================================
-- STEP 4: TEST IF THE ISSUE IS WITH USER ID FORMAT
-- ==============================================

-- Check if there's a mismatch between user ID formats
-- The app might be using different ID formats
SELECT 
    'Testing different ID formats:' as info,
    'UUID format' as format,
    'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid as test_uuid;

-- Check if the issue is with the user ID comparison
SELECT 
    'User ID comparison test:' as info,
    CASE 
        WHEN 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid 
        THEN 'UUID comparison works'
        ELSE 'UUID comparison failed'
    END as result;

-- ==============================================
-- STEP 5: CREATE A SIMPLE TEST
-- ==============================================

-- Create a test job and try to assign it
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
    'Debug Test Job',
    'This is a test job for debugging assignment',
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
WHERE title = 'Debug Test Job';

-- Check if the test assignment worked
SELECT 
    'Test job assignment result:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE title = 'Debug Test Job';
