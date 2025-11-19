-- Fix invoices permissions and create a working version
-- This addresses the "permission denied for table users" error

-- ==============================================
-- GRANT PERMISSIONS ON AUTH.USERS TABLE
-- ==============================================

-- Grant permissions to access auth.users table
GRANT SELECT ON auth.users TO authenticated;

-- ==============================================
-- CREATE ALTERNATIVE FUNCTION WITHOUT AUTH.USERS
-- ==============================================

-- Create a simpler version that doesn't access auth.users directly
CREATE OR REPLACE FUNCTION public.get_invoices_with_details_simple()
RETURNS TABLE (
    id UUID,
    job_id UUID,
    driver_id UUID,
    admin_id UUID,
    amount DECIMAL(10,2),
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    invoice_number TEXT,
    job_title TEXT,
    job_description TEXT,
    job_location TEXT,
    job_date TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.job_id,
        i.driver_id,
        i.admin_id,
        i.amount,
        i.status,
        i.created_at,
        i.updated_at,
        i.invoice_number,
        j.title as job_title,
        j.description as job_description,
        j.location as job_location,
        j.date as job_date
    FROM invoices i
    LEFT JOIN jobs j ON i.job_id = j.id
    WHERE 
        -- Allow admins to see all invoices
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND role = 'admin'
        )
        OR
        -- Allow drivers to see their own invoices
        i.driver_id = auth.uid();
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_invoices_with_details_simple() TO authenticated;

-- ==============================================
-- UPDATE THE ORIGINAL FUNCTION TO USE USERS TABLE
-- ==============================================

-- Update the original function to use the users table instead of auth.users
CREATE OR REPLACE FUNCTION public.get_invoices_with_details()
RETURNS TABLE (
    id UUID,
    job_id UUID,
    driver_id UUID,
    admin_id UUID,
    amount DECIMAL(10,2),
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    invoice_number TEXT,
    job_title TEXT,
    job_description TEXT,
    job_location TEXT,
    job_date TIMESTAMP WITH TIME ZONE,
    driver_name TEXT,
    driver_email TEXT,
    admin_name TEXT,
    admin_email TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.job_id,
        i.driver_id,
        i.admin_id,
        i.amount,
        i.status,
        i.created_at,
        i.updated_at,
        i.invoice_number,
        j.title as job_title,
        j.description as job_description,
        j.location as job_location,
        j.date as job_date,
        du.name as driver_name,
        du.email as driver_email,
        au.name as admin_name,
        au.email as admin_email
    FROM invoices i
    LEFT JOIN jobs j ON i.job_id = j.id
    LEFT JOIN users du ON i.driver_id = du.id
    LEFT JOIN users au ON i.admin_id = au.id
    WHERE 
        -- Allow admins to see all invoices
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND role = 'admin'
        )
        OR
        -- Allow drivers to see their own invoices
        i.driver_id = auth.uid();
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_invoices_with_details() TO authenticated;

-- ==============================================
-- GRANT ALL NECESSARY PERMISSIONS
-- ==============================================

-- Grant permissions on all related tables
GRANT SELECT, INSERT, UPDATE, DELETE ON invoices TO authenticated;
GRANT SELECT ON jobs TO authenticated;
GRANT SELECT ON users TO authenticated;

-- ==============================================
-- TEST THE FUNCTIONS
-- ==============================================

-- Test the simple version (should work)
-- SELECT * FROM public.get_invoices_with_details_simple();

-- Test the full version (should work now)
-- SELECT * FROM public.get_invoices_with_details();
