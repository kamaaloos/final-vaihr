-- Test to manually assign a job to a driver
-- This will help us verify if the assignment works when done directly

-- First, let's see what jobs exist and their current state
SELECT 
    id, 
    title, 
    status, 
    driver_id, 
    admin_id,
    created_at
FROM jobs 
ORDER BY created_at DESC 
LIMIT 5;

-- Now let's manually assign a job to the driver
-- Replace 'JOB_ID_HERE' with an actual job ID from the query above
-- Replace '47a7f398-8803-4237-892c-ac2b4ed7ffa3' with the actual driver ID

-- UPDATE jobs 
-- SET 
--     driver_id = '47a7f398-8803-4237-892c-ac2b4ed7ffa3'::uuid,
--     status = 'assigned',
--     updated_at = NOW()
-- WHERE id = 'JOB_ID_HERE'::uuid;

-- Check if the update worked
-- SELECT id, title, status, driver_id FROM jobs WHERE id = 'JOB_ID_HERE'::uuid;

-- Check if the driver can now see their assigned jobs
-- SELECT 
--     id, 
--     title, 
--     status, 
--     driver_id 
-- FROM jobs 
-- WHERE status = 'assigned' 
-- AND driver_id = '47a7f398-8803-4237-892c-ac2b4ed7ffa3'::uuid;
