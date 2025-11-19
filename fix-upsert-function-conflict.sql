-- Fix upsert_user_status function conflict
-- Run this in your Supabase SQL Editor

-- Drop existing function with all possible signatures
DROP FUNCTION IF EXISTS public.upsert_user_status(uuid, boolean, text, text, text);
DROP FUNCTION IF EXISTS public.upsert_user_status(uuid, boolean, text);
DROP FUNCTION IF EXISTS public.upsert_user_status(uuid, boolean);
DROP FUNCTION IF EXISTS public.upsert_user_status_compat(uuid, boolean, text, text);
DROP FUNCTION IF EXISTS public.upsert_user_status_compat(uuid, boolean, text);
DROP FUNCTION IF EXISTS public.upsert_user_status_compat(uuid, boolean);

-- Create the new upsert_user_status function with permission checks
CREATE OR REPLACE FUNCTION public.upsert_user_status(
    p_user_id uuid,
    p_is_online boolean,
    p_platform text DEFAULT NULL,
    p_platform_version text DEFAULT NULL,
    p_device_token text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if user has permission (admin or self)
    IF NOT (
        -- Is admin
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE id = auth.uid() 
            AND raw_user_meta_data->>'role' = 'admin'
        )
        -- Or is self
        OR auth.uid() = p_user_id
    ) THEN
        RAISE EXCEPTION 'Permission denied: Only admins can update other users status';
    END IF;

    -- Update the user_status table
    INSERT INTO public.user_status (
        user_id,
        is_online,
        platform,
        platform_version,
        device_token,
        last_seen,
        updated_at
    ) VALUES (
        p_user_id,
        p_is_online,
        p_platform,
        p_platform_version,
        p_device_token,
        NOW(),
        NOW()
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        is_online = EXCLUDED.is_online,
        platform = EXCLUDED.platform,
        platform_version = EXCLUDED.platform_version,
        device_token = EXCLUDED.device_token,
        last_seen = NOW(),
        updated_at = NOW();

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in upsert_user_status: %', SQLERRM;
        RAISE;
END;
$$;

-- Create compatible version for backward compatibility
CREATE OR REPLACE FUNCTION public.upsert_user_status_compat(
    p_user_id uuid,
    p_online boolean,
    p_platform text DEFAULT NULL,
    p_platform_version text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Call the main function with p_is_online parameter
    PERFORM public.upsert_user_status(
        p_user_id,
        p_online,
        p_platform,
        p_platform_version,
        NULL
    );
END;
$$;

-- Grant execute permissions on RPC functions
GRANT EXECUTE ON FUNCTION public.upsert_user_status TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_user_status_compat TO authenticated;













