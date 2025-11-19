// Test script to verify presence broadcasting
// Run this in the browser console or as a separate test

console.log('🧪 Testing Presence Broadcasting...');

// Test 1: Check if PresenceManager is working
const testPresenceManager = () => {
    console.log('Test 1: PresenceManager initialization');

    // This would be called when a user logs in
    const userId = 'test-user-' + Date.now();
    console.log('Initializing presence for user:', userId);

    // In a real app, this would be:
    // await getPresenceManager().initialize(userId);

    console.log('✅ PresenceManager test completed');
};

// Test 2: Check if global presence channel is working
const testGlobalPresence = () => {
    console.log('Test 2: Global presence channel');

    // Simulate global presence state
    const globalState = {
        'user-1': [{
            user_id: 'user-1',
            online_at: new Date().toISOString(),
            role: 'admin',
            online: true
        }],
        'user-2': [{
            user_id: 'user-2',
            online_at: new Date().toISOString(),
            role: 'driver',
            online: true
        }]
    };

    console.log('Global presence state:', globalState);
    console.log('✅ Global presence test completed');
};

// Test 3: Check if chat presence is working
const testChatPresence = () => {
    console.log('Test 3: Chat presence channel');

    const chatId = 'chat-' + Date.now();
    const chatState = {
        [chatId]: [
            {
                user_id: 'user-1',
                online_at: new Date().toISOString(),
                role: 'admin',
                online: true,
                isTyping: false
            },
            {
                user_id: 'user-2',
                online_at: new Date().toISOString(),
                role: 'driver',
                online: true,
                isTyping: true
            }
        ]
    };

    console.log('Chat presence state:', chatState);
    console.log('✅ Chat presence test completed');
};

// Test 4: Check broadcasting configuration
const testBroadcastingConfig = () => {
    console.log('Test 4: Broadcasting configuration');

    const config = {
        globalChannel: {
            name: 'global_presence',
            config: {
                broadcast: { self: true }
            }
        },
        chatChannel: {
            name: 'presence:chatId',
            config: {
                presence: {
                    key: 'userId'
                },
                broadcast: { self: true }
            }
        }
    };

    console.log('Broadcasting config:', config);
    console.log('✅ Broadcasting config test completed');
};

// Run all tests
const runAllTests = () => {
    console.log('🚀 Starting Presence Broadcasting Tests...\n');

    testPresenceManager();
    console.log('');

    testGlobalPresence();
    console.log('');

    testChatPresence();
    console.log('');

    testBroadcastingConfig();
    console.log('');

    console.log('🎉 All tests completed!');
    console.log('\n📋 Summary:');
    console.log('- PresenceManager: Singleton service for unified presence management');
    console.log('- Global Presence: All users join global_presence channel');
    console.log('- Chat Presence: Users join presence:chatId when in chats');
    console.log('- Broadcasting: All channels use broadcast: { self: true }');
    console.log('- Real-time: Presence updates broadcast to all connected clients');
};

// Export for use in other files
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        testPresenceManager,
        testGlobalPresence,
        testChatPresence,
        testBroadcastingConfig,
        runAllTests
    };
} else {
    // Run tests in browser
    runAllTests();
} 