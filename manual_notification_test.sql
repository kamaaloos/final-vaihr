-- Manual Notification Test
-- This script manually tests the notification system

-- 1. First, let's see what jobs we have
SELECT 
    id,
    title,
    status,
    admin_id,
    driver_id,
    created_at,
    updated_at
FROM jobs
ORDER BY created_at DESC
LIMIT 5;

-- 2. Check if we have any admin users with push tokens
SELECT 
    id,
    name,
    email,
    expo_push_token,
    role
FROM users
WHERE role = 'admin'
LIMIT 3;

-- 3. Manually update a job status to trigger notification
DO $$
DECLARE
    test_job_id UUID;
    test_admin_id UUID;
    old_status TEXT;
    new_status TEXT;
BEGIN
    -- Get a job that's not completed
    SELECT id, admin_id, status INTO test_job_id, test_admin_id, old_status
    FROM jobs
    WHERE status != 'completed'
    LIMIT 1;
    
    IF test_job_id IS NOT NULL THEN
        new_status := 'completed';
        
        RAISE NOTICE 'Testing notification with:';
        RAISE NOTICE 'Job ID: %', test_job_id;
        RAISE NOTICE 'Admin ID: %', test_admin_id;
        RAISE NOTICE 'Old status: %', old_status;
        RAISE NOTICE 'New status: %', new_status;
        
        -- Update the job status
        UPDATE jobs 
        SET status = new_status,
            updated_at = NOW()
        WHERE id = test_job_id;
        
        RAISE NOTICE 'Job status updated successfully';
        
        -- Check if notification was created
        IF EXISTS (
            SELECT 1 FROM notifications 
            WHERE type = 'job_status' 
            AND created_at > NOW() - INTERVAL '1 minute'
        ) THEN
            RAISE NOTICE 'SUCCESS: Notification was created!';
        ELSE
            RAISE NOTICE 'FAILURE: No notification was created';
        END IF;
        
    ELSE
        RAISE NOTICE 'No jobs found to test with';
    END IF;
END $$;

-- 4. Show recent notifications
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

-- 5. Check if the trigger function exists and can be called
SELECT 
    routine_name,
    routine_type,
    'Function exists' as status
FROM information_schema.routines 
WHERE routine_name = 'notify_admin_on_job_status_change';

-- 6. Test the trigger function directly (this will show any errors)
DO $$
BEGIN
    RAISE NOTICE 'Testing trigger function directly...';
    -- This will fail because we don't have OLD and NEW variables, but it will show if the function exists
    PERFORM notify_admin_on_job_status_change();
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Function test completed with expected error: %', SQLERRM;
END $$; 