-- Fix RLS policies with proper type casting
-- Run this in your Supabase SQL Editor

-- ==============================================
-- DROP PROBLEMATIC POLICIES
-- ==============================================

-- Drop policies that have type casting issues
DROP POLICY IF EXISTS "Users can view their own settings" ON settings;
DROP POLICY IF EXISTS "Drivers and admins can view terms" ON terms;
DROP POLICY IF EXISTS "Only admins can delete terms" ON terms;
DROP POLICY IF EXISTS "Only admins can insert terms" ON terms;
DROP POLICY IF EXISTS "Only admins can update terms" ON terms;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;

-- ==============================================
-- CREATE FIXED POLICIES WITH PROPER TYPE CASTING
-- ==============================================

-- Settings table - fix text = uuid issue
CREATE POLICY "Users can view their own settings"
    ON settings FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id::uuid);

-- Terms table - fix text = uuid issues
CREATE POLICY "Drivers and admins can view terms"
    ON terms FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id::uuid = auth.uid()
            AND (users.role = 'driver' OR users.role = 'admin')
        )
    );

CREATE POLICY "Only admins can delete terms"
    ON terms FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id::uuid = auth.uid()
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Only admins can insert terms"
    ON terms FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id::uuid = auth.uid()
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Only admins can update terms"
    ON terms FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id::uuid = auth.uid()
            AND users.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id::uuid = auth.uid()
            AND users.role = 'admin'
        )
    );

-- Notifications table - fix text = uuid issues
CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id::uuid);

CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id::uuid);

-- ==============================================
-- VERIFY FIXED POLICIES
-- ==============================================

-- Check if the problematic policies are fixed
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('settings', 'terms', 'notifications')
ORDER BY tablename, policyname;













