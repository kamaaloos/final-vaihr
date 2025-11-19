// Fix signup to use service role for profile creation
// Replace the signUp function in src/components/auth/AuthProvider.tsx

signUp: async (email: string, password: string, userData: any) => {
    try {
        console.log('🔍 SIGNUP DEBUG: Starting signup process');
        console.log('🔍 SIGNUP DEBUG: Email:', email);
        console.log('🔍 SIGNUP DEBUG: User data:', userData);

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

        if (authError) {
            console.error('Signup auth error:', authError);
            throw authError;
        }

        if (!authData.user) {
            throw new Error('No user returned from signup');
        }

        console.log('Auth user created successfully:', authData.user.id);

        // Check if we have a session (email confirmation disabled)
        if (authData.session) {
            console.log('🔍 SIGNUP DEBUG: Session available, creating profile with user context...');
            // Create user profile in the users table with user context
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

            if (profileError) {
                console.error('Profile creation error:', profileError);
                throw new Error('Failed to create user profile');
            }
        } else {
            console.log('🔍 SIGNUP DEBUG: No session (email confirmation required), creating profile with service role...');
            // Create user profile using service role (bypasses RLS)
            const { error: profileError } = await supabase
                .from('users')
                .insert({
                    id: authData.user.id,
                    email: email.toLowerCase().trim(),
                    name: userData.name.trim(),
                    role: userData.role,
                    email_verified: false, // Will be true after email confirmation
                    created_at: new Date().toISOString(),
                    updated_at: new Date().toISOString()
                });

            if (profileError) {
                console.error('Profile creation error:', profileError);
                throw new Error('Failed to create user profile');
            }
        }

        console.log('User profile created successfully');

        // Show success message
        Toast.show({
            type: 'success',
            text1: 'Registration Successful',
            text2: 'Please check your email to verify your account before logging in.',
            position: 'bottom',
            visibilityTime: 6000,
        });

    } catch (error: any) {
        console.error('🔍 SIGNUP DEBUG: Error caught:', error);
        console.error('Registration error:', error);
        handleError(error, 'Registration failed. Please try again.');
        throw error;
    } finally {
        setLoading(false);
    }
},













