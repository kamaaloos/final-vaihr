-- Test script to manually update a job and see if driver_id gets set
-- This will help us determine if the issue is with the update operation itself

-- First, let's see what jobs exist
SELECT id, title, status, driver_id, admin_id FROM jobs LIMIT 5;

-- Try to manually update a job (replace 'JOB_ID_HERE' with an actual job ID)
-- UPDATE jobs 
-- SET 
--     driver_id = '47a7f398-8803-4237-892c-ac2b4ed7ffa3'::uuid,
--     status = 'assigned',
--     updated_at = NOW()
-- WHERE id = 'JOB_ID_HERE'::uuid;

-- Check if the update worked
-- SELECT id, title, status, driver_id FROM jobs WHERE id = 'JOB_ID_HERE'::uuid;
