-- Create jobs_with_admin view
-- Run this in your Supabase SQL Editor

-- ==============================================
-- DROP EXISTING VIEW IF EXISTS
-- ==============================================

DROP VIEW IF EXISTS jobs_with_admin CASCADE;

-- ==============================================
-- CREATE JOBS_WITH_ADMIN VIEW
-- ==============================================

CREATE OR REPLACE VIEW jobs_with_admin AS
SELECT 
    j.id::uuid,
    j.title,
    j.description,
    j.location,
    j.date,
    j.duration,
    j.rate,
    j.status,
    j.driver_id::uuid,
    j.admin_id::uuid,
    j.driver_name,
    j.image_url,
    j.created_at,
    j.updated_at,
    auth_users.email::text as admin_email,
    COALESCE(auth_users.raw_user_meta_data->>'name', auth_users.email)::text as admin_name,
    COALESCE(auth_users.raw_user_meta_data->>'avatar_url', '')::text as admin_avatar_url
FROM 
    public.jobs j
LEFT JOIN 
    auth.users auth_users ON j.admin_id::uuid = auth_users.id;

-- ==============================================
-- ENABLE RLS ON VIEW
-- ==============================================

ALTER VIEW jobs_with_admin ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- CREATE RLS POLICIES FOR VIEW
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view jobs with admin info" ON jobs_with_admin;

-- Create policy for the view
CREATE POLICY "Users can view jobs with admin info"
    ON jobs_with_admin FOR SELECT
    TO authenticated
    USING (
        -- Allow admins to see all jobs
        EXISTS (
            SELECT 1 FROM auth.users au
            WHERE au.id = auth.uid()
            AND au.raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow drivers to see new jobs and their own jobs
        (
            EXISTS (
                SELECT 1 FROM auth.users au
                WHERE au.id = auth.uid()
                AND au.raw_user_meta_data->>'role' = 'driver'
                AND (
                    (jobs_with_admin.status = 'new' AND jobs_with_admin.driver_id IS NULL)
                    OR jobs_with_admin.driver_id = auth.uid()
                )
            )
        )
    );

-- ==============================================
-- GRANT PERMISSIONS
-- ==============================================

GRANT SELECT ON jobs_with_admin TO authenticated;













