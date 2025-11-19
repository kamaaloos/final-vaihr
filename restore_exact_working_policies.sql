-- Restore the exact working RLS policies from the old database
-- This will recreate all the policies that were working before

-- ==============================================
-- STEP 1: CLEAN SLATE - DROP ALL EXISTING POLICIES
-- ==============================================

-- Disable RLS temporarily on all tables
ALTER TABLE chats DISABLE ROW LEVEL SECURITY;
ALTER TABLE invoices DISABLE ROW LEVEL SECURITY;
ALTER TABLE jobs DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE presence_notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE terms DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_status DISABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies
DROP POLICY IF EXISTS "Users can create chats they're part of" ON chats;
DROP POLICY IF EXISTS "Users can update their own chats" ON chats;
DROP POLICY IF EXISTS "Users can view their own chats" ON chats;
DROP POLICY IF EXISTS "chats_insert_policy" ON chats;
DROP POLICY IF EXISTS "chats_select_policy" ON chats;
DROP POLICY IF EXISTS "chats_update_policy" ON chats;

DROP POLICY IF EXISTS "Users can view their own invoices or admin can view all" ON invoices;
DROP POLICY IF EXISTS "Users can view their own invoices or admins can view all" ON invoices;
DROP POLICY IF EXISTS "invoices_insert_policy" ON invoices;
DROP POLICY IF EXISTS "invoices_select_policy" ON invoices;
DROP POLICY IF EXISTS "invoices_update_policy" ON invoices;

DROP POLICY IF EXISTS "Drivers can accept jobs" ON jobs;
DROP POLICY IF EXISTS "Drivers can complete their jobs" ON jobs;
DROP POLICY IF EXISTS "jobs_delete_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_insert_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_select_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_update_policy" ON jobs;

DROP POLICY IF EXISTS "Users can delete their own messages" ON messages;
DROP POLICY IF EXISTS "Users can insert messages in their chats" ON messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
DROP POLICY IF EXISTS "Users can view messages in their chats" ON messages;

DROP POLICY IF EXISTS "Admin can manage all notifications" ON notifications;
DROP POLICY IF EXISTS "Admins can create notifications" ON notifications;
DROP POLICY IF EXISTS "Authenticated users can insert notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;

DROP POLICY IF EXISTS "Users can insert presence notifications" ON presence_notifications;
DROP POLICY IF EXISTS "Users can read their own presence notifications" ON presence_notifications;

DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view any profile" ON profiles;

DROP POLICY IF EXISTS "Users can view their own settings" ON settings;

DROP POLICY IF EXISTS "Drivers and admins can view terms" ON terms;
DROP POLICY IF EXISTS "Only admins can delete terms" ON terms;
DROP POLICY IF EXISTS "Only admins can insert terms" ON terms;
DROP POLICY IF EXISTS "Only admins can update terms" ON terms;
DROP POLICY IF EXISTS "Service role full access" ON terms;

DROP POLICY IF EXISTS "Admins can create user status records" ON user_status;
DROP POLICY IF EXISTS "Admins can insert all statuses" ON user_status;
DROP POLICY IF EXISTS "Admins can update all statuses" ON user_status;
DROP POLICY IF EXISTS "Allow authenticated users access" ON user_status;
DROP POLICY IF EXISTS "Authenticated users can insert own status" ON user_status;
DROP POLICY IF EXISTS "Authenticated users can update own status" ON user_status;
DROP POLICY IF EXISTS "Authenticated users can view own status" ON user_status;

-- ==============================================
-- STEP 2: RE-ENABLE RLS
-- ==============================================

ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE presence_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE terms ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- STEP 3: RESTORE EXACT WORKING POLICIES
-- ==============================================

-- CHATS TABLE POLICIES
CREATE POLICY "Users can create chats they're part of"
    ON chats FOR INSERT
    TO authenticated
    WITH CHECK ((auth.uid() = driver_id) OR (auth.uid() = admin_id));

CREATE POLICY "Users can update their own chats"
    ON chats FOR UPDATE
    TO authenticated
    USING ((auth.uid() = driver_id) OR (auth.uid() = admin_id))
    WITH CHECK ((auth.uid() = driver_id) OR (auth.uid() = admin_id));

CREATE POLICY "Users can view their own chats"
    ON chats FOR SELECT
    TO authenticated
    USING ((auth.uid() = driver_id) OR (auth.uid() = admin_id));

CREATE POLICY "chats_insert_policy"
    ON chats FOR INSERT
    TO public
    WITH CHECK ((auth.uid() = driver_id) OR (auth.uid() = admin_id) OR (auth.uid() IN ( SELECT users.id
   FROM auth.users
  WHERE ((users.raw_user_meta_data ->> 'role'::text) = 'admin'::text))));

CREATE POLICY "chats_select_policy"
    ON chats FOR SELECT
    TO public
    USING ((auth.uid() = driver_id) OR (auth.uid() = admin_id) OR (auth.uid() IN ( SELECT users.id
   FROM auth.users
  WHERE ((users.raw_user_meta_data ->> 'role'::text) = 'admin'::text))));

CREATE POLICY "chats_update_policy"
    ON chats FOR UPDATE
    TO public
    USING ((auth.uid() = driver_id) OR (auth.uid() = admin_id) OR (auth.uid() IN ( SELECT users.id
   FROM auth.users
  WHERE ((users.raw_user_meta_data ->> 'role'::text) = 'admin'::text))));

-- INVOICES TABLE POLICIES
CREATE POLICY "Users can view their own invoices or admin can view all"
    ON invoices FOR SELECT
    TO public
    USING ((driver_id = auth.uid()) OR (admin_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'admin'::text)))));

CREATE POLICY "Users can view their own invoices or admins can view all"
    ON invoices FOR SELECT
    TO public
    USING ((driver_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'admin'::text)))));

CREATE POLICY "invoices_insert_policy"
    ON invoices FOR INSERT
    TO authenticated
    WITH CHECK ((EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'driver'::text)))) AND (driver_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM jobs
  WHERE ((jobs.id = invoices.job_id) AND (jobs.driver_id = auth.uid()) AND (jobs.status = 'completed'::text)))) AND (amount > (0)::numeric));

CREATE POLICY "invoices_select_policy"
    ON invoices FOR SELECT
    TO authenticated
    USING ((driver_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'admin'::text)))));

CREATE POLICY "invoices_update_policy"
    ON invoices FOR UPDATE
    TO public
    USING ((driver_id = auth.uid()) OR (admin_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'admin'::text)))))
    WITH CHECK ((driver_id = auth.uid()) OR (admin_id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'admin'::text)))));

-- JOBS TABLE POLICIES (THE KEY ONES!)
CREATE POLICY "Drivers can accept jobs"
    ON jobs FOR UPDATE
    TO authenticated
    USING (EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'driver'::text))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'driver'::text)))) AND ((driver_id = auth.uid()) OR ((status = 'assigned'::text) AND (driver_id = auth.uid()))));

CREATE POLICY "Drivers can complete their jobs"
    ON jobs FOR UPDATE
    TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'driver'::text)))) AND (driver_id = auth.uid()) AND (status = 'in_progress'::text))
    WITH CHECK ((status = 'completed'::text) AND (driver_id = auth.uid()));

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
    USING ((EXISTS ( SELECT 1
   FROM auth.users au
  WHERE ((au.id = auth.uid()) AND ((au.raw_user_meta_data ->> 'role'::text) = 'admin'::text)))) OR ((status = 'open'::text) OR (driver_id = auth.uid())));

CREATE POLICY "jobs_update_policy"
    ON jobs FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- MESSAGES TABLE POLICIES
CREATE POLICY "Users can delete their own messages"
    ON messages FOR DELETE
    TO authenticated
    USING (sender_id = auth.uid());

CREATE POLICY "Users can insert messages in their chats"
    ON messages FOR INSERT
    TO authenticated
    WITH CHECK ((EXISTS ( SELECT 1
   FROM chats
  WHERE ((chats.id = messages.chat_id) AND ((chats.driver_id = auth.uid()) OR (chats.admin_id = auth.uid()))))) AND (sender_id = auth.uid()));

CREATE POLICY "Users can update their own messages"
    ON messages FOR UPDATE
    TO authenticated
    USING (sender_id = auth.uid())
    WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can view messages in their chats"
    ON messages FOR SELECT
    TO authenticated
    USING (EXISTS ( SELECT 1
   FROM chats
  WHERE ((chats.id = messages.chat_id) AND ((chats.driver_id = auth.uid()) OR (chats.admin_id = auth.uid())))));

-- NOTIFICATIONS TABLE POLICIES
CREATE POLICY "Admin can manage all notifications"
    ON notifications FOR ALL
    TO authenticated
    USING (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = (auth.uid())::text) AND (users.role = 'admin'::text))));

CREATE POLICY "Admins can create notifications"
    ON notifications FOR INSERT
    TO authenticated
    WITH CHECK (EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.role)::text = 'admin'::text))));

CREATE POLICY "Authenticated users can insert notifications"
    ON notifications FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    TO authenticated
    USING (((auth.uid())::text = (user_id)::text));

CREATE POLICY "Users can update their own notifications"
    ON notifications FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    TO authenticated
    USING (((auth.uid())::text = (user_id)::text));

CREATE POLICY "Users can view their own notifications"
    ON notifications FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- PRESENCE_NOTIFICATIONS TABLE POLICIES
CREATE POLICY "Users can insert presence notifications"
    ON presence_notifications FOR INSERT
    TO public
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read their own presence notifications"
    ON presence_notifications FOR SELECT
    TO public
    USING (auth.uid() = user_id);

-- PROFILES TABLE POLICIES
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

-- SETTINGS TABLE POLICIES
CREATE POLICY "Users can view their own settings"
    ON settings FOR SELECT
    TO authenticated
    USING (((auth.uid())::text = user_id));

-- TERMS TABLE POLICIES
CREATE POLICY "Drivers and admins can view terms"
    ON terms FOR SELECT
    TO authenticated
    USING (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = (auth.uid())::text) AND ((users.role = 'driver'::text) OR (users.role = 'admin'::text)))));

CREATE POLICY "Only admins can delete terms"
    ON terms FOR DELETE
    TO authenticated
    USING (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = (auth.uid())::text) AND (users.role = 'admin'::text))));

CREATE POLICY "Only admins can insert terms"
    ON terms FOR INSERT
    TO authenticated
    WITH CHECK (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = (auth.uid())::text) AND (users.role = 'admin'::text))));

CREATE POLICY "Only admins can update terms"
    ON terms FOR UPDATE
    TO authenticated
    USING (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = (auth.uid())::text) AND (users.role = 'admin'::text))))
    WITH CHECK (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = (auth.uid())::text) AND (users.role = 'admin'::text))));

CREATE POLICY "Service role full access"
    ON terms FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- USER_STATUS TABLE POLICIES
CREATE POLICY "Admins can create user status records"
    ON user_status FOR INSERT
    TO authenticated
    WITH CHECK (EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'admin'::text))));

CREATE POLICY "Admins can insert all statuses"
    ON user_status FOR INSERT
    TO public
    WITH CHECK ((auth.uid() IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'admin'::text)))));

CREATE POLICY "Admins can update all statuses"
    ON user_status FOR UPDATE
    TO public
    USING ((auth.uid() IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'admin'::text)))));

CREATE POLICY "Allow authenticated users access"
    ON user_status FOR ALL
    TO public
    USING (auth.role() = 'authenticated'::text);

CREATE POLICY "Authenticated users can insert own status"
    ON user_status FOR INSERT
    TO public
    WITH CHECK ((auth.uid() IS NOT NULL) AND (user_id = auth.uid()));

CREATE POLICY "Authenticated users can update own status"
    ON user_status FOR UPDATE
    TO public
    USING ((auth.uid() IS NOT NULL) AND (user_id = auth.uid()));

CREATE POLICY "Authenticated users can view own status"
    ON user_status FOR SELECT
    TO public
    USING ((auth.uid() IS NOT NULL) AND (user_id = auth.uid()));

-- ==============================================
-- STEP 4: GRANT NECESSARY PERMISSIONS
-- ==============================================

GRANT ALL ON chats TO authenticated;
GRANT ALL ON invoices TO authenticated;
GRANT ALL ON jobs TO authenticated;
GRANT ALL ON messages TO authenticated;
GRANT ALL ON notifications TO authenticated;
GRANT ALL ON presence_notifications TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON settings TO authenticated;
GRANT ALL ON terms TO authenticated;
GRANT ALL ON user_status TO authenticated;

-- ==============================================
-- STEP 5: VERIFY THE SETUP
-- ==============================================

-- Check that all policies are created
SELECT 
    'Policies created:' as info,
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd
FROM pg_policies 
WHERE tablename IN ('chats', 'invoices', 'jobs', 'messages', 'notifications', 'presence_notifications', 'profiles', 'settings', 'terms', 'user_status')
ORDER BY tablename, policyname;

-- Check RLS status
SELECT 
    'RLS Status:' as info,
    schemaname, 
    tablename, 
    rowsecurity 
FROM pg_tables 
WHERE tablename IN ('chats', 'invoices', 'jobs', 'messages', 'notifications', 'presence_notifications', 'profiles', 'settings', 'terms', 'user_status');
