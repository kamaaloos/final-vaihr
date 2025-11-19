-- Fix upsert_user_status function to match app's parameter order
-- Run this in your Supabase SQL Editor

-- Drop existing functions
DROP FUNCTION IF EXISTS public.upsert_user_status(uuid, boolean, text, text, text);
DROP FUNCTION IF EXISTS public.upsert_user_status_compat(uuid, boolean, text, text);

-- Create function that matches the app's parameter order
CREATE OR REPLACE FUNCTION public.upsert_user_status(
    p_is_online boolean,
    p_platform text DEFAULT NULL,
    p_platform_version text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Get the current user ID from auth.uid()
    INSERT INTO public.user_status (
        user_id,
        is_online,
        platform,
        platform_version,
        last_seen,
        updated_at
    )
    VALUES (
        auth.uid(),
        p_is_online,
        p_platform,
        p_platform_version,
        NOW(),
        NOW()
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        is_online = EXCLUDED.is_online,
        platform = EXCLUDED.platform,
        platform_version = EXCLUDED.platform_version,
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
        p_online,
        p_platform,
        p_platform_version
    );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.upsert_user_status TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_user_status_compat TO authenticated;

-- Test the function
SELECT public.upsert_user_status(true, 'mobile', '1.0.0');













