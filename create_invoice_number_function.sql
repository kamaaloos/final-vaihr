-- Create the generated_invoice_number function
-- This function generates a unique invoice number

CREATE OR REPLACE FUNCTION public.generated_invoice_number()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    date_part TEXT;
    random_part TEXT;
    new_invoice_number TEXT;
BEGIN
    -- Get current date in YYYYMM format
    date_part := to_char(CURRENT_DATE, 'YYYYMM');
    
    -- Generate a random 4-digit number
    random_part := lpad(floor(random() * 10000)::text, 4, '0');
    
    -- Combine to form invoice number
    new_invoice_number := 'INV-' || date_part || '-' || random_part;
    
    RETURN new_invoice_number;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.generated_invoice_number() TO authenticated;

-- ==============================================
-- FIX MISSING INVOICE_NUMBER COLUMN
-- ==============================================

-- Check if invoices table exists and has the required columns
DO $$
BEGIN
    -- Add invoice_number column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'invoices' 
        AND column_name = 'invoice_number'
    ) THEN
        ALTER TABLE invoices ADD COLUMN invoice_number TEXT;
    END IF;
    
    -- Add other missing columns if they don't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'invoices' 
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE invoices ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'invoices' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE invoices ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- ==============================================
-- UPDATE EXISTING INVOICES WITH GENERATED NUMBERS
-- ==============================================

-- Update existing invoices that don't have invoice_number
UPDATE invoices 
SET invoice_number = public.generated_invoice_number()
WHERE invoice_number IS NULL;

-- ==============================================
-- CREATE TRIGGER TO AUTO-GENERATE INVOICE NUMBERS
-- ==============================================

-- Create trigger function to auto-generate invoice numbers
CREATE OR REPLACE FUNCTION public.auto_generate_invoice_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Generate invoice number if not provided
    IF NEW.invoice_number IS NULL THEN
        NEW.invoice_number := public.generated_invoice_number();
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger to auto-generate invoice numbers on insert
DROP TRIGGER IF EXISTS auto_generate_invoice_number_trigger ON invoices;
CREATE TRIGGER auto_generate_invoice_number_trigger
    BEFORE INSERT ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_generate_invoice_number();

-- ==============================================
-- GRANT PERMISSIONS
-- ==============================================

-- Grant permissions on invoices table
GRANT SELECT, INSERT, UPDATE, DELETE ON invoices TO authenticated;

-- Check and grant sequence permissions if they exist
DO $$
DECLARE
    seq_name TEXT;
BEGIN
    -- Try to find the sequence for invoices table
    SELECT sequence_name INTO seq_name
    FROM information_schema.sequences 
    WHERE sequence_name LIKE '%invoices%' 
    OR sequence_name LIKE '%invoice%'
    LIMIT 1;
    
    IF seq_name IS NOT NULL THEN
        EXECUTE 'GRANT USAGE ON SEQUENCE ' || seq_name || ' TO authenticated';
        RAISE NOTICE 'Granted permissions on sequence: %', seq_name;
    ELSE
        RAISE NOTICE 'No sequence found for invoices table';
    END IF;
END $$;

-- ==============================================
-- TEST THE FUNCTION
-- ==============================================

-- Test the function (optional)
-- SELECT public.generated_invoice_number();
