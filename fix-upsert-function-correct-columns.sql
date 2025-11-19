-- Fix upsert_user_status function with correct columns
-- Run this in your Supabase SQL Editor

-- Drop existing functions
DROP FUNCTION IF EXISTS public.upsert_user_status(boolean, text, text);
DROP FUNCTION IF EXISTS public.upsert_user_status_compat(boolean, text, text);

-- Create function with only existing columns
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
    -- Insert/update with only existing columns
    INSERT INTO public.user_status (
        user_id,
        is_online,
        platform,
        last_seen,
        updated_at
    )
    VALUES (
        auth.uid(),
        p_is_online,
        p_platform,
        NOW(),
        NOW()
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        is_online = EXCLUDED.is_online,
        platform = EXCLUDED.platform,
        last_seen = NOW(),
        updated_at = NOW();

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in upsert_user_status: %', SQLERRM;
        RAISE;
END;
$$;

-- Create compatible version
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
    -- Call the main function
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













