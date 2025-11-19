const { createClient } = require('@supabase/supabase-js');

// You'll need to add your Supabase URL and key here
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkOTPTable() {
    try {
        console.log('🔍 Checking if otp_codes table exists...');

        // Try to select from the table
        const { data, error } = await supabase
            .from('otp_codes')
            .select('*')
            .limit(1);

        if (error) {
            console.log('❌ Error accessing otp_codes table:', error.message);
            console.log('💡 The table might not exist or have permission issues');
        } else {
            console.log('✅ otp_codes table exists and is accessible');
            console.log('📊 Current records:', data.length);
        }

    } catch (err) {
        console.log('❌ Connection error:', err.message);
    }
}

checkOTPTable();
