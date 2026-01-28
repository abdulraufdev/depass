import 'package:depass/models/note.dart';
import 'package:depass/models/pass.dart';
import 'package:depass/models/sync_chain.dart';
import 'package:depass/models/vault.dart';
import 'package:depass/providers/password_provider.dart';
import 'package:depass/providers/vault_provider.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/services/sync_chain_service.dart';
import 'package:flutter/foundation.dart';

/// Provider for managing sync chain state and operations
class SyncChainProvider extends ChangeNotifier implements SyncChainNotifier {
  final SyncChainService _syncChainService = SyncChainService();
  final DBService _dbService = DBService.instance;

  // State
  SyncChainStatus _status = SyncChainStatus.disconnected;
  SyncChain? _currentChain;
  List<SyncChainDevice> _connectedDevices = [];
  String? _errorMessage;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isJoiningChain = false; // Flag to indicate if we're joining a chain

  // Password provider reference for real-time sync
  PasswordProvider? _passwordProvider;

  // Vault provider reference for refreshing vaults after sync
  VaultProvider? _vaultProvider;

  // Getters
  SyncChainStatus get status => _status;
  SyncChain? get currentChain => _currentChain;
  List<SyncChainDevice> get connectedDevices => _connectedDevices;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isChainActive => _syncChainService.isChainActive;
  String? get seedPhrase => _syncChainService.seedPhrase;
  String? get chainId => _syncChainService.chainId;
  String? get deviceId => _syncChainService.deviceId;
  String? get deviceName => _syncChainService.deviceName;

  /// Set password provider reference
  void setPasswordProvider(PasswordProvider? provider) {
    _passwordProvider = provider;
    _passwordProvider?.setSyncChainNotifier(this);
  }

  /// Set vault provider reference
  void setVaultProvider(VaultProvider? provider) {
    _vaultProvider = provider;
  }

  /// Initialize the sync chain provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);

    try {
      await _syncChainService.initialize();

      // Set up callbacks
      _syncChainService.onDeviceConnected = _onDeviceConnected;
      _syncChainService.onDeviceDisconnected = _onDeviceDisconnected;
      _syncChainService.onSyncMessageReceived = _onSyncMessageReceived;
      _syncChainService.onStatusChanged = _onStatusChanged;
      _syncChainService.onError = _onError;

      // Load existing chain if any
      if (_syncChainService.isChainActive) {
        _currentChain = SyncChain(
          chainId: _syncChainService.chainId!,
          seedPhrase: _syncChainService.seedPhrase!,
          createdAt: DateTime.now(),
          connectedDevices: [],
          isActive: true,
        );
      }

      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Failed to initialize sync chain: $e';
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new sync chain
  Future<SyncChain?> createSyncChain() async {
    _setLoading(true);
    _clearError();

    try {
      // Check permissions first
      final hasPermissions = await _syncChainService
          .checkAndRequestAllPermissions();
      if (!hasPermissions) {
        _errorMessage = 'Location permission is required for sync chain';
        notifyListeners();
        return null;
      }

      // Check location enabled
      final locationEnabled = await _syncChainService.checkLocationEnabled();
      if (!locationEnabled) {
        final enabled = await _syncChainService.enableLocation();
        if (!enabled) {
          _errorMessage = 'Please enable location services';
          notifyListeners();
          return null;
        }
      }

      // Create the chain
      _currentChain = await _syncChainService.createSyncChain();

      // Start advertising and discovery
      await _syncChainService.startSyncChain();

      notifyListeners();
      return _currentChain;
    } catch (e) {
      _errorMessage = 'Failed to create sync chain: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Join an existing sync chain
  Future<bool> joinSyncChain(String seedPhrase) async {
    print('SyncChainProvider: joinSyncChain called with seed phrase');
    _setLoading(true);
    _clearError();

    try {
      // Check permissions first
      print('SyncChainProvider: Checking permissions...');
      final hasPermissions = await _syncChainService
          .checkAndRequestAllPermissions();
      if (!hasPermissions) {
        print('SyncChainProvider: Permission check FAILED');
        _errorMessage = 'Location permission is required for sync chain';
        notifyListeners();
        return false;
      }
      print('SyncChainProvider: Permissions granted');

      // Check location enabled
      print('SyncChainProvider: Checking location enabled...');
      final locationEnabled = await _syncChainService.checkLocationEnabled();
      if (!locationEnabled) {
        print('SyncChainProvider: Location not enabled, trying to enable...');
        final enabled = await _syncChainService.enableLocation();
        if (!enabled) {
          print('SyncChainProvider: Failed to enable location');
          _errorMessage = 'Please enable location services';
          notifyListeners();
          return false;
        }
      }
      print('SyncChainProvider: Location is enabled');

      // Validate and join
      print('SyncChainProvider: Calling syncChainService.joinSyncChain...');
      final success = await _syncChainService.joinSyncChain(seedPhrase);
      if (!success) {
        print('SyncChainProvider: joinSyncChain returned false');
        _errorMessage = 'Invalid seed phrase';
        notifyListeners();
        return false;
      }
      print('SyncChainProvider: joinSyncChain succeeded');

      // Set flag to indicate we're joining - full data replacement needed on first sync
      _isJoiningChain = true;

      // Create chain object
      _currentChain = SyncChain(
        chainId: _syncChainService.chainId!,
        seedPhrase: _syncChainService.seedPhrase!,
        createdAt: DateTime.now(),
        connectedDevices: [],
        isActive: true,
      );
      print('SyncChainProvider: Chain object created');

      // Start advertising and discovery to find other devices
      print('SyncChainProvider: Starting sync chain...');
      await _syncChainService.startSyncChain();
      print('SyncChainProvider: Sync chain started');

      notifyListeners();
      return true;
    } catch (e) {
      print('SyncChainProvider: Exception caught: $e');
      _errorMessage = 'Failed to join sync chain: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Start sync chain (advertising and discovery)
  Future<bool> startSyncChain() async {
    if (!_syncChainService.isChainActive) {
      _errorMessage = 'No sync chain configured';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final success = await _syncChainService.startSyncChain();
      if (!success) {
        _errorMessage = 'Failed to start sync chain';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Error starting sync chain: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Stop sync chain
  Future<void> stopSyncChain() async {
    _setLoading(true);

    try {
      await _syncChainService.stopSyncChain();
      _connectedDevices = [];
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error stopping sync chain: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Leave and delete sync chain
  Future<void> leaveSyncChain() async {
    _setLoading(true);

    try {
      await _syncChainService.leaveSyncChain();
      _currentChain = null;
      _connectedDevices = [];
      _status = SyncChainStatus.disconnected;
      _isJoiningChain = false; // Reset join flag
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error leaving sync chain: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Validate seed phrase
  bool validateSeedPhrase(String seedPhrase) {
    return _syncChainService.validateSeedPhrase(seedPhrase);
  }

  /// Called when a device connects
  void _onDeviceConnected(SyncChainDevice device) {
    _connectedDevices = List.from(_connectedDevices)..add(device);
    notifyListeners();
  }

  /// Called when a device disconnects
  void _onDeviceDisconnected(String deviceId) {
    _connectedDevices = _connectedDevices
        .where((d) => d.deviceId != deviceId)
        .toList();
    notifyListeners();
  }

  /// Called when sync status changes
  void _onStatusChanged(SyncChainStatus status) {
    _status = status;
    notifyListeners();
  }

  /// Called when an error occurs
  void _onError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Called when a sync message is received
  Future<void> _onSyncMessageReceived(SyncMessage message) async {
    print('Processing sync message: ${message.type}');

    try {
      switch (message.type) {
        case SyncMessageType.fullSyncResponse:
          await _handleFullSyncResponse(message);
          break;
        case SyncMessageType.passwordAdded:
          await _handlePasswordAdded(message);
          break;
        case SyncMessageType.passwordUpdated:
          await _handlePasswordUpdated(message);
          break;
        case SyncMessageType.passwordDeleted:
          await _handlePasswordDeleted(message);
          break;
        case SyncMessageType.vaultAdded:
          await _handleVaultAdded(message);
          break;
        case SyncMessageType.vaultUpdated:
          await _handleVaultUpdated(message);
          break;
        case SyncMessageType.vaultDeleted:
          await _handleVaultDeleted(message);
          break;
        default:
          break;
      }

      // Refresh password provider data
      await _passwordProvider?.loadAllPasses();
      // Refresh vault provider data
      await _vaultProvider?.loadAllVaults();
    } catch (e) {
      print('Error processing sync message: $e');
      _errorMessage = 'Sync error: $e';
      notifyListeners();
    }
  }

  /// Handle full sync response - import all data from another device
  /// When joining a sync chain (_isJoiningChain = true), this completely replaces local data
  /// When already in a sync chain, this merges data intelligently
  Future<void> _handleFullSyncResponse(SyncMessage message) async {
    final vaultsData = message.payload['vaults'] as List?;
    final passesData = message.payload['passes'] as List?;
    final notesData = message.payload['notes'] as List?;

    if (vaultsData == null || passesData == null || notesData == null) {
      print('Full sync response missing required data');
      return;
    }

    print(
      'Full sync: Received ${vaultsData.length} vaults, ${passesData.length} passes, ${notesData.length} notes',
    );
    print('Full sync: Is joining chain = $_isJoiningChain');

    try {
      // Convert to proper format
      final vaults = vaultsData.map((v) => v as Map<String, dynamic>).toList();
      final passes = passesData.map((p) => p as Map<String, dynamic>).toList();
      final notes = notesData.map((n) => n as Map<String, dynamic>).toList();

      if (_isJoiningChain) {
        // JOINING SCENARIO: Complete data replacement
        // This handles all 3 scenarios:
        // - Device with no data
        // - Device with no vaults/passwords
        // - Device with existing vaults/passwords (all will be deleted)
        //
        // importFullSyncData will:
        // 1. Clear ALL existing data (notes, passes, vaults)
        // 2. Reset auto-increment sequences
        // 3. Import all data with EXACT IDs preserved
        //    This ensures passwords reference correct vault IDs
        await _dbService.importFullSyncData(
          vaults: vaults,
          passes: passes,
          notes: notes,
        );

        // Reset the joining flag after successful sync
        _isJoiningChain = false;

        print('Full sync completed - data replaced with sync chain data');
      } else {
        // EXISTING SYNC CHAIN: Merge/update data
        // This happens when reconnecting to an existing sync chain
        // We should merge data rather than replace
        await _mergeFullSyncData(vaults, passes, notes);

        print('Full sync completed - data merged');
      }
    } catch (e) {
      print('Error during full sync import: $e');
      _errorMessage = 'Sync error: $e';
      notifyListeners();
    }
  }

  /// Merge data from another device with existing local data
  /// Used when reconnecting to an existing sync chain (not a fresh join)
  Future<void> _mergeFullSyncData(
    List<Map<String, dynamic>> vaults,
    List<Map<String, dynamic>> passes,
    List<Map<String, dynamic>> notes,
  ) async {
    // Get existing data
    final existingVaults = await _dbService.getAllVaults();
    final existingPasses = await _dbService.getAllPasses();
    final existingNotes = await _dbService.getAllNotes();

    final existingVaultIds = existingVaults.map((v) => v.VaultId).toSet();
    final existingPassIds = existingPasses.map((p) => p.PassId).toSet();
    final existingNoteIds = existingNotes.map((n) => n.NoteId).toSet();

    // Add missing vaults with exact IDs
    for (final vault in vaults) {
      final vaultId = vault['VaultId'] as int;
      if (!existingVaultIds.contains(vaultId)) {
        await _dbService.createVault(
          vault['VaultTitle'] as String,
          vault['VaultIcon'] as String,
          vault['VaultColor'] as String,
          vaultId: vaultId,
        );
      }
    }

    // Add missing passes with exact IDs
    for (final pass in passes) {
      final passId = pass['PassId'] as int;
      if (!existingPassIds.contains(passId)) {
        await _dbService.insertPassWithId(
          passId,
          pass['VaultId'] as int,
          pass['PassTitle'] as String,
          pass['CreatedAt'] as int,
        );
      }
    }

    // Add missing notes with exact IDs
    for (final note in notes) {
      final noteId = note['NoteId'] as int;
      if (!existingNoteIds.contains(noteId)) {
        await _dbService.insertNoteWithId(
          noteId,
          note['Description'] as String,
          note['Type'] as String,
          note['CreatedAt'] as int,
          note['UpdatedAt'] as int,
          note['PassId'] as int,
        );
      }
    }
  }

  /// Handle password added from another device
  Future<void> _handlePasswordAdded(SyncMessage message) async {
    final passData = message.payload['pass'] as Map<String, dynamic>?;
    final notesData = message.payload['notes'] as List?;

    if (passData == null) return;

    final pass = Pass.fromMap(passData);

    // Check if pass already exists by ID
    final existingPasses = await _dbService.getAllPasses();
    final exists = existingPasses.any((p) => p.PassId == pass.PassId);

    if (!exists) {
      // Insert pass with exact ID to maintain consistency across devices
      await _dbService.insertPassWithId(
        pass.PassId,
        pass.VaultId,
        pass.PassTitle,
        pass.CreatedAt,
      );

      // Insert notes with exact IDs
      if (notesData != null) {
        for (final noteData in notesData) {
          final noteMap = noteData as Map<String, dynamic>;
          await _dbService.insertNoteWithId(
            noteMap['NoteId'] as int,
            noteMap['Description'] as String,
            noteMap['Type'] as String,
            noteMap['CreatedAt'] as int,
            noteMap['UpdatedAt'] as int,
            noteMap['PassId'] as int,
          );
        }
      }

      print('Password added from sync: ${pass.PassTitle}');
    }
  }

  /// Handle password updated from another device
  Future<void> _handlePasswordUpdated(SyncMessage message) async {
    final passData = message.payload['pass'] as Map<String, dynamic>?;
    final notesData = message.payload['notes'] as List?;

    if (passData == null) return;

    final passId = passData['PassId'] as int;
    final newTitle = passData['PassTitle'] as String;

    // Update pass title
    await _dbService.updatePass(passId, newTitle, null);

    // Update notes
    if (notesData != null) {
      for (final noteData in notesData) {
        final noteMap = noteData as Map<String, dynamic>;
        final noteId = noteMap['NoteId'] as int?;
        if (noteId != null) {
          await _dbService.updateNote(
            noteId,
            noteMap['Description'] as String,
            noteMap['Type'] as String,
          );
        }
      }
    }
  }

  /// Handle password deleted from another device
  Future<void> _handlePasswordDeleted(SyncMessage message) async {
    final passId = message.payload['passId'] as int?;
    if (passId != null) {
      await _dbService.deletePass(passId);
    }
  }

  /// Handle vault added from another device
  Future<void> _handleVaultAdded(SyncMessage message) async {
    final vaultData = message.payload['vault'] as Map<String, dynamic>?;
    if (vaultData == null) return;

    final vault = Vault.fromMap(vaultData);

    // Check if vault already exists by ID
    final existingVaults = await _dbService.getAllVaults();
    final exists = existingVaults.any((v) => v.VaultId == vault.VaultId);

    if (!exists) {
      await _dbService.createVault(
        vault.VaultTitle,
        vault.VaultIcon,
        vault.VaultColor,
        vaultId: vault.VaultId,
      );

      print('Vault added from sync: ${vault.VaultTitle}');
    }
  }

  /// Handle vault updated from another device
  Future<void> _handleVaultUpdated(SyncMessage message) async {
    final vaultData = message.payload['vault'] as Map<String, dynamic>?;
    if (vaultData == null) return;

    final vaultId = vaultData['VaultId'] as int;
    final newTitle = vaultData['VaultTitle'] as String;
    final vaultIcon = vaultData['VaultIcon'] as String;
    final vaultColor = vaultData['VaultColor'] as String;

    await _dbService.updateVault(vaultId, newTitle, vaultIcon, vaultColor);
  }

  /// Handle vault deleted from another device
  Future<void> _handleVaultDeleted(SyncMessage message) async {
    final vaultId = message.payload['vaultId'] as int?;
    if (vaultId != null) {
      await _dbService.deleteVault(vaultId);
    }
  }

  /// Called when password changes locally - broadcast to all devices
  @override
  Future<void> onPasswordChanged() async {
    // This is called by PasswordProvider when local changes occur
    // The actual broadcasting is done through specific methods
    print('Password changed notification received');
  }

  /// Broadcast a new password to all connected devices
  Future<void> broadcastPasswordAdded(Pass pass, List<Note> notes) async {
    if (_status != SyncChainStatus.connected || _connectedDevices.isEmpty) {
      return;
    }

    await _syncChainService.broadcastPasswordAdded(
      pass.toMap(),
      notes.map((n) => n.toMap()).toList(),
    );
  }

  /// Broadcast password update to all connected devices
  Future<void> broadcastPasswordUpdated(Pass pass, List<Note> notes) async {
    if (_status != SyncChainStatus.connected || _connectedDevices.isEmpty) {
      return;
    }

    await _syncChainService.broadcastPasswordUpdated(
      pass.toMap(),
      notes.map((n) => n.toMap()).toList(),
    );
  }

  /// Broadcast password deletion to all connected devices
  Future<void> broadcastPasswordDeleted(int passId) async {
    if (_status != SyncChainStatus.connected || _connectedDevices.isEmpty) {
      return;
    }

    await _syncChainService.broadcastPasswordDeleted(passId);
  }

  /// Broadcast vault added to all connected devices
  Future<void> broadcastVaultAdded(Vault vault) async {
    if (_status != SyncChainStatus.connected || _connectedDevices.isEmpty) {
      return;
    }

    await _syncChainService.broadcastVaultAdded(vault.toMap());
  }

  /// Broadcast vault updated to all connected devices
  Future<void> broadcastVaultUpdated(Vault vault) async {
    if (_status != SyncChainStatus.connected || _connectedDevices.isEmpty) {
      return;
    }

    await _syncChainService.broadcastVaultUpdated(vault.toMap());
  }

  /// Broadcast vault deleted to all connected devices
  Future<void> broadcastVaultDeleted(int vaultId) async {
    if (_status != SyncChainStatus.connected || _connectedDevices.isEmpty) {
      return;
    }

    await _syncChainService.broadcastVaultDeleted(vaultId);
  }

  /// Helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Get status display text
  String getStatusText() {
    switch (_status) {
      case SyncChainStatus.disconnected:
        return 'Disconnected';
      case SyncChainStatus.discovering:
        return 'Searching for devices...';
      case SyncChainStatus.connecting:
        return 'Connecting...';
      case SyncChainStatus.connected:
        return 'Connected (${_connectedDevices.length} device${_connectedDevices.length != 1 ? 's' : ''})';
      case SyncChainStatus.syncing:
        return 'Syncing...';
      case SyncChainStatus.error:
        return 'Error';
    }
  }

  /// Debug: Get current status info
  Future<Map<String, dynamic>> debugGetStatus() async {
    return await _syncChainService.debugGetStatus();
  }

  /// Debug: Scan all visible BLE devices
  Future<List<String>> debugScanAllDevices() async {
    return await _syncChainService.debugScanAllDevices();
  }

  @override
  void dispose() {
    _syncChainService.stopSyncChain();
    _passwordProvider?.setSyncChainNotifier(null);
    super.dispose();
  }
}
