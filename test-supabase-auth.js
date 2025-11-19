// Simple test to check Supabase auth
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

console.log('Testing Supabase Auth...');
console.log('URL:', supabaseUrl);
console.log('Has Anon Key:', !!supabaseAnonKey);

if (!supabaseUrl || !supabaseAnonKey) {
    console.error('❌ Missing environment variables!');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Test auth signup
async function testSignup() {
    try {
        console.log('Testing auth signup...');
        const { data, error } = await supabase.auth.signUp({
            email: 'test@example.com',
            password: 'testpassword123'
        });

        if (error) {
            console.error('❌ Signup error:', error.message);
        } else {
            console.log('✅ Signup successful!');
        }
    } catch (err) {
        console.error('❌ Signup failed:', err.message);
    }
}

testSignup();
