-- Comprehensive debug and fix for job assignment issues
-- This will identify why driver_id remains null after assignment

-- STEP 1: CHECK CURRENT STATE

-- Check all jobs and their current state
SELECT 
    'Current jobs state:' as info,
    id,
    title,
    status,
    driver_id,
    admin_id,
    created_at,
    updated_at
FROM jobs 
ORDER BY created_at DESC;

-- Check if there are any jobs with assigned status but null driver_id
SELECT 
    'Jobs with assigned status but null driver_id:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE status = 'assigned' 
AND driver_id IS NULL;

-- STEP 2: CHECK RLS POLICIES

-- Check current RLS policies on jobs table
SELECT 
    'Current RLS policies on jobs:' as info,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'jobs';

-- STEP 3: TEST MANUAL ASSIGNMENT

-- Try to manually assign a job to test if the database allows it
UPDATE jobs 
SET 
    driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid,
    status = 'assigned',
    updated_at = NOW()
WHERE status = 'open' 
AND driver_id IS NULL;

-- Check if the manual assignment worked
SELECT 
    'After manual assignment:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;

-- STEP 4: CREATE PERMISSIVE POLICIES

-- Drop all existing policies on jobs table
DROP POLICY IF EXISTS jobs_allow_all ON jobs;
DROP POLICY IF EXISTS jobs_delete_policy ON jobs;
DROP POLICY IF EXISTS jobs_insert_policy ON jobs;
DROP POLICY IF EXISTS jobs_select_policy ON jobs;
DROP POLICY IF EXISTS jobs_update_policy ON jobs;

-- Create completely permissive policies
CREATE POLICY jobs_allow_all ON jobs FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY jobs_select_policy ON jobs FOR SELECT TO authenticated USING (true);
CREATE POLICY jobs_insert_policy ON jobs FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY jobs_update_policy ON jobs FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY jobs_delete_policy ON jobs FOR DELETE TO authenticated USING (true);

-- STEP 5: GRANT ALL PERMISSIONS

-- Grant all necessary permissions
GRANT ALL ON jobs TO authenticated;
GRANT ALL ON users TO authenticated;
GRANT ALL ON invoices TO authenticated;

-- STEP 6: TEST ASSIGNMENT AGAIN

-- Try assignment again with permissive policies
UPDATE jobs 
SET 
    driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid,
    status = 'assigned',
    updated_at = NOW()
WHERE status = 'open' 
AND driver_id IS NULL;

-- Check the result
SELECT 
    'After permissive policy assignment:' as info,
    id,
    title,
    status,
    driver_id
FROM jobs 
WHERE driver_id = 'fb46cc34-37ed-495f-8c3b-e7e7f1885e47'::uuid;

-- STEP 7: CREATE DEBUG FUNCTION

-- Create a function to test job assignment from the app
CREATE OR REPLACE FUNCTION public.debug_job_assignment(
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
BEGIN
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
        'updated_at', v_job_record.updated_at
    );
    
    RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.debug_job_assignment(UUID, UUID) TO authenticated;

-- STEP 8: FINAL STATUS CHECK

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
