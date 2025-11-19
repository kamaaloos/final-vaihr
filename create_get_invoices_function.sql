-- Create the get_invoices_with_details function
-- This function returns invoices with detailed information including job and user data

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
        du.raw_user_meta_data->>'name' as driver_name,
        du.email as driver_email,
        au.raw_user_meta_data->>'name' as admin_name,
        au.email as admin_email
    FROM invoices i
    LEFT JOIN jobs j ON i.job_id = j.id
    LEFT JOIN auth.users du ON i.driver_id = du.id
    LEFT JOIN auth.users au ON i.admin_id = au.id
    WHERE 
        -- Allow admins to see all invoices
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND raw_user_meta_data->>'role' = 'admin'
        )
        OR
        -- Allow drivers to see their own invoices
        i.driver_id = auth.uid();
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_invoices_with_details() TO authenticated;

-- ==============================================
-- TEST THE FUNCTION (OPTIONAL)
-- ==============================================

-- Test the function (uncomment to test)
-- SELECT * FROM public.get_invoices_with_details();
