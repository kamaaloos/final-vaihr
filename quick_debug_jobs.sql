-- Quick debug to check jobs table state
-- Run this to see what's happening with job assignment

-- Check current jobs
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
LIMIT 5;

-- Check for assigned jobs with NULL driver_id
SELECT 
    'Assigned jobs with NULL driver_id:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE status = 'assigned' 
AND driver_id IS NULL;

-- Check current RLS policies on jobs
SELECT 
    'Current jobs policies:' as info,
    policyname, 
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'jobs'
ORDER BY policyname;

-- Check what status values exist
SELECT 
    'Status values in use:' as info,
    status,
    COUNT(*) as count
FROM jobs 
GROUP BY status
ORDER BY count DESC;
