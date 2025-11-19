-- Test if database assignment works manually
-- This will verify if the database operations work correctly

-- ==============================================
-- STEP 1: CHECK CURRENT JOBS
-- ==============================================

SELECT 
    'Current jobs:' as info,
    id,
    title,
    status,
    driver_id,
    admin_id
FROM jobs 
ORDER BY created_at DESC;

-- ==============================================
-- STEP 2: TEST MANUAL ASSIGNMENT
-- ==============================================

-- Try to assign an open job manually
UPDATE jobs 
SET 
    driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid,
    status = 'assigned',
    updated_at = NOW()
WHERE status = 'open' 
AND driver_id IS NULL;

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
-- STEP 3: CHECK ALL JOBS STATUS
-- ==============================================

SELECT 
    'All jobs status:' as info,
    status,
    COUNT(*) as count,
    COUNT(CASE WHEN driver_id IS NOT NULL THEN 1 END) as with_driver_id,
    COUNT(CASE WHEN driver_id IS NULL THEN 1 END) as with_null_driver_id
FROM jobs 
GROUP BY status
ORDER BY status;
