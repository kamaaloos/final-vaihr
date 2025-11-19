-- Migrate exact RLS policies from old database
-- Run this in your Supabase SQL Editor

-- ==============================================
-- DROP ALL EXISTING POLICIES FIRST
-- ==============================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view their own status" ON user_status;
DROP POLICY IF EXISTS "Users can update their own status" ON user_status;
DROP POLICY IF EXISTS "Users can insert their own status" ON user_status;
DROP POLICY IF EXISTS "Users can view their own settings" ON settings;
DROP POLICY IF EXISTS "Users can update their own settings" ON settings;
DROP POLICY IF EXISTS "Users can insert their own settings" ON settings;
DROP POLICY IF EXISTS "Users can view their own terms" ON terms;
DROP POLICY IF EXISTS "Users can update their own terms" ON terms;
DROP POLICY IF EXISTS "Users can insert their own terms" ON terms;
DROP POLICY IF EXISTS "Admins can see all jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers see new jobs and their own jobs" ON jobs;
DROP POLICY IF EXISTS "Admins can create jobs" ON jobs;
DROP POLICY IF EXISTS "Admins can update jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers can accept new jobs" ON jobs;
DROP POLICY IF EXISTS "Users can view their own chats" ON chats;
DROP POLICY IF EXISTS "Users can create chats" ON chats;
DROP POLICY IF EXISTS "Users can update their own chats" ON chats;
DROP POLICY IF EXISTS "Users can view messages in their chats" ON messages;
DROP POLICY IF EXISTS "Users can send messages in their chats" ON messages;
DROP POLICY IF EXISTS "Users can view their own invoices" ON invoices;
DROP POLICY IF EXISTS "Admins can create invoices" ON invoices;
DROP POLICY IF EXISTS "Admins can update invoices" ON invoices;
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
DROP POLICY IF EXISTS "System can create notifications" ON notifications;
DROP POLICY IF EXISTS "Users can view their own presence notifications" ON presence_notifications;
DROP POLICY IF EXISTS "Users can create presence notifications" ON presence_notifications;
DROP POLICY IF EXISTS "Users can delete their own presence notifications" ON presence_notifications;

-- ==============================================
-- PROFILES TABLE POLICIES (EXACT FROM OLD DB)
-- ==============================================

CREATE POLICY "Users can insert their own profile"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view any profile"
    ON profiles FOR SELECT
    TO authenticated
    USING (true);

-- ==============================================
-- USER_STATUS TABLE POLICIES (EXACT FROM OLD DB)
-- ==============================================

CREATE POLICY "Admins can create user status records"
    ON user_status FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can insert all statuses"
    ON user_status FOR INSERT
    TO public
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can update all statuses"
    ON user_status FOR UPDATE
    TO public
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Allow authenticated users access"
    ON user_status FOR ALL
    TO public
    USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert own status"
    ON user_status FOR INSERT
    TO public
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND user_id = auth.uid()
    );

CREATE POLICY "Authenticated users can update own status"
    ON user_status FOR UPDATE
    TO public
    USING (
        auth.uid() IS NOT NULL
        AND user_id = auth.uid()
    );

CREATE POLICY "Authenticated users can view own status"
    ON user_status FOR SELECT
    TO public
    USING (
        auth.uid() IS NOT NULL
        AND user_id = auth.uid()
    );

-- ==============================================
-- SETTINGS TABLE POLICIES (EXACT FROM OLD DB)
-- ==============================================

CREATE POLICY "Users can view their own settings"
    ON settings FOR SELECT
    TO authenticated
    USING (auth.uid()::text = user_id);

-- ==============================================
-- TERMS TABLE POLICIES (EXACT FROM OLD DB)
-- ==============================================

CREATE POLICY "Drivers and admins can view terms"
    ON terms FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()::text
            AND (users.role = 'driver' OR users.role = 'admin')
        )
    );

CREATE POLICY "Only admins can delete terms"
    ON terms FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()::text
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Only admins can insert terms"
    ON terms FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()::text
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Only admins can update terms"
    ON terms FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()::text
            AND users.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()::text
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Service role full access"
    ON terms FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ==============================================
-- JOBS TABLE POLICIES (EXACT FROM OLD DB)
-- ==============================================

CREATE POLICY "Drivers can accept jobs"
    ON jobs FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'driver'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'driver'
        )
        AND (
            driver_id = auth.uid()
            OR (status = 'assigned' AND driver_id = auth.uid())
        )
    );

CREATE POLICY "Drivers can complete their jobs"
    ON jobs FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'driver'
        )
        AND driver_id = auth.uid()
        AND status = 'in_progress'
    )
    WITH CHECK (
        status = 'completed'
        AND driver_id = auth.uid()
    );

CREATE POLICY "jobs_delete_policy"
    ON jobs FOR DELETE
    TO authenticated
    USING (true);

CREATE POLICY "jobs_insert_policy"
    ON jobs FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "jobs_select_policy"
    ON jobs FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users au
            WHERE au.id = auth.uid()
            AND au.raw_user_meta_data->>'role' = 'admin'
        )
        OR (status = 'open' OR driver_id = auth.uid())
    );

CREATE POLICY "jobs_update_policy"
    ON jobs FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ==============================================
-- CHATS TABLE POLICIES (EXACT FROM OLD DB)
-- ==============================================

CREATE POLICY "Users can create chats they're part of"
    ON chats FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = driver_id
        OR auth.uid() = admin_id
    );

CREATE POLICY "Users can update their own chats"
    ON chats FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = driver_id
        OR auth.uid() = admin_id
    )
    WITH CHECK (
        auth.uid() = driver_id
        OR auth.uid() = admin_id
    );

CREATE POLICY "Users can view their own chats"
    ON chats FOR SELECT
    TO authenticated
    USING (
        auth.uid() = driver_id
        OR auth.uid() = admin_id
    );

CREATE POLICY "chats_insert_policy"
    ON chats FOR INSERT
    TO public
    WITH CHECK (
        auth.uid() = driver_id
        OR auth.uid() = admin_id
        OR auth.uid() IN (
            SELECT users.id
            FROM auth.users
            WHERE users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "chats_select_policy"
    ON chats FOR SELECT
    TO public
    USING (
        auth.uid() = driver_id
        OR auth.uid() = admin_id
        OR auth.uid() IN (
            SELECT users.id
            FROM auth.users
            WHERE users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "chats_update_policy"
    ON chats FOR UPDATE
    TO public
    USING (
        auth.uid() = driver_id
        OR auth.uid() = admin_id
        OR auth.uid() IN (
            SELECT users.id
            FROM auth.users
            WHERE users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- ==============================================
-- MESSAGES TABLE POLICIES (EXACT FROM OLD DB)
-- ==============================================

CREATE POLICY "Users can delete their own messages"
    ON messages FOR DELETE
    TO authenticated
    USING (sender_id = auth.uid());

CREATE POLICY "Users can insert messages in their chats"
    ON messages FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM chats
            WHERE chats.id = messages.chat_id
            AND (chats.driver_id = auth.uid() OR chats.admin_id = auth.uid())
        )
        AND sender_id = auth.uid()
    );

CREATE POLICY "Users can update their own messages"
    ON messages FOR UPDATE
    TO authenticated
    USING (sender_id = auth.uid())
    WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can view messages in their chats"
    ON messages FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM chats
            WHERE chats.id = messages.chat_id
            AND (chats.driver_id = auth.uid() OR chats.admin_id = auth.uid())
        )
    );

-- ==============================================
-- INVOICES TABLE POLICIES (EXACT FROM OLD DB)
-- ==============================================

CREATE POLICY "Users can view their own invoices or admin can view all"
    ON invoices FOR SELECT
    TO public
    USING (
        driver_id = auth.uid()
        OR admin_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Users can view their own invoices or admins can view all"
    ON invoices FOR SELECT
    TO public
    USING (
        driver_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "invoices_insert_policy"
    ON invoices FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'driver'
        )
        AND driver_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM jobs
            WHERE jobs.id = invoices.job_id
            AND jobs.driver_id = auth.uid()
            AND jobs.status = 'completed'
        )
        AND amount > 0
    );

CREATE POLICY "invoices_select_policy"
    ON invoices FOR SELECT
    TO authenticated
    USING (
        driver_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "invoices_update_policy"
    ON invoices FOR UPDATE
    TO public
    USING (
        driver_id = auth.uid()
        OR admin_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    )
    WITH CHECK (
        driver_id = auth.uid()
        OR admin_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- ==============================================
-- NOTIFICATIONS TABLE POLICIES (EXACT FROM OLD DB)
-- ==============================================

CREATE POLICY "Admin can manage all notifications"
    ON notifications FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()::text
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can create notifications"
    ON notifications FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Authenticated users can insert notifications"
    ON notifications FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    TO authenticated
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own notifications"
    ON notifications FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    TO authenticated
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can view their own notifications"
    ON notifications FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- ==============================================
-- PRESENCE_NOTIFICATIONS TABLE POLICIES (EXACT FROM OLD DB)
-- ==============================================

CREATE POLICY "Users can insert presence notifications"
    ON presence_notifications FOR INSERT
    TO public
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read their own presence notifications"
    ON presence_notifications FOR SELECT
    TO public
    USING (auth.uid() = user_id);

-- ==============================================
-- VERIFY ALL POLICIES
-- ==============================================

-- Check all policies
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
WHERE tablename IN ('profiles', 'user_status', 'settings', 'terms', 'jobs', 'chats', 'messages', 'invoices', 'notifications', 'presence_notifications')
ORDER BY tablename, policyname;













