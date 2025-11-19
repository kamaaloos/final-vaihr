-- Fix the RLS policy that's preventing driver_id from being updated
-- The current policy has a logical contradiction in the WITH CHECK clause

-- Drop the problematic policy
DROP POLICY IF EXISTS "jobs_update_policy" ON jobs;
DROP POLICY IF EXISTS "Drivers can accept jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers can accept and update jobs" ON jobs;

-- Create a corrected policy for updating jobs
CREATE POLICY "jobs_update_policy" ON jobs
    FOR UPDATE
    TO authenticated
    USING (
        -- Allow admins to update any job
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow users to update jobs where they are the admin
        admin_id = auth.uid()
        OR
        -- Allow drivers to update jobs they are assigned to
        (
            EXISTS (
                SELECT 1 FROM auth.users
                WHERE auth.users.id = auth.uid()
                AND raw_user_meta_data->>'role' = 'driver'
            )
            AND (
                -- Allow drivers to accept open jobs
                (jobs.status = 'open' AND jobs.driver_id IS NULL)
                OR
                -- Allow drivers to update their own jobs
                driver_id = auth.uid()
            )
        )
    )
    WITH CHECK (
        -- Allow admins to update any job
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow users to update jobs where they are the admin
        admin_id = auth.uid()
        OR
        -- Allow drivers to update jobs
        (
            EXISTS (
                SELECT 1 FROM auth.users
                WHERE auth.users.id = auth.uid()
                AND raw_user_meta_data->>'role' = 'driver'
            )
            AND (
                -- Allow drivers to accept open jobs (FIXED: removed contradictory condition)
                (status = 'assigned' AND driver_id = auth.uid())
                OR
                -- Allow drivers to update their own jobs with valid status transitions
                (
                    driver_id = auth.uid()
                    AND (
                        -- Allow status transitions for driver's own jobs
                        (status = 'in_progress')
                        OR
                        (status = 'completed')
                        OR
                        (status = 'cancelled')
                    )
                )
            )
        )
    );

-- Ensure RLS is enabled
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
