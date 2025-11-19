-- Run these migrations manually in your Supabase SQL Editor
-- Run them in this exact order:

-- 1. First, create the basic tables
-- Run: 002_create_jobs_table.sql
-- Run: 004_create_user_status_table.sql
-- Run: 005_create_profiles_table.sql
-- Run: 006_create_chats_table.sql
-- Run: 008_create_invoices_table.sql
-- Run: 009_create_notifications_table.sql

-- 2. Then, add RLS policies
-- Run: 010_add_users_rls_policies.sql
-- Run: 020_fix_user_status_permissions.sql

-- 3. Finally, add triggers and functions
-- Run: 082_add_job_status_notification_trigger.sql
-- Run: 083_comprehensive_notification_triggers.sql

-- Note: Skip the problematic migrations for now
-- We can add them later once the basic structure is working













