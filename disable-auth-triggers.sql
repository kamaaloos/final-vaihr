-- Temporarily disable triggers to see if that fixes the issue
-- This will help us identify if triggers are causing the problem

-- List all triggers on auth.users
SELECT 
    trigger_name,
    'DISABLED' as status
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth';

-- Disable triggers on auth.users (if any exist)
-- Note: This is just for testing - we'll re-enable them later
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'users' 
        AND event_object_schema = 'auth'
    LOOP
        EXECUTE format('ALTER TABLE auth.users DISABLE TRIGGER %I', trigger_record.trigger_name);
        RAISE NOTICE 'Disabled trigger: %', trigger_record.trigger_name;
    END LOOP;
END $$;
