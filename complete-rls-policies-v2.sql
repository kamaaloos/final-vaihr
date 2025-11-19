-- Complete RLS policies for all tables (Version 2)
-- Run this in your Supabase SQL Editor

-- ==============================================
-- USERS TABLE POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to insert own profile" ON users;
DROP POLICY IF EXISTS "Allow any authenticated user to insert" ON users;

-- Create users policies
CREATE POLICY "Users can view their own profile"
    ON users FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow authenticated users to insert own profile"
    ON users FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- ==============================================
-- PROFILES TABLE POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;

-- Create profiles policies
CREATE POLICY "Users can view their own profile"
    ON profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- ==============================================
-- USER_STATUS TABLE POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own status" ON user_status;
DROP POLICY IF EXISTS "Users can update their own status" ON user_status;
DROP POLICY IF EXISTS "Users can insert their own status" ON user_status;

-- Create user_status policies
CREATE POLICY "Users can view their own status"
    ON user_status FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own status"
    ON user_status FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own status"
    ON user_status FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- ==============================================
-- SETTINGS TABLE POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own settings" ON settings;
DROP POLICY IF EXISTS "Users can update their own settings" ON settings;
DROP POLICY IF EXISTS "Users can insert their own settings" ON settings;

-- Create settings policies
CREATE POLICY "Users can view their own settings"
    ON settings FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings"
    ON settings FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings"
    ON settings FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- ==============================================
-- TERMS TABLE POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own terms" ON terms;
DROP POLICY IF EXISTS "Users can update their own terms" ON terms;
DROP POLICY IF EXISTS "Users can insert their own terms" ON terms;

-- Create terms policies
CREATE POLICY "Users can view their own terms"
    ON terms FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own terms"
    ON terms FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own terms"
    ON terms FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- ==============================================
-- JOBS TABLE POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins can see all jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers see new jobs and their own jobs" ON jobs;
DROP POLICY IF EXISTS "Admins can create jobs" ON jobs;
DROP POLICY IF EXISTS "Admins can update jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers can accept new jobs" ON jobs;

-- Create jobs policies
CREATE POLICY "Admins can see all jobs"
    ON jobs FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Drivers see new jobs and their own jobs"
    ON jobs FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'driver'
            AND (
                (jobs.status = 'new' AND jobs.driver_id IS NULL)
                OR jobs.driver_id = auth.uid()
            )
        )
    );

CREATE POLICY "Admins can create jobs"
    ON jobs FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can update jobs"
    ON jobs FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Drivers can accept new jobs"
    ON jobs FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'driver'
        )
        AND jobs.status = 'new'
        AND jobs.driver_id IS NULL
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'driver'
        )
        AND (
            CASE 
                WHEN jobs.status = 'new' AND jobs.driver_id IS NULL THEN
                    status = 'processing' AND driver_id = auth.uid()
                ELSE false
            END
        )
    );

-- ==============================================
-- CHAT_RELATIONSHIP TABLE POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own chat relationships" ON chat_relationship;
DROP POLICY IF EXISTS "Users can create chat relationships" ON chat_relationship;
DROP POLICY IF EXISTS "Users can update their own chat relationships" ON chat_relationship;

-- Create chat_relationship policies
CREATE POLICY "Users can view their own chat relationships"
    ON chat_relationship FOR SELECT
    TO authenticated
    USING (auth.uid() = driver_id OR auth.uid() = admin_id);

CREATE POLICY "Users can create chat relationships"
    ON chat_relationship FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = driver_id OR auth.uid() = admin_id);

CREATE POLICY "Users can update their own chat relationships"
    ON chat_relationship FOR UPDATE
    TO authenticated
    USING (auth.uid() = driver_id OR auth.uid() = admin_id)
    WITH CHECK (auth.uid() = driver_id OR auth.uid() = admin_id);

-- ==============================================
-- CHATS TABLE POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own chats" ON chats;
DROP POLICY IF EXISTS "Users can create chats" ON chats;
DROP POLICY IF EXISTS "Users can update their own chats" ON chats;

-- Create chats policies
CREATE POLICY "Users can view their own chats"
    ON chats FOR SELECT
    TO authenticated
    USING (auth.uid() = driver_id OR auth.uid() = admin_id);

CREATE POLICY "Users can create chats"
    ON chats FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = driver_id OR auth.uid() = admin_id);

CREATE POLICY "Users can update their own chats"
    ON chats FOR UPDATE
    TO authenticated
    USING (auth.uid() = driver_id OR auth.uid() = admin_id)
    WITH CHECK (auth.uid() = driver_id OR auth.uid() = admin_id);

-- ==============================================
-- MESSAGES TABLE POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view messages in their chats" ON messages;
DROP POLICY IF EXISTS "Users can send messages in their chats" ON messages;

-- Create messages policies
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

CREATE POLICY "Users can send messages in their chats"
    ON messages FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = sender_id
        AND EXISTS (
            SELECT 1 FROM chats
            WHERE chats.id = messages.chat_id
            AND (chats.driver_id = auth.uid() OR chats.admin_id = auth.uid())
        )
    );

-- ==============================================
-- INVOICES TABLE POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own invoices" ON invoices;
DROP POLICY IF EXISTS "Admins can create invoices" ON invoices;
DROP POLICY IF EXISTS "Admins can update invoices" ON invoices;

-- Create invoices policies
CREATE POLICY "Users can view their own invoices"
    ON invoices FOR SELECT
    TO authenticated
    USING (auth.uid() = driver_id OR auth.uid() = admin_id);

CREATE POLICY "Admins can create invoices"
    ON invoices FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

CREATE POLICY "Admins can update invoices"
    ON invoices FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'admin'
        )
    );

-- ==============================================
-- NOTIFICATIONS TABLE POLICIES
-- ==============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
DROP POLICY IF EXISTS "System can create notifications" ON notifications;

-- Create notifications policies
CREATE POLICY "Users can view their own notifications"
    ON notifications FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
    ON notifications FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "System can create notifications"
    ON notifications FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);













