// Fix AuthProvider to use Edge Function for profile creation
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

        // Create user profile using Edge Function (bypasses RLS)
        console.log('🔍 SIGNUP DEBUG: Creating user profile via Edge Function...');
        const { data: profileData, error: profileError } = await supabase.functions.invoke('create-user-profile', {
            body: {
                userId: authData.user.id,
                email: email.toLowerCase().trim(),
                name: userData.name.trim(),
                role: userData.role
            }
        });

        console.log('🔍 SIGNUP DEBUG: Profile creation result:', { profileData, profileError });

        if (profileError) {
            console.error('Profile creation error:', profileError);
            throw new Error('Failed to create user profile');
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













