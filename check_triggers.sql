-- Check if notification triggers exist and are working
-- Run this to debug why notifications aren't being created

-- 1. Check if triggers exist
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    'Trigger exists' as status
FROM information_schema.triggers 
WHERE trigger_name LIKE '%notification%'
ORDER BY trigger_name;

-- 2. Check if functions exist
SELECT 
    routine_name,
    routine_type,
    'Function exists' as status
FROM information_schema.routines 
WHERE routine_name LIKE '%notification%'
ORDER BY routine_name;

-- 3. Check recent job updates to see if triggers should have fired
SELECT 
    id,
    title,
    status,
    admin_id,
    driver_id,
    created_at,
    updated_at
FROM jobs
WHERE updated_at > NOW() - INTERVAL '1 hour'
ORDER BY updated_at DESC
LIMIT 10;

-- 4. Check if there are any jobs that changed status recently
SELECT 
    'recent_job_changes' as check_type,
    COUNT(*) as count,
    'Jobs updated in last hour' as description
FROM jobs
WHERE updated_at > NOW() - INTERVAL '1 hour'
UNION ALL
SELECT 
    'completed_jobs' as check_type,
    COUNT(*) as count,
    'Jobs with completed status' as description
FROM jobs
WHERE status = 'completed';

-- 5. Check if users table has the required columns
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('is_online', 'expo_push_token', 'role', 'name', 'avatar_url')
ORDER BY column_name;

-- 6. Check if admin users have push tokens
SELECT 
    id,
    name,
    email,
    expo_push_token,
    is_online
FROM users
WHERE role = 'admin'
LIMIT 5;

-- 7. Test manual trigger execution
-- This will help us see if the trigger function works
DO $$
DECLARE
    test_job_id UUID;
    test_admin_id UUID;
BEGIN
    -- Get a job to test with
    SELECT id, admin_id INTO test_job_id, test_admin_id
    FROM jobs
    WHERE status != 'completed'
    LIMIT 1;
    
    IF test_job_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with job ID: % and admin ID: %', test_job_id, test_admin_id;
        
        -- Manually call the trigger function
        PERFORM notify_admin_on_job_status_change();
        
        RAISE NOTICE 'Manual trigger function call completed';
    ELSE
        RAISE NOTICE 'No jobs found to test with';
    END IF;
END $$;

-- 8. Check for any recent database errors or notices
SELECT 
    'No recent errors found' as status
WHERE NOT EXISTS (
    SELECT 1 FROM pg_stat_activity 
    WHERE query LIKE '%Error%' 
    AND query_start > NOW() - INTERVAL '1 hour'
); 