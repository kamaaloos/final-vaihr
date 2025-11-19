# Presence Broadcasting Fix

## Problem Summary
The presence state was not syncing to all clients due to:
1. Multiple inconsistent presence channels (`online_users`, `presence:${chatId}`, etc.)
2. Missing `broadcast: { self: true }` configuration on some channels
3. Isolated presence management across different screens
4. No unified presence broadcasting system
5. **NEW**: Infinite re-renders caused by non-memoized functions in hooks

## Solution Implemented

### 1. Unified PresenceManager Service
Created `src/services/PresenceManager.ts` - a singleton service that:
- Manages a global presence channel (`global_presence`) with `broadcast: { self: true }`
- Handles chat-specific presence channels with consistent configuration
- Provides centralized presence tracking and broadcasting
- Ensures all presence updates are broadcast to all connected clients

### 2. Updated OnlineStatusManager
Modified `src/services/OnlineStatusManager.ts` to:
- Initialize the PresenceManager when setting up online status
- Integrate with the unified presence system
- Ensure consistent presence broadcasting across the app

### 3. Optimized useUnifiedPresence Hook
Created `src/hooks/useUnifiedPresence.ts` that provides:
- **Memoized functions** to prevent infinite re-renders
- Easy access to global and chat-specific presence states
- Helper functions for checking online/typing status
- Automatic presence monitoring with configurable intervals
- Clean API for presence management

### 4. Updated Components with Performance Optimizations
Modified key components to use the unified system:
- `ChatListScreen.tsx` - Uses unified presence for chat list online status
- `ChatContext.tsx` - Uses unified presence for chat-specific features with memoization
- `DriversListScreen.tsx` - Uses unified presence for driver online status with memoization

## Key Features

### Global Presence Channel
- All users join `global_presence` channel on login
- Broadcasts presence updates to all connected clients
- Used for general online status across the app

### Chat-Specific Presence Channels
- Users join `presence:${chatId}` when entering a chat
- Handles typing indicators and chat-specific presence
- Automatically leaves when exiting chat

### Consistent Broadcasting
- All channels use `broadcast: { self: true }` configuration
- Ensures presence updates are sent to all clients, including sender
- Prevents presence state fragmentation

### Performance Optimizations
- **Memoized functions** in `useUnifiedPresence` hook prevent infinite re-renders
- **useMemo** for expensive computations like filtering and status updates
- **useCallback** for stable function references
- **Optimized re-renders** by only updating state when values actually change

## Testing the Fix

### 1. Basic Online Status Test
1. Login with two different users (admin and driver)
2. Check that both users appear online in their respective lists
3. Verify online status updates in real-time

### 2. Chat Presence Test
1. Open a chat between two users
2. Check that typing indicators work
3. Verify presence updates when users join/leave chat

### 3. Cross-Screen Presence Test
1. Login with multiple users
2. Navigate between different screens (ChatList, DriversList, etc.)
3. Verify presence status remains consistent across all screens

### 4. Network Disconnect Test
1. Disconnect one user's network
2. Verify other users see the offline status
3. Reconnect and verify online status is restored

### 5. Performance Test
1. Check console for "Maximum update depth exceeded" errors
2. Verify no infinite re-renders occur
3. Monitor memory usage and performance

## Logging and Debugging

The system includes comprehensive logging:
- `PresenceManager: Global presence sync` - Shows global presence updates
- `PresenceManager: Chat presence sync` - Shows chat-specific updates
- `OnlineStatusManager: Status changed` - Shows database status changes
- `useUnifiedPresence: Memoized update` - Shows when memoization prevents re-renders

## Configuration

### Presence Check Intervals
- Global presence: 3 seconds
- Chat presence: 2 seconds
- Online status threshold: 30 seconds

### Channel Configuration
- Global channel: `global_presence`
- Chat channels: `presence:${chatId}`
- All channels use `broadcast: { self: true }`

### Performance Settings
- Function memoization: Enabled for all presence functions
- State updates: Only when values actually change
- Re-render optimization: useMemo for expensive computations

## Benefits

1. **Consistent Broadcasting**: All presence updates are broadcast to all clients
2. **Reduced Fragmentation**: Single source of truth for presence management
3. **Better Performance**: Optimized presence checking intervals and memoization
4. **Easier Maintenance**: Centralized presence logic
5. **Real-time Updates**: Immediate presence state synchronization
6. **No Infinite Re-renders**: Memoized functions prevent performance issues

## Migration Notes

- Existing presence channels are automatically replaced
- No breaking changes to existing APIs
- Backward compatible with existing database structure
- Gradual migration as components are updated
- Performance optimizations are automatically applied

## Future Improvements

1. **Presence Analytics**: Track presence patterns and usage
2. **Optimized Intervals**: Dynamic presence check intervals based on activity
3. **Presence History**: Store and retrieve presence history
4. **Advanced Filtering**: Filter presence by user roles or groups
5. **WebSocket Optimization**: Implement connection pooling for better performance

## Troubleshooting

### Infinite Re-renders
If you see "Maximum update depth exceeded" errors:
1. Check that all functions in `useUnifiedPresence` are properly memoized
2. Verify that component dependencies are stable
3. Use React DevTools to identify unnecessary re-renders

### Presence Not Syncing
If presence is not syncing between clients:
1. Check that `broadcast: { self: true }` is configured on all channels
2. Verify that PresenceManager is properly initialized
3. Check network connectivity and Supabase real-time subscriptions

### Performance Issues
If performance is poor:
1. Monitor presence check intervals (should be 2-3 seconds)
2. Check for memory leaks in presence channels
3. Verify that memoization is working correctly 