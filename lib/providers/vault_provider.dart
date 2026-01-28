import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/models/vault.dart';

class VaultProvider extends ChangeNotifier {
  final DBService _dbService = DBService.instance;

  // Cache for all vaults
  List<Vault>? _allVaults;

  // Loading state
  bool _isLoadingAllVaults = false;

  // Safe notification method
  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Getters
  List<Vault>? get allVaults => _allVaults;
  bool get isLoadingAllVaults => _isLoadingAllVaults;

  // Load all vaults
  Future<void> loadAllVaults() async {
    _isLoadingAllVaults = true;
    _safeNotifyListeners();

    try {
      final vaults = await _dbService.getAllVaults();
      _allVaults = vaults;
    } catch (e) {
      print('Error loading all vaults: $e');
      _allVaults = [];
    } finally {
      _isLoadingAllVaults = false;
      _safeNotifyListeners();
    }
  }

  // Update vault info
  Future<void> updateVaultInfo(
    int vaultId,
    String newTitle,
    String vaultIcon,
    String vaultColor,
  ) async {
    try {
      await _dbService.updateVault(vaultId, newTitle, vaultIcon, vaultColor);

      // Update cached data
      if (_allVaults != null) {
        final vaultIndex = _allVaults!.indexWhere(
          (vault) => vault.VaultId == vaultId,
        );
        if (vaultIndex != -1) {
          _allVaults![vaultIndex] = Vault(
            VaultId: _allVaults![vaultIndex].VaultId,
            VaultTitle: newTitle,
            VaultIcon: vaultIcon,
            VaultColor: vaultColor,
            CreatedAt: _allVaults![vaultIndex].CreatedAt,
            UpdatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }

      _safeNotifyListeners();
    } catch (e) {
      print('Error updating vault title: $e');
      rethrow;
    }
  }

  // Create new vault
  Future<void> createVault(
    String title,
    String vaultIcon,
    String vaultColor,
  ) async {
    try {
      await _dbService.createVault(title, vaultIcon, vaultColor);

      // Refresh all vaults to include the new one
      await loadAllVaults();
    } catch (e) {
      print('Error creating vault: $e');
      rethrow;
    }
  }

  // Delete vault
  Future<void> deleteVault(int vaultId) async {
    try {
      await _dbService.deleteVault(vaultId);

      // Remove from cache
      if (_allVaults != null) {
        _allVaults!.removeWhere((vault) => vault.VaultId == vaultId);
      }

      _safeNotifyListeners();
    } catch (e) {
      print('Error deleting vault: $e');
      rethrow;
    }
  }

  // Get vault by ID
  Vault? getVaultById(int vaultId) {
    if (_allVaults == null) return null;

    try {
      return _allVaults!.firstWhere((vault) => vault.VaultId == vaultId);
    } catch (e) {
      return null;
    }
  }

  // Clear all caches (useful for logout or major data changes)
  void clearAllCaches() {
    _allVaults = null;
    _isLoadingAllVaults = false;
    _safeNotifyListeners();
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    clearAllCaches();
    await loadAllVaults();
  }
}
