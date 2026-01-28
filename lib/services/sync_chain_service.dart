import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip39/src/wordlists/english.dart' as bip39_wordlist;
import 'package:crypto/crypto.dart';
import 'package:depass/models/sync_chain.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/services/notification_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

/// Callback types for sync chain events
typedef OnDeviceConnected = void Function(SyncChainDevice device);
typedef OnDeviceDisconnected = void Function(String deviceId);
typedef OnSyncMessageReceived = void Function(SyncMessage message);
typedef OnStatusChanged = void Function(SyncChainStatus status);
typedef OnError = void Function(String error);

/// Service for managing P2P sync chain connections using Nearby Connections
class SyncChainService {
  static final SyncChainService _instance = SyncChainService._internal();
  factory SyncChainService() => _instance;
  SyncChainService._internal();

  // Service identifier for nearby connections
  static const String _serviceId = 'com.abdulraufdev.depass.syncchain';

  // Storage keys
  static const String _chainIdKey = 'sync_chain_id';
  static const String _seedPhraseKey = 'sync_chain_seed_phrase';
  static const String _deviceIdKey = 'sync_chain_device_id';
  static const String _deviceNameKey = 'sync_chain_device_name';
  static const String _chainActiveKey = 'sync_chain_active';

  // Secure storage instance
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Nearby connections instance
  final Nearby _nearby = Nearby();

  // Database service instance
  final DBService _dbService = DBService.instance;

  // Current device information
  String? _deviceId;
  String? _deviceName;
  String? _chainId;
  String? _seedPhrase;

  // Connection state
  SyncChainStatus _status = SyncChainStatus.disconnected;
  final Map<String, SyncChainDevice> _connectedDevices = {};
  final Map<String, String> _endpointToDeviceId = {};
  final Map<String, String> _deviceIdToEndpoint = {};
  final Set<String> _pendingConnections = {};

  // Discovery state
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  bool _isForegroundServiceRunning = false;
  bool _useClusterStrategy = false; // Fallback strategy flag
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  // Message queue for retry
  final Map<String, List<_PendingMessage>> _messageQueues = {};

  // Callbacks
  OnDeviceConnected? onDeviceConnected;
  OnDeviceDisconnected? onDeviceDisconnected;
  OnSyncMessageReceived? onSyncMessageReceived;
  OnStatusChanged? onStatusChanged;
  OnError? onError;

  // Getters
  SyncChainStatus get status => _status;
  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;
  String? get chainId => _chainId;
  String? get seedPhrase => _seedPhrase;
  List<SyncChainDevice> get connectedDevices =>
      _connectedDevices.values.toList();
  bool get isChainActive => _chainId != null && _seedPhrase != null;

  /// Initialize the sync chain service
  Future<void> initialize() async {
    log('SyncChainService: Initializing...');

    // Load saved device info
    _deviceId = await _secureStorage.read(key: _deviceIdKey);
    _deviceName = await _secureStorage.read(key: _deviceNameKey);
    _chainId = await _secureStorage.read(key: _chainIdKey);
    _seedPhrase = await _secureStorage.read(key: _seedPhraseKey);

    // Generate device ID if not exists
    if (_deviceId == null) {
      _deviceId = _generateDeviceId();
      await _secureStorage.write(key: _deviceIdKey, value: _deviceId);
    }

    // Get device name if not exists
    if (_deviceName == null) {
      _deviceName = await _getDeviceName();
      await _secureStorage.write(key: _deviceNameKey, value: _deviceName);
    }

    log(
      'SyncChainService: Initialized - deviceId: $_deviceId, chainActive: $isChainActive',
    );
  }

  /// Generate a unique device ID
  String _generateDeviceId() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Get device name from device info
  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      }
    } catch (e) {
      log('Error getting device name: $e');
    }
    return 'Unknown Device';
  }

  /// Generate an 8-word seed phrase using BIP39
  String generateSeedPhrase() {
    final mnemonic = bip39.generateMnemonic(strength: 128);
    final words = mnemonic.split(' ');
    return words.take(8).join(' ');
  }

  /// Derive chain ID from seed phrase
  String _deriveChainId(String seedPhrase) {
    final bytes = utf8.encode(seedPhrase + _serviceId);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 16);
  }

  /// Get the username for nearby connections (includes chain ID for matching)
  String get _nearbyUsername => '${_deviceName ?? 'Device'}_${_chainId ?? ''}';

  /// Validate seed phrase format (8 BIP39 words)
  bool validateSeedPhrase(String seedPhrase) {
    final words = seedPhrase.trim().toLowerCase().split(RegExp(r'\s+'));
    if (words.length != 8) {
      log(
        'Seed phrase validation failed: expected 8 words, got ${words.length}',
      );
      return false;
    }

    final wordList = bip39_wordlist.WORDLIST;
    for (final word in words) {
      if (!wordList.contains(word)) {
        log('Seed phrase validation failed: "$word" is not a valid BIP39 word');
        return false;
      }
    }

    log('Seed phrase validation passed');
    return true;
  }

  /// Create a new sync chain
  Future<SyncChain> createSyncChain() async {
    log('SyncChainService: Creating new sync chain...');

    _seedPhrase = generateSeedPhrase();
    _chainId = _deriveChainId(_seedPhrase!);

    await _secureStorage.write(key: _seedPhraseKey, value: _seedPhrase);
    await _secureStorage.write(key: _chainIdKey, value: _chainId);
    await _secureStorage.write(key: _chainActiveKey, value: 'true');

    final syncChain = SyncChain(
      chainId: _chainId!,
      seedPhrase: _seedPhrase!,
      createdAt: DateTime.now(),
      connectedDevices: [
        SyncChainDevice(
          deviceId: _deviceId!,
          deviceName: _deviceName!,
          connectedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
        ),
      ],
      isActive: true,
    );

    log('SyncChainService: Sync chain created with ID: $_chainId');
    return syncChain;
  }

  /// Join an existing sync chain with seed phrase
  Future<bool> joinSyncChain(String seedPhrase) async {
    log('SyncChainService: Attempting to join sync chain');

    if (!validateSeedPhrase(seedPhrase)) {
      onError?.call(
        'Invalid seed phrase format. Please enter 8 valid BIP39 words.',
      );
      return false;
    }

    _seedPhrase = seedPhrase.trim().toLowerCase();
    _chainId = _deriveChainId(_seedPhrase!);

    await _secureStorage.write(key: _seedPhraseKey, value: _seedPhrase);
    await _secureStorage.write(key: _chainIdKey, value: _chainId);
    await _secureStorage.write(key: _chainActiveKey, value: 'true');

    log('SyncChainService: Joined sync chain with ID: $_chainId');
    return true;
  }

  /// Start the sync chain (advertising and discovering)
  Future<bool> startSyncChain() async {
    log('SyncChainService: ========== STARTING SYNC CHAIN ==========');
    log('SyncChainService: Chain ID: $_chainId');
    log('SyncChainService: Device Name: $_deviceName');
    log('SyncChainService: Username: $_nearbyUsername');

    if (_chainId == null || _deviceName == null) {
      onError?.call('Sync chain not initialized');
      return false;
    }

    _setStatus(SyncChainStatus.discovering);

    // Start foreground service for persistent background connection
    await _startForegroundService();

    // Start both advertising and discovering
    await _startAdvertising();
    await _startDiscovery();

    // Start heartbeat timer
    _startHeartbeat();

    log('SyncChainService: ========== SYNC CHAIN STARTED ==========');
    return true;
  }

  /// Start advertising this device
  Future<void> _startAdvertising() async {
    if (_isAdvertising) {
      log('SyncChainService: Already advertising');
      return;
    }

    final strategy = _useClusterStrategy
        ? Strategy.P2P_CLUSTER
        : Strategy.P2P_STAR;
    log(
      'SyncChainService: Starting advertising as: $_nearbyUsername (strategy: $strategy)',
    );

    try {
      final success = await _nearby.startAdvertising(
        _nearbyUsername,
        strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );

      _isAdvertising = success;
      log('SyncChainService: Advertising started: $success');
    } catch (e) {
      log('SyncChainService: Error starting advertising: $e');
      onError?.call('Failed to start advertising: $e');
    }
  }

  /// Start discovering other devices
  Future<void> _startDiscovery() async {
    if (_isDiscovering) {
      log('SyncChainService: Already discovering');
      return;
    }

    final strategy = _useClusterStrategy
        ? Strategy.P2P_CLUSTER
        : Strategy.P2P_STAR;
    log('SyncChainService: Starting discovery... (strategy: $strategy)');

    try {
      final success = await _nearby.startDiscovery(
        _nearbyUsername,
        strategy,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: _serviceId,
      );

      _isDiscovering = success;
      log('SyncChainService: Discovery started: $success');
    } catch (e) {
      log('SyncChainService: Error starting discovery: $e');
      onError?.call('Failed to start discovery: $e');
    }
  }

  /// Handle endpoint found during discovery
  void _onEndpointFound(
    String endpointId,
    String endpointName,
    String serviceId,
  ) {
    log(
      'SyncChainService: Endpoint found - id: $endpointId, name: $endpointName',
    );

    // Parse the endpoint name to get device name and chain ID
    // Format: DeviceName_ChainId
    final parts = endpointName.split('_');
    if (parts.length < 2) {
      log('SyncChainService: Invalid endpoint name format');
      return;
    }

    final remoteChainId = parts.last;
    final remoteDeviceName = parts.sublist(0, parts.length - 1).join('_');

    // Only connect to devices with matching chain ID
    if (remoteChainId == _chainId) {
      log('SyncChainService: Chain ID matches!');

      // Avoid duplicate connection attempts
      if (_pendingConnections.contains(endpointId) ||
          _endpointToDeviceId.containsKey(endpointId)) {
        log('SyncChainService: Connection already pending or established');
        return;
      }

      // CONNECTION ARBITRATION:
      // To prevent both devices from requesting connection simultaneously,
      // only the device with the lexicographically SMALLER device name initiates.
      // The other device waits to accept the incoming connection.
      final myName = _deviceName ?? '';
      final shouldInitiate = myName.compareTo(remoteDeviceName) < 0;

      log(
        'SyncChainService: My name: "$myName", Remote name: "$remoteDeviceName"',
      );
      log('SyncChainService: Should I initiate? $shouldInitiate');

      if (shouldInitiate) {
        log('SyncChainService: I will initiate the connection');
        _pendingConnections.add(endpointId);
        _requestConnection(endpointId);
      } else {
        log(
          'SyncChainService: Waiting for remote device to initiate connection',
        );
        // Don't request - wait for the other device to connect to us
        // We're advertising, so they will find us and connect
      }
    } else {
      log(
        'SyncChainService: Chain ID mismatch - ignoring (remote: $remoteChainId, local: $_chainId)',
      );
    }
  }

  /// Handle endpoint lost
  void _onEndpointLost(String? endpointId) {
    log('SyncChainService: Endpoint lost: $endpointId');
    if (endpointId != null) {
      _pendingConnections.remove(endpointId);
      _connectionRetryCount.remove(endpointId);
    }
  }

  // Track connection retry attempts
  final Map<String, int> _connectionRetryCount = {};
  static const int _maxConnectionRetries = 3;

  /// Request connection to an endpoint with retry logic
  Future<void> _requestConnection(
    String endpointId, {
    int retryDelay = 0,
  }) async {
    // Add delay if retrying
    if (retryDelay > 0) {
      log('SyncChainService: Waiting ${retryDelay}ms before retry...');
      await Future.delayed(Duration(milliseconds: retryDelay));
    }

    // Check if still valid to connect
    if (!_pendingConnections.contains(endpointId)) {
      log('SyncChainService: Connection cancelled for $endpointId');
      return;
    }

    final retryCount = _connectionRetryCount[endpointId] ?? 0;
    log(
      'SyncChainService: Requesting connection to: $endpointId (attempt ${retryCount + 1}/$_maxConnectionRetries)',
    );
    _setStatus(SyncChainStatus.connecting);

    try {
      await _nearby.requestConnection(
        _nearbyUsername,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      log('SyncChainService: Error requesting connection: $e');

      // Check if we should retry
      final isRetryableError =
          e.toString().contains('STATUS_ENDPOINT_IO_ERROR') ||
          e.toString().contains('STATUS_RADIO_ERROR') ||
          e.toString().contains('8012') ||
          e.toString().contains('8007');

      if (isRetryableError && retryCount < _maxConnectionRetries - 1) {
        _connectionRetryCount[endpointId] = retryCount + 1;
        final delay =
            (retryCount + 1) * 1500; // Exponential backoff: 1.5s, 3s, 4.5s
        log('SyncChainService: Will retry connection in ${delay}ms');
        _requestConnection(endpointId, retryDelay: delay);
        return;
      }

      // Give up after max retries - try switching strategy
      log('SyncChainService: Max retries reached, giving up on $endpointId');
      _pendingConnections.remove(endpointId);
      _connectionRetryCount.remove(endpointId);

      // If we haven't tried cluster strategy yet, switch and restart
      if (!_useClusterStrategy && isRetryableError) {
        log('SyncChainService: Switching to P2P_CLUSTER strategy...');
        _useClusterStrategy = true;
        onError?.call(
          'Connection failed. Trying alternate connection method...',
        );
        _scheduleReconnect();
      } else {
        onError?.call(
          'Unable to connect. Please ensure both devices have WiFi and Bluetooth enabled and are near each other.',
        );
      }

      _setStatus(
        _connectedDevices.isEmpty
            ? SyncChainStatus.discovering
            : SyncChainStatus.connected,
      );
    }
  }

  /// Handle connection initiated
  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    log(
      'SyncChainService: Connection initiated from ${info.endpointName} ($endpointId)',
    );
    log('SyncChainService: Auth token: ${info.authenticationToken}');

    // Parse endpoint name to verify chain ID
    final parts = info.endpointName.split('_');
    final remoteChainId = parts.isNotEmpty ? parts.last : '';

    if (remoteChainId == _chainId || _pendingConnections.contains(endpointId)) {
      log('SyncChainService: Accepting connection...');
      _nearby.acceptConnection(
        endpointId,
        onPayLoadRecieved: _onPayloadReceived,
        onPayloadTransferUpdate: _onPayloadTransferUpdate,
      );
    } else {
      log('SyncChainService: Rejecting connection - chain ID mismatch');
      _nearby.rejectConnection(endpointId);
    }
  }

  /// Handle connection result
  void _onConnectionResult(String endpointId, Status status) {
    log(
      'SyncChainService: Connection result for $endpointId: ${status.toString()}',
    );
    _pendingConnections.remove(endpointId);

    if (status == Status.CONNECTED) {
      log('SyncChainService: *** CONNECTION ESTABLISHED ***');

      // Send handshake to exchange device info
      _sendHandshake(endpointId);
    } else {
      log('SyncChainService: Connection failed with status: $status');

      if (_connectedDevices.isEmpty) {
        _setStatus(SyncChainStatus.discovering);
      }
    }
  }

  /// Handle disconnection
  void _onDisconnected(String endpointId) {
    log('SyncChainService: Disconnected from: $endpointId');

    final deviceId = _endpointToDeviceId.remove(endpointId);
    if (deviceId != null) {
      _deviceIdToEndpoint.remove(deviceId);
      _connectedDevices.remove(deviceId);
      _messageQueues.remove(endpointId);
      onDeviceDisconnected?.call(deviceId);
    }

    if (_connectedDevices.isEmpty) {
      _setStatus(SyncChainStatus.discovering);
      // Try to reconnect
      _scheduleReconnect();
    }
  }

  /// Send handshake message
  Future<void> _sendHandshake(String endpointId) async {
    final message = SyncMessage(
      type: SyncMessageType.handshake,
      senderId: _deviceId!,
      senderName: _deviceName!,
      timestamp: DateTime.now(),
      payload: {
        'chainId': _chainId,
        'seedPhraseHash': sha256.convert(utf8.encode(_seedPhrase!)).toString(),
      },
    );

    await _sendMessageToEndpoint(endpointId, message);
  }

  /// Handle payload received
  void _onPayloadReceived(String endpointId, Payload payload) {
    log(
      'SyncChainService: Payload received from $endpointId, type: ${payload.type}',
    );

    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      try {
        final jsonString = utf8.decode(payload.bytes!);
        final message = SyncMessage.fromJson(jsonString);
        _handleSyncMessage(endpointId, message);
      } catch (e) {
        log('SyncChainService: Error parsing payload: $e');
      }
    }
  }

  /// Handle payload transfer update
  void _onPayloadTransferUpdate(
    String endpointId,
    PayloadTransferUpdate update,
  ) {
    final progress = update.totalBytes > 0
        ? (update.bytesTransferred / update.totalBytes * 100).toStringAsFixed(1)
        : '0';

    if (update.status == PayloadStatus.SUCCESS) {
      log('SyncChainService: Payload transfer SUCCESS to $endpointId');
      // Remove from retry queue on success
      _messageQueues[endpointId]?.removeWhere((m) => m.payloadId == update.id);
    } else if (update.status == PayloadStatus.FAILURE) {
      log('SyncChainService: Payload transfer FAILED to $endpointId');
      // Retry failed messages
      _retryFailedMessage(endpointId, update.id);
    } else if (update.status == PayloadStatus.IN_PROGRESS) {
      log('SyncChainService: Payload transfer $progress% to $endpointId');
    }
  }

  /// Retry a failed message
  Future<void> _retryFailedMessage(String endpointId, int payloadId) async {
    final queue = _messageQueues[endpointId];
    if (queue == null) return;

    final pending = queue.where((m) => m.payloadId == payloadId).firstOrNull;
    if (pending != null && pending.retryCount < 3) {
      log(
        'SyncChainService: Retrying message (attempt ${pending.retryCount + 1}/3)',
      );
      await Future.delayed(
        Duration(milliseconds: 500 * (pending.retryCount + 1)),
      );
      pending.retryCount++;
      await _sendMessageToEndpoint(endpointId, pending.message);
    } else {
      log('SyncChainService: Max retries reached, giving up on message');
      queue.removeWhere((m) => m.payloadId == payloadId);
    }
  }

  /// Handle sync messages
  void _handleSyncMessage(String endpointId, SyncMessage message) {
    log(
      'SyncChainService: Received ${message.type} from ${message.senderName}',
    );

    switch (message.type) {
      case SyncMessageType.handshake:
        _handleHandshake(endpointId, message);
        break;
      case SyncMessageType.handshakeResponse:
        _handleHandshakeResponse(endpointId, message);
        break;
      case SyncMessageType.fullSync:
        _handleFullSync(endpointId, message);
        break;
      case SyncMessageType.fullSyncResponse:
        _handleFullSyncResponse(message);
        break;
      case SyncMessageType.passwordAdded:
      case SyncMessageType.passwordUpdated:
      case SyncMessageType.passwordDeleted:
      case SyncMessageType.noteAdded:
      case SyncMessageType.noteUpdated:
      case SyncMessageType.noteDeleted:
      case SyncMessageType.vaultAdded:
      case SyncMessageType.vaultUpdated:
      case SyncMessageType.vaultDeleted:
        onSyncMessageReceived?.call(message);
        break;
      case SyncMessageType.ping:
        _sendPong(endpointId);
        break;
      case SyncMessageType.pong:
        _updateLastSyncTime(message.senderId);
        break;
      case SyncMessageType.disconnect:
        _handleDisconnectMessage(endpointId);
        break;
    }
  }

  /// Handle handshake
  void _handleHandshake(String endpointId, SyncMessage message) {
    final receivedChainId = message.payload['chainId'] as String?;
    final receivedHash = message.payload['seedPhraseHash'] as String?;
    final expectedHash = sha256.convert(utf8.encode(_seedPhrase!)).toString();

    log('SyncChainService: Validating handshake...');
    log('SyncChainService: Chain ID match: ${receivedChainId == _chainId}');
    log('SyncChainService: Hash match: ${receivedHash == expectedHash}');

    if (receivedChainId == _chainId && receivedHash == expectedHash) {
      final device = SyncChainDevice(
        deviceId: message.senderId,
        deviceName: message.senderName,
        connectedAt: DateTime.now(),
        lastSyncedAt: DateTime.now(),
      );

      _connectedDevices[message.senderId] = device;
      _endpointToDeviceId[endpointId] = message.senderId;
      _deviceIdToEndpoint[message.senderId] = endpointId;

      _setStatus(SyncChainStatus.connected);
      _sendHandshakeResponse(endpointId, true);
      onDeviceConnected?.call(device);

      log('SyncChainService: Handshake accepted from ${message.senderName}');
    } else {
      log('SyncChainService: Handshake rejected - verification failed');
      _sendHandshakeResponse(endpointId, false);
      _nearby.disconnectFromEndpoint(endpointId);
    }
  }

  /// Send handshake response
  Future<void> _sendHandshakeResponse(String endpointId, bool accepted) async {
    final message = SyncMessage(
      type: SyncMessageType.handshakeResponse,
      senderId: _deviceId!,
      senderName: _deviceName!,
      timestamp: DateTime.now(),
      payload: {'accepted': accepted, 'chainId': _chainId},
    );

    await _sendMessageToEndpoint(endpointId, message);

    if (accepted) {
      // Request full sync after successful handshake
      await Future.delayed(const Duration(milliseconds: 500));
      await _requestFullSync(endpointId);
    }
  }

  /// Handle handshake response
  void _handleHandshakeResponse(String endpointId, SyncMessage message) {
    final accepted = message.payload['accepted'] as bool? ?? false;

    if (accepted) {
      final device = SyncChainDevice(
        deviceId: message.senderId,
        deviceName: message.senderName,
        connectedAt: DateTime.now(),
        lastSyncedAt: DateTime.now(),
      );

      _connectedDevices[message.senderId] = device;
      _endpointToDeviceId[endpointId] = message.senderId;
      _deviceIdToEndpoint[message.senderId] = endpointId;

      _setStatus(SyncChainStatus.connected);
      onDeviceConnected?.call(device);

      log(
        'SyncChainService: Handshake response accepted by ${message.senderName}',
      );
    } else {
      log('SyncChainService: Handshake rejected by ${message.senderName}');
      onError?.call('Connection rejected by ${message.senderName}');
      _nearby.disconnectFromEndpoint(endpointId);
    }
  }

  /// Request full sync
  Future<void> _requestFullSync(String endpointId) async {
    log('SyncChainService: Requesting full sync from $endpointId');
    _setStatus(SyncChainStatus.syncing);

    final message = SyncMessage(
      type: SyncMessageType.fullSync,
      senderId: _deviceId!,
      senderName: _deviceName!,
      timestamp: DateTime.now(),
      payload: {},
    );

    await _sendMessageToEndpoint(endpointId, message);
  }

  /// Handle full sync request
  Future<void> _handleFullSync(String endpointId, SyncMessage message) async {
    log(
      'SyncChainService: Processing full sync request from ${message.senderName}',
    );
    _setStatus(SyncChainStatus.syncing);

    try {
      final vaults = await _dbService.getAllVaults();
      final passes = await _dbService.getAllPasses();
      final notes = await _dbService.getAllNotes();

      log(
        'SyncChainService: Sending ${vaults.length} vaults, ${passes.length} passes, ${notes.length} notes',
      );

      final response = SyncMessage(
        type: SyncMessageType.fullSyncResponse,
        senderId: _deviceId!,
        senderName: _deviceName!,
        timestamp: DateTime.now(),
        payload: {
          'vaults': vaults.map((v) => v.toMap()).toList(),
          'passes': passes.map((p) => p.toMap()).toList(),
          'notes': notes.map((n) => n.toMap()).toList(),
        },
      );

      await _sendMessageToEndpoint(endpointId, response);
    } catch (e) {
      log('SyncChainService: Error handling full sync: $e');
      onError?.call('Error syncing data: $e');
    } finally {
      _setStatus(SyncChainStatus.connected);
    }
  }

  /// Handle full sync response
  void _handleFullSyncResponse(SyncMessage message) {
    log(
      'SyncChainService: Received full sync response from ${message.senderName}',
    );
    _setStatus(SyncChainStatus.syncing);
    onSyncMessageReceived?.call(message);
    _setStatus(SyncChainStatus.connected);
  }

  /// Send pong response
  Future<void> _sendPong(String endpointId) async {
    final message = SyncMessage(
      type: SyncMessageType.pong,
      senderId: _deviceId!,
      senderName: _deviceName!,
      timestamp: DateTime.now(),
      payload: {},
    );

    await _sendMessageToEndpoint(endpointId, message);
  }

  /// Update last sync time
  void _updateLastSyncTime(String deviceId) {
    if (_connectedDevices.containsKey(deviceId)) {
      _connectedDevices[deviceId] = _connectedDevices[deviceId]!.copyWith(
        lastSyncedAt: DateTime.now(),
      );
    }
  }

  /// Handle disconnect message
  void _handleDisconnectMessage(String endpointId) {
    _nearby.disconnectFromEndpoint(endpointId);
  }

  /// Send message to a specific endpoint with retry support
  Future<void> _sendMessageToEndpoint(
    String endpointId,
    SyncMessage message,
  ) async {
    try {
      final jsonString = message.toJson();
      final bytes = utf8.encode(jsonString);

      log(
        'SyncChainService: Sending ${message.type} to $endpointId (${bytes.length} bytes)',
      );

      // Add to message queue for retry tracking
      _messageQueues.putIfAbsent(endpointId, () => []);

      await _nearby.sendBytesPayload(endpointId, Uint8List.fromList(bytes));
    } catch (e) {
      log('SyncChainService: Error sending message: $e');

      // Check for specific error types
      if (e.toString().contains('STATUS_ENDPOINT_IO_ERROR') ||
          e.toString().contains('4201')) {
        log('SyncChainService: Endpoint IO error - connection may be unstable');
        // Don't immediately disconnect, let retry handle it
      }
    }
  }

  /// Broadcast message to all connected devices
  Future<void> broadcastMessage(SyncMessage message) async {
    log(
      'SyncChainService: Broadcasting ${message.type} to ${_connectedDevices.length} devices',
    );

    for (final entry in _deviceIdToEndpoint.entries) {
      await _sendMessageToEndpoint(entry.value, message);
    }
  }

  /// Start heartbeat timer
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendHeartbeat();
    });
  }

  /// Send heartbeat to all connected devices
  Future<void> _sendHeartbeat() async {
    if (_connectedDevices.isEmpty) return;

    final message = SyncMessage(
      type: SyncMessageType.ping,
      senderId: _deviceId!,
      senderName: _deviceName!,
      timestamp: DateTime.now(),
      payload: {},
    );

    await broadcastMessage(message);
  }

  /// Schedule reconnect attempt
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (isChainActive && _connectedDevices.isEmpty) {
        log('SyncChainService: Attempting reconnect...');
        await stopSyncChain();
        await startSyncChain();
      }
    });
  }

  // Broadcast methods for password provider
  Future<void> broadcastPasswordAdded(
    Map<String, dynamic> passData,
    List<Map<String, dynamic>> notesData,
  ) async {
    final message = SyncMessage(
      type: SyncMessageType.passwordAdded,
      senderId: _deviceId!,
      senderName: _deviceName!,
      timestamp: DateTime.now(),
      payload: {'pass': passData, 'notes': notesData},
    );
    await broadcastMessage(message);
  }

  Future<void> broadcastPasswordUpdated(
    Map<String, dynamic> passData,
    List<Map<String, dynamic>> notesData,
  ) async {
    final message = SyncMessage(
      type: SyncMessageType.passwordUpdated,
      senderId: _deviceId!,
      senderName: _deviceName!,
      timestamp: DateTime.now(),
      payload: {'pass': passData, 'notes': notesData},
    );
    await broadcastMessage(message);
  }

  Future<void> broadcastPasswordDeleted(int passId) async {
    final message = SyncMessage(
      type: SyncMessageType.passwordDeleted,
      senderId: _deviceId!,
      senderName: _deviceName!,
      timestamp: DateTime.now(),
      payload: {'passId': passId},
    );
    await broadcastMessage(message);
  }

  Future<void> broadcastVaultAdded(Map<String, dynamic> vaultData) async {
    final message = SyncMessage(
      type: SyncMessageType.vaultAdded,
      senderId: _deviceId!,
      senderName: _deviceName!,
      timestamp: DateTime.now(),
      payload: {'vault': vaultData},
    );
    await broadcastMessage(message);
  }

  Future<void> broadcastVaultUpdated(Map<String, dynamic> vaultData) async {
    final message = SyncMessage(
      type: SyncMessageType.vaultUpdated,
      senderId: _deviceId!,
      senderName: _deviceName!,
      timestamp: DateTime.now(),
      payload: {'vault': vaultData},
    );
    await broadcastMessage(message);
  }

  Future<void> broadcastVaultDeleted(int vaultId) async {
    final message = SyncMessage(
      type: SyncMessageType.vaultDeleted,
      senderId: _deviceId!,
      senderName: _deviceName!,
      timestamp: DateTime.now(),
      payload: {'vaultId': vaultId},
    );
    await broadcastMessage(message);
  }

  /// Stop sync chain
  Future<void> stopSyncChain() async {
    log('SyncChainService: Stopping sync chain...');

    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    try {
      await _nearby.stopAdvertising();
      await _nearby.stopDiscovery();
      await _nearby.stopAllEndpoints();
    } catch (e) {
      log('SyncChainService: Error stopping: $e');
    }

    // Stop foreground service
    await _stopForegroundService();

    _isAdvertising = false;
    _isDiscovering = false;
    _useClusterStrategy = false; // Reset strategy for next time
    _connectedDevices.clear();
    _endpointToDeviceId.clear();
    _deviceIdToEndpoint.clear();
    _pendingConnections.clear();
    _messageQueues.clear();
    _connectionRetryCount.clear();

    _setStatus(SyncChainStatus.disconnected);
    log('SyncChainService: Stopped');
  }

  /// Leave sync chain
  Future<void> leaveSyncChain() async {
    await stopSyncChain();

    await _secureStorage.delete(key: _chainIdKey);
    await _secureStorage.delete(key: _seedPhraseKey);
    await _secureStorage.delete(key: _chainActiveKey);

    _chainId = null;
    _seedPhrase = null;

    log('SyncChainService: Left sync chain');
  }

  /// Set status and notify
  void _setStatus(SyncChainStatus newStatus) {
    if (_status != newStatus) {
      log('SyncChainService: Status changed: $_status -> $newStatus');
      _status = newStatus;
      onStatusChanged?.call(newStatus);
      // Update foreground notification with new status
      _updateForegroundNotification();
    }
  }

  // Permission methods
  Future<bool> checkLocationPermission() async {
    return await Permission.locationWhenInUse.isGranted;
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> checkBluetoothPermission() async {
    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.isGranted;
      final advertise = await Permission.bluetoothAdvertise.isGranted;
      final connect = await Permission.bluetoothConnect.isGranted;
      return scan && advertise && connect;
    }
    return true;
  }

  Future<bool> requestBluetoothPermission() async {
    if (Platform.isAndroid) {
      final results = await [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ].request();
      return results.values.every((s) => s.isGranted);
    }
    return true;
  }

  Future<bool> checkAndRequestAllPermissions() async {
    bool bluetoothGranted = await checkBluetoothPermission();
    if (!bluetoothGranted) {
      bluetoothGranted = await requestBluetoothPermission();
    }

    bool locationGranted = await checkLocationPermission();
    if (!locationGranted) {
      locationGranted = await requestLocationPermission();
    }

    // Also request nearby WiFi devices permission on Android 12+
    if (Platform.isAndroid) {
      await Permission.nearbyWifiDevices.request();
    }

    log(
      'SyncChainService: Permissions - Bluetooth: $bluetoothGranted, Location: $locationGranted',
    );
    return bluetoothGranted && locationGranted;
  }

  Future<bool> enableLocation() async {
    return await openAppSettings();
  }

  Future<bool> checkLocationEnabled() async {
    return await Permission.locationWhenInUse.serviceStatus.isEnabled;
  }

  // ========== FOREGROUND SERVICE METHODS ==========

  /// Initialize foreground task for persistent background connection
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sync_chain_service',
        channelName: 'Sync Chain Service',
        channelDescription: 'Keeps password sync active in background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start foreground service for persistent connection
  Future<void> _startForegroundService() async {
    if (_isForegroundServiceRunning) return;

    // Check notification permission first - required for foreground service on Android 13+
    // Don't request permission here, it should have been requested at app launch
    if (Platform.isAndroid) {
      try {
        final isGranted = await NotiService.instance
            .checkNotificationPermission();
        if (!isGranted) {
          log(
            'SyncChainService: Notification permission not granted - skipping foreground service',
          );
          // Don't start foreground service without notification permission
          // This prevents crashes on Android 13+
          return;
        }
      } catch (e) {
        log(
          'SyncChainService: Error checking notification permission: $e - skipping foreground service',
        );
        return;
      }
    }

    try {
      _initForegroundTask();

      final result = await FlutterForegroundTask.startService(
        notificationTitle: 'Sync Chain Active',
        notificationText: 'Syncing passwords with connected devices',
        notificationIcon: null,
        notificationButtons: [
          const NotificationButton(id: 'stop', text: 'Stop Sync'),
        ],
        callback: null,
      );

      if (result is ServiceRequestSuccess) {
        _isForegroundServiceRunning = true;
        log('SyncChainService: Foreground service started');
      } else {
        log('SyncChainService: Failed to start foreground service: $result');
      }
    } catch (e) {
      log('SyncChainService: Error starting foreground service: $e');
      // Don't rethrow - foreground service is optional, sync can work without it
    }
  }

  /// Stop foreground service
  Future<void> _stopForegroundService() async {
    if (!_isForegroundServiceRunning) return;

    try {
      final result = await FlutterForegroundTask.stopService();
      if (result is ServiceRequestSuccess) {
        _isForegroundServiceRunning = false;
        log('SyncChainService: Foreground service stopped');
      } else {
        log('SyncChainService: Failed to stop foreground service: $result');
      }
    } catch (e) {
      log('SyncChainService: Error stopping foreground service: $e');
      _isForegroundServiceRunning = false;
    }
  }

  /// Update foreground notification with current status
  Future<void> _updateForegroundNotification() async {
    if (!_isForegroundServiceRunning) return;

    try {
      final deviceCount = _connectedDevices.length;
      final statusText = deviceCount > 0
          ? 'Connected to $deviceCount device${deviceCount > 1 ? 's' : ''}'
          : 'Searching for devices...';

      await FlutterForegroundTask.updateService(
        notificationTitle: 'Sync Chain Active',
        notificationText: statusText,
      );
    } catch (e) {
      log('SyncChainService: Error updating foreground notification: $e');
    }
  }

  /// Check if foreground service is running
  bool get isForegroundServiceRunning => _isForegroundServiceRunning;

  /// Debug methods
  Future<Map<String, dynamic>> debugGetStatus() async {
    return {
      'chainId': _chainId,
      'deviceId': _deviceId,
      'deviceName': _deviceName,
      'isAdvertising': _isAdvertising,
      'isDiscovering': _isDiscovering,
      'connectedDevices': _connectedDevices.length,
      'pendingConnections': _pendingConnections.length,
      'status': _status.toString(),
      'nearbyUsername': _nearbyUsername,
    };
  }

  Future<List<String>> debugScanAllDevices() async {
    // For nearby_connections, we can't do a manual scan
    // The discovery is continuous, so just return current state
    return [
      'Advertising: $_isAdvertising',
      'Discovering: $_isDiscovering',
      'Connected: ${_connectedDevices.length}',
      'Pending: ${_pendingConnections.length}',
    ];
  }

  void dispose() {
    log('SyncChainService: Disposing...');
    stopSyncChain();
  }
}

/// Helper class for pending messages
class _PendingMessage {
  final SyncMessage message;
  final int payloadId;
  int retryCount = 0;

  _PendingMessage({required this.message, required this.payloadId});
}
