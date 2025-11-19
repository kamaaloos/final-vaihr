-- Comprehensive Notification Debug Script
-- This script will help identify why notifications aren't being created

-- 1. Check if triggers exist and are enabled
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    'Trigger exists' as status
FROM information_schema.triggers 
WHERE trigger_name LIKE '%notification%'
ORDER BY trigger_name;

-- 2. Check if functions exist and are valid
SELECT 
    routine_name,
    routine_type,
    routine_definition IS NOT NULL as has_definition,
    'Function exists' as status
FROM information_schema.routines 
WHERE routine_name LIKE '%notification%'
ORDER BY routine_name;

-- 3. Check notifications table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'notifications'
ORDER BY ordinal_position;

-- 4. Check if there are any notifications at all
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
WHERE type = 'job_status'
UNION ALL
SELECT 
    'recent_notifications' as check_type,
    COUNT(*) as count,
    'Notifications created in last hour' as description
FROM notifications
WHERE created_at > NOW() - INTERVAL '1 hour';

-- 5. Check admin users and their push tokens
SELECT 
    id,
    name,
    email,
    expo_push_token IS NOT NULL as has_push_token,
    expo_push_token,
    is_online,
    role
FROM users
WHERE role = 'admin'
ORDER BY name;

-- 6. Check recent job status changes
SELECT 
    id,
    title,
    status,
    admin_id,
    driver_id,
    created_at,
    updated_at,
    EXTRACT(EPOCH FROM (updated_at - created_at))/3600 as hours_since_update
FROM jobs
WHERE updated_at > NOW() - INTERVAL '24 hours'
ORDER BY updated_at DESC
LIMIT 10;

-- 7. Test the trigger manually with a specific job
DO $$
DECLARE
    test_job_id UUID;
    test_admin_id UUID;
    old_status TEXT;
    notification_count_before INTEGER;
    notification_count_after INTEGER;
    trigger_exists BOOLEAN;
BEGIN
    -- Check if trigger exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'job_status_notification_trigger'
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        RAISE NOTICE 'ERROR: job_status_notification_trigger does not exist!';
        RETURN;
    END IF;
    
    -- Get current notification count
    SELECT COUNT(*) INTO notification_count_before FROM notifications;
    
    -- Get a job that's not completed and has an admin
    SELECT id, admin_id, status INTO test_job_id, test_admin_id, old_status
    FROM jobs
    WHERE status != 'completed' 
    AND admin_id IS NOT NULL
    LIMIT 1;
    
    IF test_job_id IS NULL THEN
        RAISE NOTICE 'No suitable jobs found for testing';
        RETURN;
    END IF;
    
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
        
        -- Show the created notification
        SELECT 
            id,
            user_id,
            title,
            message,
            type,
            created_at
        FROM notifications
        WHERE created_at > NOW() - INTERVAL '2 minutes'
        ORDER BY created_at DESC
        LIMIT 1;
    ELSE
        RAISE NOTICE 'FAILURE: No notification was created';
        
        -- Check if admin has push token
        SELECT 
            expo_push_token IS NOT NULL as has_token,
            expo_push_token
        FROM users
        WHERE id = test_admin_id;
    END IF;
END $$;

-- 8. Check for any errors in the function
SELECT 
    'function_errors' as check_type,
    COUNT(*) as count,
    'Functions with errors' as description
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname LIKE '%notification%'
AND p.prosrc IS NULL;

-- 9. Show recent notifications with details
SELECT 
    id,
    user_id,
    title,
    message,
    type,
    data,
    push_token IS NOT NULL as has_push_token,
    created_at
FROM notifications
ORDER BY created_at DESC
LIMIT 10; 