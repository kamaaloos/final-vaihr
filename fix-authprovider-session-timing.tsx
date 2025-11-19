// Fix AuthProvider to wait for session after signup
// Replace the signUp function in src/components/auth/AuthProvider.tsx

signUp: async (email: string, password: string, userData: any) => {
    try {
        console.log('🔍 SIGNUP DEBUG: Starting signup process');
        console.log('🔍 SIGNUP DEBUG: Email:', email);
        console.log('🔍 SIGNUP DEBUG: User data:', userData);
        console.log('🔍 SIGNUP DEBUG: Supabase client:', !!supabase);
        console.log('🔍 SIGNUP DEBUG: Supabase client initialized');

        setLoading(true);
        clearError();

        console.log('Starting signup process for:', email);

        // Create the user in Supabase Auth
        console.log('🔍 SIGNUP DEBUG: Calling supabase.auth.signUp...');
        const { data: authData, error: authError } = await supabase.auth.signUp({
            email: email.toLowerCase().trim(),
            password: password.trim(),
            options: {
                data: {
                    name: userData.name.trim(),
                    role: userData.role
                }
            }
        });

        console.log('🔍 SIGNUP DEBUG: Auth response:', { authData, authError });
        console.log('🔍 SIGNUP DEBUG: Auth error details:', authError?.message, authError?.status);

        if (authError) {
            console.error('Signup auth error:', authError);
            throw authError;
        }

        if (!authData.user) {
            throw new Error('No user returned from signup');
        }

        console.log('Auth user created successfully:', authData.user.id);

        // Wait for session to be established before creating profile
        console.log('🔍 SIGNUP DEBUG: Waiting for session to be established...');
        let sessionEstablished = false;
        let attempts = 0;
        const maxAttempts = 10;

        while (!sessionEstablished && attempts < maxAttempts) {
            const { data: { session } } = await supabase.auth.getSession();
            if (session && session.user.id === authData.user.id) {
                sessionEstablished = true;
                console.log('🔍 SIGNUP DEBUG: Session established successfully');
            } else {
                attempts++;
                console.log(`🔍 SIGNUP DEBUG: Waiting for session... attempt ${attempts}/${maxAttempts}`);
                await new Promise(resolve => setTimeout(resolve, 500)); // Wait 500ms
            }
        }

        if (!sessionEstablished) {
            console.log('🔍 SIGNUP DEBUG: Session not established, proceeding anyway...');
        }

        // Create user profile in the users table
        console.log('🔍 SIGNUP DEBUG: Creating user profile in database...');
        const { error: profileError } = await supabase
            .from('users')
            .insert({
                id: authData.user.id,
                email: email.toLowerCase().trim(),
                name: userData.name.trim(),
                role: userData.role,
                email_verified: userData.email_verified || false,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            });

        console.log('🔍 SIGNUP DEBUG: Profile creation result:', { profileError });

        if (profileError) {
            console.error('Profile creation error:', profileError);
            throw new Error('Failed to create user profile');
        }

        console.log('User profile created successfully');

        // Show success message only if not using OTP flow
        if (!userData.email_verified) {
            Toast.show({
                type: 'success',
                text1: 'Registration Successful',
                text2: 'Please check your email to verify your account before logging in.',
                position: 'bottom',
                visibilityTime: 6000,
            });
        }

    } catch (error: any) {
        console.error('🔍 SIGNUP DEBUG: Error caught:', error);
        console.error('🔍 SIGNUP DEBUG: Error type:', typeof error);
        console.error('🔍 SIGNUP DEBUG: Error message:', error?.message);
        console.error('🔍 SIGNUP DEBUG: Error stack:', error?.stack);
        console.error('Registration error:', error);
        console.error('Detailed error:', error?.message || 'Unknown error');
        handleError(error, 'Registration failed. Please try again.');
        throw error;
    } finally {
        setLoading(false);
    }
},













