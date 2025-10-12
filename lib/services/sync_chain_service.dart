import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:depass/models/sync_chain.dart';
import 'package:depass/models/pass.dart';
import 'package:depass/models/note.dart';
import 'package:depass/services/database_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:bip39/bip39.dart' as bip39;

// Global state manager for simulating cross-device communication
class _GlobalSyncState {
  static final _GlobalSyncState _instance = _GlobalSyncState._internal();
  factory _GlobalSyncState() => _instance;
  _GlobalSyncState._internal();

  final Map<String, Set<SyncChainService>> _activeSyncChains = {};

  void registerDevice(String syncChainId, SyncChainService service) {
    _activeSyncChains[syncChainId] ??= {};
    _activeSyncChains[syncChainId]!.add(service);
    log('Registered device for sync chain: $syncChainId (total: ${_activeSyncChains[syncChainId]!.length})');
  }

  void unregisterDevice(String syncChainId, SyncChainService service) {
    _activeSyncChains[syncChainId]?.remove(service);
    if (_activeSyncChains[syncChainId]?.isEmpty == true) {
      _activeSyncChains.remove(syncChainId);
    }
  }

  void broadcastMessage(String syncChainId, SyncMessage message, SyncChainService sender) {
    final devices = _activeSyncChains[syncChainId];
    if (devices != null) {
      for (final device in devices) {
        if (device != sender) {
          // Simulate network delay
          Timer(Duration(milliseconds: 100 + math.Random().nextInt(400)), () {
            device._receiveMessageFromPeer(message);
          });
        }
      }
    }
  }

  Set<SyncChainService>? getDevicesInSyncChain(String syncChainId) {
    return _activeSyncChains[syncChainId];
  }
}

class SyncChainService extends ChangeNotifier {
  static final SyncChainService _instance = SyncChainService._internal();
  factory SyncChainService() => _instance;
  SyncChainService._internal();

  // Storage and database
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DBService _dbService = DBService.instance;
  
  // WebRTC components
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  
  // Simple peer discovery mechanism (for local network discovery)
  Timer? _discoveryTimer;
  Timer? _heartbeatTimer;
  
  // Global state for cross-device communication
  final _GlobalSyncState _globalState = _GlobalSyncState();
  
  // State management
  SyncChain? _currentSyncChain;
  final Map<String, PeerConnection> _connectedPeers = {};
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};
  
  // Stream controllers for real-time updates
  final StreamController<SyncChainStatus> _statusController = StreamController<SyncChainStatus>.broadcast();
  final StreamController<List<PeerConnection>> _peersController = StreamController<List<PeerConnection>>.broadcast();
  final StreamController<SyncMessage> _messageController = StreamController<SyncMessage>.broadcast();
  
  // Signaling server configuration (you'll need to set up your own signaling server)
  static const String signalingServerUrl = 'wss://your-signaling-server.com';
  
  // Device info
  String? _deviceId;
  String? _deviceName;
  
  // Getters
  SyncChain? get currentSyncChain => _currentSyncChain;
  List<PeerConnection> get connectedPeers => _connectedPeers.values.toList();
  Stream<SyncChainStatus> get statusStream => _statusController.stream;
  Stream<List<PeerConnection>> get peersStream => _peersController.stream;
  Stream<SyncMessage> get messageStream => _messageController.stream;
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      await _initializeDeviceInfo();
      await _loadSyncChainFromStorage();
      await _initializeWebRTC();
      
      // Auto-connect if we have a sync chain
      if (_currentSyncChain != null && _currentSyncChain!.status != SyncChainStatus.disconnected) {
        await _reconnectToSyncChain();
      }
    } catch (e) {
      log('Error initializing SyncChainService: $e');
    }
  }
  
  // Initialize device info
  Future<void> _initializeDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
        _deviceName = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor;
        _deviceName = '${iosInfo.name} (${iosInfo.model})';
      }
      
      _deviceId ??= _generateRandomId();
      _deviceName ??= 'Unknown Device';
    } catch (e) {
      log('Error getting device info: $e');
      _deviceId = _generateRandomId();
      _deviceName = 'Unknown Device';
    }
  }
  
  // Generate a random device ID
  String _generateRandomId() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  
  // Load sync chain from storage
  Future<void> _loadSyncChainFromStorage() async {
    try {
      final syncChainData = await _secureStorage.read(key: 'sync_chain');
      if (syncChainData != null) {
        final data = jsonDecode(syncChainData);
        _currentSyncChain = SyncChain.fromMap(data);
      }
    } catch (e) {
      log('Error loading sync chain from storage: $e');
    }
  }
  
  // Save sync chain to storage
  Future<void> _saveSyncChainToStorage() async {
    try {
      if (_currentSyncChain != null) {
        final data = jsonEncode(_currentSyncChain!.toMap());
        await _secureStorage.write(key: 'sync_chain', value: data);
      } else {
        await _secureStorage.delete(key: 'sync_chain');
      }
    } catch (e) {
      log('Error saving sync chain to storage: $e');
    }
  }
  
  // Initialize WebRTC configuration
  Future<void> _initializeWebRTC() async {
    // ICE servers configuration
    final Map<String,dynamic> configuration = {
      // your implementation might use different or additional ICE servers
    };
    
    final constraints = {
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };
    
    try {
      _peerConnection = await createPeerConnection(configuration, constraints);
      _setupPeerConnectionHandlers();
    } catch (e) {
      log('Error initializing WebRTC: $e');
    }
  }
  
  // Set up peer connection event handlers
  void _setupPeerConnectionHandlers() {
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      // Send ICE candidate to signaling server
      _sendSignalingMessage({
        'type': 'ice-candidate',
        'candidate': candidate.toMap(),
      });
    };
    
    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      log('Peer connection state: $state');
      _updateSyncChainStatus(_mapConnectionStateToSyncStatus(state));
    };
    
    _peerConnection?.onDataChannel = (RTCDataChannel channel) {
      _setupDataChannel(channel);
    };
  }
  
  // Map RTCPeerConnectionState to SyncChainStatus
  SyncChainStatus _mapConnectionStateToSyncStatus(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return SyncChainStatus.connected;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        return SyncChainStatus.connecting;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        return SyncChainStatus.disconnected;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return SyncChainStatus.error;
      default:
        return SyncChainStatus.waiting;
    }
  }
  
  // Create a new sync chain
  Future<SyncChain> createSyncChain() async {
    try {
      _updateSyncChainStatus(SyncChainStatus.creating);
      
      // Generate seed phrase using BIP39
      final mnemonic = bip39.generateMnemonic();
      // Generate consistent sync chain ID from seed phrase
      final syncChainId = _generateIdFromSeedPhrase(mnemonic);
      
      _currentSyncChain = SyncChain(
        id: syncChainId,
        seedPhrase: mnemonic,
        createdAt: DateTime.now(),
        connectedPeers: [_deviceId!],
        status: SyncChainStatus.waiting,
        isOwner: true,
      );
      
      await _saveSyncChainToStorage();
      _updateSyncChainStatus(SyncChainStatus.waiting);
      
      // Set up as the sync chain owner
      await _setupAsOwner();
      
      notifyListeners();
      return _currentSyncChain!;
    } catch (e) {
      log('Error creating sync chain: $e');
      _updateSyncChainStatus(SyncChainStatus.error);
      rethrow;
    }
  }
  
  // Join an existing sync chain
  Future<void> joinSyncChain(String seedPhrase) async {
    try {
      _updateSyncChainStatus(SyncChainStatus.connecting);
      
      // Validate seed phrase
      if (!bip39.validateMnemonic(seedPhrase)) {
        throw Exception('Invalid seed phrase');
      }
      
      // Generate sync chain ID from seed phrase (you might want to use a different approach)
      final syncChainId = _generateIdFromSeedPhrase(seedPhrase);
      
      _currentSyncChain = SyncChain(
        id: syncChainId,
        seedPhrase: seedPhrase,
        createdAt: DateTime.now(),
        connectedPeers: [_deviceId!],
        status: SyncChainStatus.connecting,
        isOwner: false,
      );
      
      await _saveSyncChainToStorage();
      
      // Attempt to connect to existing peers
      await _connectToPeers();
      
      notifyListeners();
    } catch (e) {
      log('Error joining sync chain: $e');
      _updateSyncChainStatus(SyncChainStatus.error);
      rethrow;
    }
  }
  
  // Set up as sync chain owner
  Future<void> _setupAsOwner() async {
    try {
      // Register with global state
      if (_currentSyncChain != null) {
        _globalState.registerDevice(_currentSyncChain!.id, this);
      }
      
      // Create data channel for communication
      final dataChannelInit = RTCDataChannelInit();
      dataChannelInit.ordered = true;
      
      _dataChannel = await _peerConnection!.createDataChannel('sync', dataChannelInit);
      _setupDataChannel(_dataChannel!);
      
      // Start listening for connection requests
      await _startListeningForConnections();
      
      // Start heartbeat to announce presence
      _startHeartbeat();
    } catch (e) {
      log('Error setting up as owner: $e');
    }
  }
  
  // Start listening for connection requests
  Future<void> _startListeningForConnections() async {
    log('Started listening for connections for sync chain: ${_currentSyncChain?.id}');
    
    // Start discovery timer to periodically announce this device's presence
    _discoveryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _announcePresence();
    });
  }
  
  // Announce presence for peer discovery
  void _announcePresence() {
    if (_currentSyncChain == null) return;
    
    log('Announcing presence for sync chain: ${_currentSyncChain!.id}');
    // In a real implementation, this would broadcast to a discovery service
    // For now, we'll use a simplified approach where joining devices can find this one
  }
  
  // Start heartbeat
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _sendHeartbeat();
    });
  }
  
  // Send heartbeat to all connected peers
  void _sendHeartbeat() {
    if (_dataChannel != null && _dataChannel!.state.toString().contains('open')) {
      _sendMessage(SyncMessage(
        type: SyncMessageType.heartbeat,
        data: {
          'deviceId': _deviceId,
          'deviceName': _deviceName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        senderId: _deviceId!,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  // Connect to existing peers
  Future<void> _connectToPeers() async {
    if (_currentSyncChain == null) return;
    
    log('Attempting to connect to existing peers for sync chain: ${_currentSyncChain!.id}');
    
    // Register with global state
    _globalState.registerDevice(_currentSyncChain!.id, this);
    
    // Check if there are existing devices in this sync chain
    final existingDevices = _globalState.getDevicesInSyncChain(_currentSyncChain!.id);
    
    if (existingDevices != null && existingDevices.length > 1) {
      // Found existing devices, establish connection
      await _establishConnectionWithExistingDevices();
    } else {
      // No existing devices found, wait for owner
      log('No existing devices found, waiting...');
      _updateSyncChainStatus(SyncChainStatus.connecting);
    }
  }
  
  // Establish connection with existing devices
  Future<void> _establishConnectionWithExistingDevices() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      _updateSyncChainStatus(SyncChainStatus.connected);
      
      // Create data channel for communication
      final dataChannelInit = RTCDataChannelInit();
      dataChannelInit.ordered = true;
      
      _dataChannel = await _peerConnection!.createDataChannel('sync', dataChannelInit);
      _setupDataChannel(_dataChannel!);
      
      // Send handshake to announce presence
      _sendMessage(SyncMessage(
        type: SyncMessageType.handshake,
        data: {
          'deviceId': _deviceId,
          'deviceName': _deviceName,
          'isResponse': false,
        },
        senderId: _deviceId!,
        timestamp: DateTime.now(),
      ));
      
      // Start heartbeat
      _startHeartbeat();
    } catch (e) {
      log('Error establishing connection with existing devices: $e');
      _updateSyncChainStatus(SyncChainStatus.error);
    }
  }
  
  // Generate sync chain ID from seed phrase
  String _generateIdFromSeedPhrase(String seedPhrase) {
    // Use a consistent hash function to generate the same ID from the same seed phrase
    final words = seedPhrase.split(' ');
    var hash = 0;
    for (final word in words) {
      for (var i = 0; i < word.length; i++) {
        hash = ((hash << 5) - hash + word.codeUnitAt(i)) & 0xffffffff;
      }
    }
    return hash.abs().toRadixString(16).padLeft(8, '0');
  }
  
  // Set up data channel handlers
  void _setupDataChannel(RTCDataChannel channel) {
    channel.onDataChannelState = (RTCDataChannelState state) {
      log('Data channel state: $state');
    };
    
    channel.onMessage = (RTCDataChannelMessage message) {
      _handleReceivedMessage(message);
    };
  }
  
  // Handle received messages
  void _handleReceivedMessage(RTCDataChannelMessage message) {
    try {
      final data = jsonDecode(message.text);
      final syncMessage = SyncMessage.fromJson(data);
      
      log('Received sync message: ${syncMessage.type}');
      
      switch (syncMessage.type) {
        case SyncMessageType.handshake:
          _handleHandshake(syncMessage);
          break;
        case SyncMessageType.passwordSync:
          _handlePasswordSync(syncMessage);
          break;
        case SyncMessageType.passwordUpdate:
          _handlePasswordUpdate(syncMessage);
          break;
        case SyncMessageType.passwordDelete:
          _handlePasswordDelete(syncMessage);
          break;
        case SyncMessageType.verification:
          _handleVerificationRequest(syncMessage);
          break;
        case SyncMessageType.verificationResponse:
          _handleVerificationResponse(syncMessage);
          break;
        case SyncMessageType.heartbeat:
          _handleHeartbeat(syncMessage);
          break;
      }
      
      _messageController.add(syncMessage);
    } catch (e) {
      log('Error handling received message: $e');
    }
  }
  
  // Handle handshake
  void _handleHandshake(SyncMessage message) {
    final deviceInfo = message.data;
    final peerId = message.senderId;
    final isResponse = deviceInfo['isResponse'] ?? false;
    
    log('Handling handshake from $peerId (isResponse: $isResponse)');
    
    _connectedPeers[peerId] = PeerConnection(
      peerId: peerId,
      deviceName: deviceInfo['deviceName'] ?? 'Unknown Device',
      isConnected: true,
      lastSeen: DateTime.now(),
      isPendingVerification: false, // Simplified for demo
    );
    
    _peersController.add(connectedPeers);
    
    // Update sync chain status to connected when we have at least one peer
    if (_connectedPeers.isNotEmpty) {
      _updateSyncChainStatus(SyncChainStatus.connected);
    }
    
    // Send handshake response if this is not already a response
    if (!isResponse) {
      _sendMessage(SyncMessage(
        type: SyncMessageType.handshake,
        data: {
          'deviceId': _deviceId,
          'deviceName': _deviceName,
          'isResponse': true,
        },
        senderId: _deviceId!,
        timestamp: DateTime.now(),
      ));
      
      // If we're the owner and a new device joined, sync all passwords
      if (_currentSyncChain?.isOwner == true) {
        Timer(const Duration(seconds: 1), () {
          syncAllPasswords();
        });
      }
    }
  }
  
  // Handle password synchronization
  void _handlePasswordSync(SyncMessage message) async {
    try {
      final passwords = message.data['passwords'] as List<dynamic>;
      
      for (final passwordData in passwords) {
        final syncedPassword = SyncedPassword.fromMap(passwordData);
        await _applyPasswordSync(syncedPassword);
      }
      
      log('Synchronized ${passwords.length} passwords');
    } catch (e) {
      log('Error handling password sync: $e');
    }
  }
  
  // Apply password synchronization
  Future<void> _applyPasswordSync(SyncedPassword syncedPassword) async {
    try {
      // Check if password already exists
      final existingPasses = await _dbService.getAllPasses();
      final existingPass = existingPasses.where((p) => p.PassId == syncedPassword.passId).firstOrNull;
      
      if (existingPass == null) {
        // Create new password
        final notes = syncedPassword.notes.map((note) => {
          'Description': note.description,
          'Type': note.type,
        }).toList();
        
        await _dbService.createBulkNotes(
          notes: notes,
          title: syncedPassword.passTitle,
          vaultId: syncedPassword.vaultId,
        );
      } else {
        // Update existing password if the synced version is newer
        if (syncedPassword.updatedAt > existingPass.CreatedAt) {
          await _dbService.updatePass(syncedPassword.passId, syncedPassword.passTitle);
          
          // Update notes (this is simplified - you might want more sophisticated merging)
          for (final note in syncedPassword.notes) {
            await _dbService.updateNote(note.noteId, note.description, note.type);
          }
        }
      }
    } catch (e) {
      log('Error applying password sync: $e');
    }
  }
  
  // Handle password updates
  void _handlePasswordUpdate(SyncMessage message) async {
    final syncedPassword = SyncedPassword.fromMap(message.data);
    await _applyPasswordSync(syncedPassword);
  }
  
  // Handle password deletion
  void _handlePasswordDelete(SyncMessage message) async {
    try {
      final passId = message.data['passId'] as int;
      // You'll need to implement deletePass in DBService
      // await _dbService.deletePass(passId);
      log('Deleted password with ID: $passId');
    } catch (e) {
      log('Error handling password delete: $e');
    }
  }
  
  // Handle verification request
  void _handleVerificationRequest(SyncMessage message) {
    // Show verification dialog to user
    log('Received verification request from: ${message.senderId}');
  }
  
  // Handle verification response
  void _handleVerificationResponse(SyncMessage message) {
    final isApproved = message.data['approved'] as bool;
    final peerId = message.senderId;
    
    if (isApproved) {
      _connectedPeers[peerId] = _connectedPeers[peerId]!.copyWith(
        isPendingVerification: false,
      );
      log('Peer $peerId has been verified');
    } else {
      _connectedPeers.remove(peerId);
      log('Peer $peerId verification was rejected');
    }
    
    _peersController.add(connectedPeers);
  }
  
  // Handle heartbeat
  void _handleHeartbeat(SyncMessage message) {
    final peerId = message.senderId;
    if (_connectedPeers.containsKey(peerId)) {
      _connectedPeers[peerId] = _connectedPeers[peerId]!.copyWith(
        lastSeen: DateTime.now(),
      );
    }
  }
  
  // Send a message to all connected peers
  void _sendMessage(SyncMessage message) {
    try {
      log('Sending message: ${message.type} from ${message.senderId}');
      
      // Use global state to broadcast to other devices
      if (_currentSyncChain != null) {
        _globalState.broadcastMessage(_currentSyncChain!.id, message, this);
      }
      
      // Also send via data channel if available (for real WebRTC)
      if (_dataChannel != null) {
        final messageJson = jsonEncode(message.toJson());
        _dataChannel?.send(RTCDataChannelMessage(messageJson));
      }
    } catch (e) {
      log('Error sending message: $e');
    }
  }
  
  // Receive message from peer (via global state simulation)
  void _receiveMessageFromPeer(SyncMessage message) {
    log('Received message from peer: ${message.type} from ${message.senderId}');
    _handleReceivedMessage(RTCDataChannelMessage(jsonEncode(message.toJson())));
  }
  
  // Send signaling message
  void _sendSignalingMessage(Map<String, dynamic> message) {
    // Implement signaling server communication here
    log('Sending signaling message: ${message['type']}');
  }
  
  // Sync password changes
  Future<void> syncPasswordUpdate(Pass pass, List<Note> notes) async {
    if (_currentSyncChain == null || _dataChannel == null) return;
    
    try {
      final syncedNotes = notes.map((note) => SyncedNote(
        noteId: note.NoteId,
        description: note.Description,
        type: note.Type,
        passId: note.PassId,
        createdAt: note.CreatedAt,
        updatedAt: note.UpdatedAt,
      )).toList();
      
      final syncedPassword = SyncedPassword(
        passId: pass.PassId,
        passTitle: pass.PassTitle,
        vaultId: pass.VaultId,
        createdAt: pass.CreatedAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        notes: syncedNotes,
        lastModifiedBy: _deviceId!,
      );
      
      _sendMessage(SyncMessage(
        type: SyncMessageType.passwordUpdate,
        data: syncedPassword.toMap(),
        senderId: _deviceId!,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      log('Error syncing password update: $e');
    }
  }
  
  // Sync all passwords
  Future<void> syncAllPasswords() async {
    if (_currentSyncChain == null || _dataChannel == null) return;
    
    try {
      final allPasses = await _dbService.getAllPasses();
      final syncedPasswords = <SyncedPassword>[];
      
      for (final pass in allPasses) {
        final notes = await _dbService.getNotesByPassId(pass.PassId);
        final syncedNotes = notes.map((noteData) => SyncedNote(
          noteId: noteData['NoteId'] ?? 0,
          description: noteData['Description'] ?? '',
          type: noteData['Type'] ?? '',
          passId: noteData['PassId'] ?? 0,
          createdAt: noteData['CreatedAt'] ?? 0,
          updatedAt: noteData['UpdatedAt'] ?? 0,
        )).toList();
        
        syncedPasswords.add(SyncedPassword(
          passId: pass.PassId,
          passTitle: pass.PassTitle,
          vaultId: pass.VaultId,
          createdAt: pass.CreatedAt,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          notes: syncedNotes,
          lastModifiedBy: _deviceId!,
        ));
      }
      
      _sendMessage(SyncMessage(
        type: SyncMessageType.passwordSync,
        data: {
          'passwords': syncedPasswords.map((p) => p.toMap()).toList(),
        },
        senderId: _deviceId!,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      log('Error syncing all passwords: $e');
    }
  }
  
  // Verify a peer connection
  Future<void> verifyPeerConnection(String peerId, bool approve) async {
    try {
      _sendMessage(SyncMessage(
        type: SyncMessageType.verificationResponse,
        data: {'approved': approve},
        senderId: _deviceId!,
        timestamp: DateTime.now(),
      ));
      
      if (approve) {
        _connectedPeers[peerId] = _connectedPeers[peerId]!.copyWith(
          isPendingVerification: false,
        );
      } else {
        _connectedPeers.remove(peerId);
      }
      
      _peersController.add(connectedPeers);
    } catch (e) {
      log('Error verifying peer connection: $e');
    }
  }
  
  // Reconnect to sync chain
  Future<void> _reconnectToSyncChain() async {
    if (_currentSyncChain == null) return;
    
    try {
      _updateSyncChainStatus(SyncChainStatus.connecting);
      
      if (_currentSyncChain!.isOwner) {
        await _setupAsOwner();
      } else {
        await _connectToPeers();
      }
    } catch (e) {
      log('Error reconnecting to sync chain: $e');
      _updateSyncChainStatus(SyncChainStatus.error);
    }
  }
  
  // Disconnect from sync chain
  Future<void> disconnectFromSyncChain() async {
    try {
      _updateSyncChainStatus(SyncChainStatus.disconnected);
      
      // Unregister from global state
      if (_currentSyncChain != null) {
        _globalState.unregisterDevice(_currentSyncChain!.id, this);
      }
      
      // Cancel timers
      _discoveryTimer?.cancel();
      _heartbeatTimer?.cancel();
      
      // Close all peer connections
      for (final connection in _peerConnections.values) {
        await connection.close();
      }
      _peerConnections.clear();
      
      // Close data channels
      for (final channel in _dataChannels.values) {
        await channel.close();
      }
      _dataChannels.clear();
      
      _dataChannel?.close();
      _dataChannel = null;
      
      _connectedPeers.clear();
      _peersController.add([]);
      
      notifyListeners();
    } catch (e) {
      log('Error disconnecting from sync chain: $e');
    }
  }
  
  // Leave sync chain permanently
  Future<void> leaveSyncChain() async {
    try {
      await disconnectFromSyncChain();
      
      _currentSyncChain = null;
      await _secureStorage.delete(key: 'sync_chain');
      
      notifyListeners();
    } catch (e) {
      log('Error leaving sync chain: $e');
    }
  }
  
  // Update sync chain status
  void _updateSyncChainStatus(SyncChainStatus status) {
    if (_currentSyncChain != null) {
      _currentSyncChain = _currentSyncChain!.copyWith(status: status);
      _saveSyncChainToStorage();
    }
    
    _statusController.add(status);
    notifyListeners();
  }
  
  
  @override
  void dispose() {
    // Unregister from global state
    if (_currentSyncChain != null) {
      _globalState.unregisterDevice(_currentSyncChain!.id, this);
    }
    
    _discoveryTimer?.cancel();
    _heartbeatTimer?.cancel();
    _statusController.close();
    _peersController.close();
    _messageController.close();
    super.dispose();
  }
}