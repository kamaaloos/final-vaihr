-- Test Notification System
-- Run this after applying the simple_notification_migration.sql

-- 1. Check if triggers exist
SELECT 
    trigger_name,
    event_manipulation,
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

-- 3. Test job status change notification
-- First, get a job to test with
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
        -- Update job status to trigger notification
        UPDATE jobs 
        SET status = 'completed' 
        WHERE id = test_job_id;
        
        RAISE NOTICE 'Test job status update completed for job ID: %', test_job_id;
    ELSE
        RAISE NOTICE 'No jobs found to test with';
    END IF;
END $$;

-- 4. Check if notification was created
SELECT 
    'job_status_notification' as test_type,
    COUNT(*) as count,
    'Job status notifications created' as description
FROM notifications
WHERE type = 'job_status'
AND created_at > NOW() - INTERVAL '5 minutes';

-- 5. Show recent notifications
SELECT 
    id,
    user_id,
    title,
    message,
    type,
    created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 5;

-- 6. Test the should_notify_driver function
SELECT 
    'should_notify_driver test' as test_name,
    should_notify_driver(NULL, 'Dublin', '25') as no_preferences,
    should_notify_driver('{"excludedLocations": ["Cork"]}'::jsonb, 'Dublin', '25') as different_location,
    should_notify_driver('{"excludedLocations": ["Dublin"]}'::jsonb, 'Dublin', '25') as excluded_location,
    should_notify_driver('{"minRate": "30"}'::jsonb, 'Dublin', '25') as low_rate,
    should_notify_driver('{"minRate": "20"}'::jsonb, 'Dublin', '25') as high_rate; 