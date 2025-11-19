-- Simple Notification Triggers Migration
-- This script creates the essential notification triggers

-- Drop existing triggers and functions first
DROP TRIGGER IF EXISTS job_creation_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_status_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS invoice_creation_notification_trigger ON invoices;
DROP TRIGGER IF EXISTS invoice_status_notification_trigger ON invoices;

DROP FUNCTION IF EXISTS notify_drivers_on_job_creation();
DROP FUNCTION IF EXISTS should_notify_driver(JSONB, TEXT, TEXT);
DROP FUNCTION IF EXISTS notify_admin_on_job_status_change();
DROP FUNCTION IF EXISTS notify_admin_on_invoice_creation();
DROP FUNCTION IF EXISTS notify_on_invoice_status_change();

-- ============================================================================
-- 1. JOB CREATION NOTIFICATION TRIGGER
-- ============================================================================

-- Helper function to determine if a driver should be notified
CREATE OR REPLACE FUNCTION should_notify_driver(
    driver_preferences JSONB,
    job_location TEXT,
    job_rate TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    -- If no preferences, notify all drivers
    IF driver_preferences IS NULL THEN
        RETURN TRUE;
    END IF;

    -- Check excluded locations
    IF driver_preferences ? 'excludedLocations' THEN
        IF job_location = ANY(ARRAY(SELECT jsonb_array_elements_text(driver_preferences->'excludedLocations'))) THEN
            RETURN FALSE;
        END IF;
    END IF;

    -- Check minimum rate
    IF driver_preferences ? 'minRate' THEN
        IF (job_rate::DECIMAL) < (driver_preferences->>'minRate')::DECIMAL THEN
            RETURN FALSE;
        END IF;
    END IF;

    RETURN TRUE;
END;
$$;

-- Create a function to handle job creation notifications
CREATE OR REPLACE FUNCTION notify_drivers_on_job_creation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_name TEXT;
    v_admin_email TEXT;
    v_driver_record RECORD;
BEGIN
    -- Only proceed for new job insertions
    IF TG_OP != 'INSERT' THEN
        RETURN NEW;
    END IF;

    -- Get admin details from auth.users
    SELECT 
        COALESCE(raw_user_meta_data->>'name', email) as name,
        email
    INTO v_admin_name, v_admin_email
    FROM auth.users
    WHERE id = NEW.admin_id;

    -- Get all active drivers with push tokens
    FOR v_driver_record IN
        SELECT 
            u.id,
            u.expo_push_token,
            COALESCE(au.raw_user_meta_data->>'name', au.email) as name,
            u.preferences
        FROM users u
        JOIN auth.users au ON u.id = au.id
        WHERE u.role = 'driver'
        AND u.expo_push_token IS NOT NULL
        AND u.is_online = true
    LOOP
        -- Check if driver should be notified based on preferences
        IF should_notify_driver(v_driver_record.preferences, NEW.location, NEW.rate) THEN
            -- Create notification record for driver
            INSERT INTO notifications (
                user_id,
                title,
                message,
                type,
                data,
                created_at
            ) VALUES (
                v_driver_record.id,
                'New Job Available',
                format('%s posted a new job: %s', v_admin_name, NEW.title),
                'job_creation',
                jsonb_build_object(
                    'jobId', NEW.id,
                    'jobTitle', NEW.title,
                    'jobLocation', NEW.location,
                    'jobRate', NEW.rate,
                    'adminName', v_admin_name,
                    'adminEmail', v_admin_email,
                    'pushToken', v_driver_record.expo_push_token
                ),
                NOW()
            );

            -- Log the notification
            RAISE NOTICE 'Driver notification created for %: New job "%s"', 
                v_driver_record.name, NEW.title;
        END IF;
    END LOOP;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the job creation
        RAISE NOTICE 'Error creating driver notifications: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Create trigger for job creation notifications
CREATE TRIGGER job_creation_notification_trigger
    AFTER INSERT ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_drivers_on_job_creation();

-- ============================================================================
-- 2. JOB STATUS CHANGE NOTIFICATION TRIGGER
-- ============================================================================

-- Enhanced function to handle job status change notifications
CREATE OR REPLACE FUNCTION notify_admin_on_job_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_id UUID;
    v_admin_push_token TEXT;
    v_job_title TEXT;
    v_old_status TEXT;
    v_new_status TEXT;
    v_notification_title TEXT;
    v_notification_message TEXT;
    v_driver_name TEXT;
    v_driver_email TEXT;
BEGIN
    -- Only proceed if status actually changed
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    -- Get job details
    v_job_title := NEW.title;
    v_old_status := OLD.status;
    v_new_status := NEW.status;
    v_admin_id := NEW.admin_id;

    -- Skip if no admin_id
    IF v_admin_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Get driver details if available (from auth.users)
    IF NEW.driver_id IS NOT NULL THEN
        SELECT 
            COALESCE(raw_user_meta_data->>'name', email) as name,
            email
        INTO v_driver_name, v_driver_email
        FROM auth.users
        WHERE id = NEW.driver_id;
    END IF;

    -- Determine notification content based on status change
    CASE 
        WHEN v_old_status = 'open' AND v_new_status = 'assigned' THEN
            v_notification_title := 'Job Accepted';
            v_notification_message := CASE 
                WHEN v_driver_name IS NOT NULL THEN 
                    format('Job "%s" has been accepted by %s', v_job_title, v_driver_name)
                ELSE 
                    format('Job "%s" has been accepted by a driver', v_job_title)
            END;
        
        WHEN v_old_status = 'assigned' AND v_new_status = 'in_progress' THEN
            v_notification_title := 'Job Started';
            v_notification_message := CASE 
                WHEN v_driver_name IS NOT NULL THEN 
                    format('Job "%s" has been started by %s', v_job_title, v_driver_name)
                ELSE 
                    format('Job "%s" has been started by a driver', v_job_title)
            END;
        
        WHEN v_old_status = 'in_progress' AND v_new_status = 'completed' THEN
            v_notification_title := 'Job Completed';
            v_notification_message := CASE 
                WHEN v_driver_name IS NOT NULL THEN 
                    format('Job "%s" has been completed by %s', v_job_title, v_driver_name)
                ELSE 
                    format('Job "%s" has been completed by a driver', v_job_title)
            END;
        
        WHEN v_new_status = 'cancelled' THEN
            v_notification_title := 'Job Cancelled';
            v_notification_message := CASE 
                WHEN v_driver_name IS NOT NULL THEN 
                    format('Job "%s" has been cancelled by %s', v_job_title, v_driver_name)
                ELSE 
                    format('Job "%s" has been cancelled', v_job_title)
            END;
        
        ELSE
            -- For any other status change, send a generic notification
            v_notification_title := 'Job Status Updated';
            v_notification_message := format('Job "%s" status changed from %s to %s', 
                v_job_title, v_old_status, v_new_status);
    END CASE;

    -- Get admin's push token from users table
    SELECT expo_push_token INTO v_admin_push_token
    FROM users
    WHERE id = v_admin_id;

    -- Create notification record in database
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        data,
        created_at
    ) VALUES (
        v_admin_id,
        v_notification_title,
        v_notification_message,
        'job_status',
        jsonb_build_object(
            'jobId', NEW.id,
            'oldStatus', v_old_status,
            'newStatus', v_new_status,
            'driverId', NEW.driver_id,
            'driverName', v_driver_name,
            'driverEmail', v_driver_email,
            'pushToken', v_admin_push_token
        ),
        NOW()
    );

    -- Log the notification for debugging
    RAISE NOTICE 'Admin notification created: % - %', v_notification_title, v_notification_message;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the job update
        RAISE NOTICE 'Error creating admin notification: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Create trigger for job status change notifications
CREATE TRIGGER job_status_notification_trigger
    AFTER UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_admin_on_job_status_change();

-- ============================================================================
-- 3. INVOICE CREATION NOTIFICATION TRIGGER
-- ============================================================================

-- Create a function to handle invoice creation notifications
CREATE OR REPLACE FUNCTION notify_admin_on_invoice_creation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_id UUID;
    v_admin_push_token TEXT;
    v_job_title TEXT;
    v_driver_name TEXT;
    v_driver_email TEXT;
    v_amount DECIMAL;
    v_invoice_number TEXT;
    v_notification_title TEXT;
    v_notification_message TEXT;
BEGIN
    -- Only proceed for new invoice insertions
    IF TG_OP != 'INSERT' THEN
        RETURN NEW;
    END IF;

    -- Get job and driver details
    SELECT 
        j.title,
        j.admin_id,
        COALESCE(au.raw_user_meta_data->>'name', au.email) as driver_name,
        au.email as driver_email
    INTO v_job_title, v_admin_id, v_driver_name, v_driver_email
    FROM jobs j
    LEFT JOIN auth.users au ON j.driver_id = au.id
    WHERE j.id = NEW.job_id;

    -- Skip if no admin_id or job not found
    IF v_admin_id IS NULL OR v_job_title IS NULL THEN
        RETURN NEW;
    END IF;

    -- Get invoice details
    v_amount := NEW.amount;
    v_invoice_number := NEW.invoice_number;

    -- Set notification content
    v_notification_title := 'Invoice Generated';
    v_notification_message := CASE 
        WHEN v_driver_name IS NOT NULL THEN 
            format('Invoice %s generated for job "%s" completed by %s (€%.2f)', 
                v_invoice_number, v_job_title, v_driver_name, v_amount)
        ELSE 
            format('Invoice %s generated for job "%s" (€%.2f)', 
                v_invoice_number, v_job_title, v_amount)
    END;

    -- Get admin's push token from users table
    SELECT expo_push_token INTO v_admin_push_token
    FROM users
    WHERE id = v_admin_id;

    -- Create notification record in database
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        data,
        created_at
    ) VALUES (
        v_admin_id,
        v_notification_title,
        v_notification_message,
        'invoice_creation',
        jsonb_build_object(
            'invoiceId', NEW.id,
            'invoiceNumber', v_invoice_number,
            'jobId', NEW.job_id,
            'jobTitle', v_job_title,
            'driverId', NEW.driver_id,
            'driverName', v_driver_name,
            'driverEmail', v_driver_email,
            'amount', v_amount,
            'pushToken', v_admin_push_token
        ),
        NOW()
    );

    -- Log the notification for debugging
    RAISE NOTICE 'Invoice notification created: % - %', v_notification_title, v_notification_message;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the invoice creation
        RAISE NOTICE 'Error creating invoice notification: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Create trigger for invoice creation notifications
CREATE TRIGGER invoice_creation_notification_trigger
    AFTER INSERT ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION notify_admin_on_invoice_creation();

-- ============================================================================
-- 4. GRANT PERMISSIONS
-- ============================================================================

-- Grant execute permissions for all functions
GRANT EXECUTE ON FUNCTION notify_drivers_on_job_creation() TO authenticated;
GRANT EXECUTE ON FUNCTION should_notify_driver(JSONB, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION notify_admin_on_job_status_change() TO authenticated;
GRANT EXECUTE ON FUNCTION notify_admin_on_invoice_creation() TO authenticated;

-- Force PostgREST to reload its schema cache
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- 5. VERIFICATION
-- ============================================================================

-- Verify all triggers were created
DO $$ 
DECLARE
    trigger_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO trigger_count
    FROM information_schema.triggers 
    WHERE trigger_name IN (
        'job_creation_notification_trigger',
        'job_status_notification_trigger',
        'invoice_creation_notification_trigger'
    );

    IF trigger_count = 3 THEN
        RAISE NOTICE 'All notification triggers created successfully';
    ELSE
        RAISE NOTICE 'ERROR: Only % out of 3 triggers were created', trigger_count;
    END IF;
END $$; 