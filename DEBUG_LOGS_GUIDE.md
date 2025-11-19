# Debug Logs Guide

## Recent Fixes Applied

### ✅ Fixed Infinite Loop Issues
1. **AuthProvider Initialization**: Now only logs "Initializing" once per session
2. **State Change Logging**: Only logs when state actually changes
3. **updateUserData Optimization**: Only updates when data is actually different
4. **DriverHomeScreen**: Prevents unnecessary user data fetching

### ✅ Online Status Verification
- Enhanced with retry logic and proper timing
- Should now work reliably without repeated attempts

## Expected Log Flow

### On App Start
```
AuthProvider: Initializing
AuthProvider: Starting auth initialization
AuthProvider: Getting session
AuthProvider: Session found, fetching user data
AuthProvider: User data fetched successfully
AuthProvider: Setting merged user data: {...}
AuthProvider: Initialization complete
AuthProvider: Current state: {"hasUser": true, "hasUserData": true, "loading": false, "hasError": false}
```

### On Login
```
OnlineStatusManager: Setting user online for user: [user-id]
OnlineStatusManager: Database operation result: [success]
OnlineStatusManager: Verification attempt 1 result: [data]
OnlineStatusManager: User set online successfully
OnlineStatusManager: Heartbeat started
```

### On Logout
```
OnlineStatusManager: Setting user offline
OnlineStatusManager: User set offline successfully
AuthProvider: User signed out, cleaning up
AuthProvider: Cleaning up online status on sign out
```

## What to Look For

### ✅ Good Signs
- AuthProvider only initializes once
- Online status verification succeeds (even if it takes 1-2 attempts)
- No repeated "Updating user data" logs
- Clean logout process

### ❌ Problem Signs
- Repeated "AuthProvider: Initializing" logs
- Multiple "Updating user data" logs with same data
- Online status verification failing repeatedly
- Infinite loops in any component

## Console Filtering Tips

### To Focus on Auth Issues
```
AuthProvider
```

### To Focus on Online Status
```
OnlineStatusManager
```

### To Hide Verbose Logs
```
- Updating user data
- AuthProvider: Current state
```

## Testing Checklist

1. **App Start**: Should see initialization logs only once
2. **Login**: Should see online status setup logs
3. **Navigation**: Should work smoothly without repeated logs
4. **Logout**: Should see cleanup logs and navigation to Welcome
5. **Re-login**: Should work without repeated initialization

## If You Still See Issues

1. **Clear app cache/storage** and restart
2. **Check for multiple AuthProvider instances** in your app
3. **Verify no circular dependencies** in your component tree
4. **Monitor for memory leaks** with repeated component mounts

## Quick Debug Commands

### Check Current Online Status
```sql
SELECT 
    u.id, u.name, u.online as users_online,
    us.is_online as status_online, us.last_seen
FROM users u
LEFT JOIN user_status us ON u.id = us.user_id::text
WHERE u.id = 'your-user-id';
```

### Check for Multiple Sessions
```sql
SELECT COUNT(*) as active_sessions 
FROM auth.sessions 
WHERE user_id = 'your-user-id';
```

The logs should now be much cleaner and more informative! 