# Sync Chain Implementation Guide

This document provides a comprehensive guide for the peer-to-peer sync chain feature implementation in the Depass Flutter app.

## Overview

The sync chain feature allows users to synchronize their passwords across multiple devices using WebRTC for peer-to-peer communication. This eliminates the need for cloud storage while maintaining end-to-end encryption.

## Architecture

The implementation consists of several key components:

1. **Models** (`lib/models/sync_chain.dart`)
   - `SyncChain`: Represents a sync chain with metadata
   - `SyncMessage`: Messages exchanged between peers
   - `PeerConnection`: Information about connected devices
   - `SyncedPassword` & `SyncedNote`: Serializable password data

2. **Service** (`lib/services/sync_chain_service.dart`)
   - Core WebRTC functionality
   - Seed phrase generation using BIP39
   - Real-time password synchronization
   - Peer verification and management

3. **Provider** (`lib/providers/sync_aware_password_provider.dart`)
   - Extension of PasswordProvider with sync capabilities
   - Automatic sync on password changes

4. **UI Components**
   - Updated `backup_sync.dart` with sync chain option
   - Comprehensive `sync_chain_management.dart` screen

## Features Implemented

### 1. Sync Chain Creation
- Generate 16-word BIP39 seed phrase
- Create unique sync chain ID
- Set up WebRTC peer connection as owner
- Display seed phrase for sharing

### 2. Joining Existing Sync Chain
- Validate seed phrase input
- Connect to existing sync chain
- Request verification from owner
- Establish peer-to-peer connection

### 3. Peer Verification
- Owner can approve/reject new connections
- Visual indicators for pending verifications
- Device name and connection status display

### 4. Real-time Synchronization
- Automatic sync on password changes
- Bidirectional data flow
- Conflict resolution (newer timestamp wins)
- Heartbeat mechanism for connection monitoring

### 5. Sync Chain Management
- View current sync chain status
- List connected devices
- Manual sync trigger
- Disconnect/leave options

## User Flow

### Creating a Sync Chain:
1. Navigate to Backup & Sync
2. Tap "Sync Chain"
3. Select "Create New Sync Chain"
4. System generates 16-word seed phrase
5. User saves seed phrase securely
6. Sync chain is active and waiting for peers

### Joining a Sync Chain:
1. Navigate to Backup & Sync
2. Tap "Sync Chain"
3. Select "Join Existing Sync Chain"
4. Enter 16-word seed phrase
5. System connects to sync chain
6. Original device owner receives verification request
7. Owner approves/rejects the connection
8. If approved, passwords sync automatically

### Managing Sync Chain:
1. Navigate to Backup & Sync
2. Tap "Sync Chain" (shows current status)
3. Select "View Current Sync Chain"
4. Monitor connected devices
5. Perform manual sync or disconnect

## Security Features

1. **End-to-End Encryption**: All data is encrypted using the app's existing encryption
2. **BIP39 Seed Phrases**: Industry-standard mnemonic generation
3. **Peer Verification**: Manual approval required for new connections
4. **No Central Server**: Direct peer-to-peer communication
5. **Local Storage**: Sync chain metadata stored securely on device

## Technical Implementation Details

### WebRTC Configuration
- Uses Google's STUN servers for NAT traversal
- Data channels for password synchronization
- ICE candidate exchange for connection establishment

### Data Synchronization
- JSON-based message protocol
- Timestamp-based conflict resolution
- Incremental updates for efficiency
- Full sync on initial connection

### Storage
- Sync chain metadata in Flutter Secure Storage
- Device information from device_info_plus
- Integration with existing database service

## Required Dependencies

The following dependencies are added to `pubspec.yaml`:

```yaml
dependencies:
  flutter_webrtc: ^1.2.0  # Already included
  bip39: ^1.0.6           # Seed phrase generation
  device_info_plus: ^11.2.0  # Device identification
```

## Missing Components for Full Implementation

### 1. Signaling Server
You'll need to set up a signaling server for initial peer discovery and connection establishment. This can be a simple WebSocket server that facilitates the exchange of WebRTC offers/answers and ICE candidates.

Example signaling server setup:
```javascript
// Simple Node.js WebSocket signaling server
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

const rooms = new Map();

wss.on('connection', (ws) => {
  ws.on('message', (data) => {
    const message = JSON.parse(data);
    
    switch (message.type) {
      case 'join':
        // Add peer to room based on sync chain ID
        break;
      case 'offer':
      case 'answer':
      case 'ice-candidate':
        // Forward to other peers in room
        break;
    }
  });
});
```

### 2. Production Configuration
Update the signaling server URL in `sync_chain_service.dart`:
```dart
static const String signalingServerUrl = 'wss://your-signaling-server.com';
```

### 3. Platform Permissions
Add required permissions for WebRTC:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for WebRTC</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for WebRTC</string>
```

## Integration Instructions

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Update Provider Usage**:
   Replace `PasswordProvider` with `SyncAwarePasswordProvider` in your app's provider setup for automatic sync functionality.

3. **Initialize Sync Chain**:
   Call `initializeSyncChain()` in your app's initialization code.

4. **Test the Implementation**:
   - Create a sync chain on one device
   - Join from another device using the seed phrase
   - Verify password synchronization works bidirectionally

## Limitations and Considerations

1. **Network Requirements**: Devices must be able to establish P2P connections (may not work in some corporate networks)
2. **Battery Usage**: Maintaining WebRTC connections can impact battery life
3. **Concurrent Editing**: Current implementation uses timestamp-based conflict resolution
4. **Scalability**: Designed for personal use across a few devices
5. **Signaling Server**: Requires a separate server for initial connection establishment

## Future Enhancements

1. **Better Conflict Resolution**: Implement operational transforms for concurrent editing
2. **Offline Sync**: Queue changes for sync when connection is restored
3. **Group Management**: Support for family/team sync chains
4. **Backup Validation**: Verify data integrity across devices
5. **Performance Optimization**: Implement delta sync for large datasets

## Troubleshooting

### Common Issues:
1. **Connection Failed**: Check signaling server availability
2. **Sync Not Working**: Verify both devices are connected and verified
3. **Performance Issues**: Monitor for memory leaks in WebRTC connections
4. **Seed Phrase Invalid**: Ensure correct BIP39 format

### Debug Tools:
- Use Flutter logs to monitor sync chain events
- WebRTC stats for connection quality
- Network analysis for signaling issues

This implementation provides a solid foundation for peer-to-peer password synchronization while maintaining security and user privacy.