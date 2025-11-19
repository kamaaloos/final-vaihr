// Simple test to check Supabase connection
const SUPABASE_URL = process.env.EXPO_PUBLIC_SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

console.log('Testing Supabase connection...');
console.log('URL:', SUPABASE_URL);
console.log('Has Anon Key:', !!SUPABASE_ANON_KEY);

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    console.error('❌ Missing environment variables!');
    process.exit(1);
}

// Test basic connectivity
fetch(`${SUPABASE_URL}/rest/v1/`, {
    headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
    }
})
    .then(response => {
        if (response.ok) {
            console.log('✅ Supabase connection successful!');
        } else {
            console.log('❌ Supabase connection failed:', response.status, response.statusText);
        }
    })
    .catch(error => {
        console.error('❌ Network error:', error.message);
    });
