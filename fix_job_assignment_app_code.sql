-- Fix job assignment by ensuring we use the correct user ID
-- This addresses the issue where driver_id remains null after assignment

-- ==============================================
-- STEP 1: CHECK CURRENT USER DATA
-- ==============================================

-- Check what user data looks like in the users table
SELECT 
    'Current user data:' as info,
    id,
    email,
    role,
    name,
    created_at
FROM users 
WHERE id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;

-- ==============================================
-- STEP 2: CHECK AUTH USERS
-- ==============================================

-- Check what auth user data looks like
SELECT 
    'Auth user data:' as info,
    id,
    email,
    created_at
FROM auth.users 
WHERE id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;

-- ==============================================
-- STEP 3: TEST MANUAL ASSIGNMENT WITH CORRECT ID
-- ==============================================

-- Try to assign a job using the correct user ID
UPDATE jobs 
SET 
    driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid,
    status = 'assigned',
    updated_at = NOW()
WHERE status = 'open' 
AND driver_id IS NULL;

-- Check if the assignment worked
SELECT 
    'After manual assignment with correct ID:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;

-- ==============================================
-- STEP 4: CREATE DEBUG FUNCTION FOR APP
-- ==============================================

-- Create a function to test job assignment from the app
CREATE OR REPLACE FUNCTION public.test_job_assignment(
    p_job_id UUID,
    p_driver_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
    v_job_record RECORD;
    v_user_record RECORD;
BEGIN
    -- Check if the user exists
    SELECT * INTO v_user_record
    FROM users 
    WHERE id = p_driver_id;
    
    IF v_user_record IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User not found',
            'driver_id', p_driver_id
        );
    END IF;
    
    -- Get the current job record
    SELECT * INTO v_job_record
    FROM jobs 
    WHERE id = p_job_id;
    
    -- Try to update the job
    UPDATE jobs 
    SET 
        driver_id = p_driver_id,
        status = 'assigned',
        updated_at = NOW()
    WHERE id = p_job_id;
    
    -- Get the updated record
    SELECT * INTO v_job_record
    FROM jobs 
    WHERE id = p_job_id;
    
    -- Return the result
    v_result := json_build_object(
        'success', FOUND,
        'job_id', p_job_id,
        'driver_id', p_driver_id,
        'updated_driver_id', v_job_record.driver_id,
        'updated_status', v_job_record.status,
        'updated_at', v_job_record.updated_at,
        'user_exists', v_user_record IS NOT NULL,
        'user_role', v_user_record.role
    );
    
    RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.test_job_assignment(UUID, UUID) TO authenticated;

-- ==============================================
-- STEP 5: TEST THE FUNCTION
-- ==============================================

-- Test the function with a real job ID
-- SELECT public.test_job_assignment(
--     'your-job-id-here'::uuid,
--     'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid
-- );

-- ==============================================
-- STEP 6: FINAL STATUS CHECK
-- ==============================================

-- Check all jobs one final time
SELECT 
    'Final jobs status:' as info,
    status,
    COUNT(*) as count,
    COUNT(CASE WHEN driver_id IS NOT NULL THEN 1 END) as with_driver_id,
    COUNT(CASE WHEN driver_id IS NULL THEN 1 END) as with_null_driver_id
FROM jobs 
GROUP BY status
ORDER BY status;
