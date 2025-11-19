-- Create jobs_with_admin view (Fixed - No RLS on views)
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
-- GRANT PERMISSIONS
-- ==============================================

GRANT SELECT ON jobs_with_admin TO authenticated;

-- ==============================================
-- NOTE: Views inherit RLS from underlying tables
-- ==============================================

-- The view will automatically respect the RLS policies on the 'jobs' table
-- No need to set RLS on the view itself













