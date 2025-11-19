-- Debug Notification Triggers
-- This script checks why notifications aren't being created

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

-- 3. Check notifications table structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'notifications'
ORDER BY ordinal_position;

-- 4. Check users table structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('is_online', 'expo_push_token', 'role', 'name', 'avatar_url')
ORDER BY column_name;

-- 5. Check if admin users exist and have push tokens
SELECT 
    id,
    name,
    email,
    expo_push_token,
    is_online,
    role
FROM users
WHERE role = 'admin'
LIMIT 5;

-- 6. Check recent jobs
SELECT 
    id,
    title,
    status,
    admin_id,
    driver_id,
    created_at,
    updated_at
FROM jobs
ORDER BY updated_at DESC
LIMIT 5;

-- 7. Check if there are any completed jobs
SELECT 
    'completed_jobs' as check_type,
    COUNT(*) as count,
    'Jobs with completed status' as description
FROM jobs
WHERE status = 'completed'
UNION ALL
SELECT 
    'recent_updates' as check_type,
    COUNT(*) as count,
    'Jobs updated in last hour' as description
FROM jobs
WHERE updated_at > NOW() - INTERVAL '1 hour';

-- 8. Check current notification count
SELECT 
    'total_notifications' as check_type,
    COUNT(*) as count,
    'Total notifications in table' as description
FROM notifications
UNION ALL
SELECT 
    'job_status_notifications' as check_type,
    COUNT(*) as count,
    'Job status notifications' as description
FROM notifications
WHERE type = 'job_status';

-- 9. Test manual job update to trigger notification
DO $$
DECLARE
    test_job_id UUID;
    test_admin_id UUID;
    old_status TEXT;
    notification_count_before INTEGER;
    notification_count_after INTEGER;
BEGIN
    -- Get current notification count
    SELECT COUNT(*) INTO notification_count_before FROM notifications;
    
    -- Get a job that's not completed
    SELECT id, admin_id, status INTO test_job_id, test_admin_id, old_status
    FROM jobs
    WHERE status != 'completed'
    LIMIT 1;
    
    IF test_job_id IS NOT NULL THEN
        RAISE NOTICE 'Testing notification trigger with:';
        RAISE NOTICE 'Job ID: %', test_job_id;
        RAISE NOTICE 'Admin ID: %', test_admin_id;
        RAISE NOTICE 'Old status: %', old_status;
        RAISE NOTICE 'Notifications before: %', notification_count_before;
        
        -- Update the job status (this should trigger the notification)
        UPDATE jobs 
        SET status = 'completed',
            updated_at = NOW()
        WHERE id = test_job_id;
        
        -- Wait a moment for the trigger to execute
        PERFORM pg_sleep(1);
        
        -- Get notification count after update
        SELECT COUNT(*) INTO notification_count_after FROM notifications;
        
        RAISE NOTICE 'Notifications after: %', notification_count_after;
        
        IF notification_count_after > notification_count_before THEN
            RAISE NOTICE 'SUCCESS: Notification was created!';
        ELSE
            RAISE NOTICE 'FAILURE: No notification was created';
            
            -- Check if admin has push token
            IF NOT EXISTS (
                SELECT 1 FROM users 
                WHERE id = test_admin_id
                AND expo_push_token IS NOT NULL
            ) THEN
                RAISE NOTICE 'POSSIBLE CAUSE: Admin user has no push token';
            END IF;
            
            -- Check if trigger exists for jobs table
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.triggers 
                WHERE trigger_name = 'job_status_notification_trigger'
                AND event_object_table = 'jobs'
            ) THEN
                RAISE NOTICE 'POSSIBLE CAUSE: Trigger does not exist';
            END IF;
        END IF;
        
    ELSE
        RAISE NOTICE 'No jobs found to test with';
    END IF;
END $$;

-- 10. Show recent notifications
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

-- 11. Check if there are any recent database errors
SELECT 
    'No recent errors found' as status
WHERE NOT EXISTS (
    SELECT 1 FROM pg_stat_activity 
    WHERE query LIKE '%Error%' 
    AND query_start > NOW() - INTERVAL '1 hour'
); 