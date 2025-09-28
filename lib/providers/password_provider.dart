import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/models/pass.dart';

class PasswordProvider extends ChangeNotifier {
  final DBService _dbService = DBService.instance;
  
  // Cache for password data by ID
  final Map<int, List<Map<String, dynamic>>> _passwordCache = {};
  
  // Cache for all passes list
  List<Pass>? _allPasses;
  
  // Loading states
  final Map<int, bool> _loadingStates = {};
  bool _isLoadingAllPasses = false;
  
  // Current selected vault ID
  int _currentVaultId = 0;

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
  List<Pass>? get allPasses => _allPasses;
  bool get isLoadingAllPasses => _isLoadingAllPasses;
  int get currentVaultId => _currentVaultId;
  
  List<Map<String, dynamic>>? getPasswordData(int passId) {
    return _passwordCache[passId];
  }
  
  bool isLoadingPassword(int passId) {
    return _loadingStates[passId] ?? false;
  }

  // Load all passes
  Future<void> loadAllPasses() async {
    _isLoadingAllPasses = true;
    _safeNotifyListeners();
    
    try {
      final passes = await _dbService.getAllPasses();
      _allPasses = passes;
    } catch (e) {
      print('Error loading all passes: $e');
      _allPasses = [];
    } finally {
      _isLoadingAllPasses = false;
      _safeNotifyListeners();
    }
  }

  // Set current vault and load filtered passes
  Future<void> setCurrentVault(int vaultId) async {
    print('setCurrentVault called with vaultId: $vaultId, current: $_currentVaultId, allPasses: ${_allPasses?.length}');
    if (_currentVaultId != vaultId || _allPasses == null) {
      _currentVaultId = vaultId;
      await loadFilteredPasses(vaultId);
    } else {
      print('Skipping load - vault already set and passes loaded');
    }
  }

  // Load filtered passes by vault ID
  Future<void> loadFilteredPasses(int vaultId) async {
    _currentVaultId = vaultId; // Update current vault ID
    _isLoadingAllPasses = true;
    _safeNotifyListeners();
    
    try {
      print('Loading filtered passes for vaultId: $vaultId');
      final passes = await _dbService.getAllPasses();
      _allPasses = passes.where((pass) => vaultId == 0 || pass.VaultId == vaultId).toList();
      print('Loaded ${_allPasses?.length ?? 0} passes for vaultId: $vaultId');
    } catch (e) {
      print('Error loading all passes: $e');
      _allPasses = [];
    } finally {
      _isLoadingAllPasses = false;
      _safeNotifyListeners();
    }
  }

  // Load specific password data
  Future<void> loadPasswordData(int passId) async {
    _loadingStates[passId] = true;
    _safeNotifyListeners();
    
    try {
      final data = await _dbService.getNotesByPassId(passId);
      _passwordCache[passId] = data;
    } catch (e) {
      print('Error loading password data for ID $passId: $e');
      _passwordCache[passId] = [];
    } finally {
      _loadingStates[passId] = false;
      _safeNotifyListeners();
    }
  }

  // Update password title
  Future<void> updatePasswordTitle(int passId, String newTitle) async {
    try {
      await _dbService.updatePass(passId, newTitle);
      
      // Update cached data
      if (_passwordCache.containsKey(passId)) {
        for (var item in _passwordCache[passId]!) {
          item['PassTitle'] = newTitle;
        }
      }
      
      // Update all passes cache
      if (_allPasses != null) {
        final passIndex = _allPasses!.indexWhere((pass) => pass.PassId == passId);
        if (passIndex != -1) {
          _allPasses![passIndex] = Pass(
            PassId: _allPasses![passIndex].PassId,
            PassTitle: newTitle,
            CreatedAt: _allPasses![passIndex].CreatedAt,
            VaultId: _allPasses![passIndex].VaultId,
          );
        }
      }
      
      _safeNotifyListeners();
    } catch (e) {
      print('Error updating password title: $e');
      rethrow;
    }
  }

  // Update note
  Future<void> updateNote(int noteId, String newDescription, String type) async {
    try {
      await _dbService.updateNote(noteId, newDescription, type);
      
      // Update cached data
      for (var passwordData in _passwordCache.values) {
        for (var note in passwordData) {
          if (note['NoteId'] == noteId) {
            note['Description'] = newDescription;
            note['Type'] = type;
            note['UpdatedAt'] = DateTime.now().millisecondsSinceEpoch;
            break;
          }
        }
      }
      
      _safeNotifyListeners();
    } catch (e) {
      print('Error updating note: $e');
      rethrow;
    }
  }

  // Create note
  Future<void> createNote({
    required String description,
    required String type,
    required int passId,
  }) async {
    try {
      await _dbService.createNote(
        description: description,
        type: type,
        passId: passId,
      );
      
      // Refresh the specific password data to include the new note
      await loadPasswordData(passId);
    } catch (e) {
      print('Error creating note: $e');
      rethrow;
    }
  }

  // Create new password entry
  Future<void> createPassword({
    required List<Map<String, dynamic>> notes,
    required String title,
    int vaultId = 1,
  }) async {
    try {
      await _dbService.createBulkNotes(
        notes: notes,
        title: title,
        vaultId: vaultId,
      );
      
      // Refresh all passes to include the new password
      await loadAllPasses();
    } catch (e) {
      print('Error creating password: $e');
      rethrow;
    }
  }

  // Delete password (if needed)
  Future<void> deletePassword(int passId) async {
    try {
      // Note: You'll need to implement deletePass in DBService
      // await _dbService.deletePass(passId);
      
      // Remove from caches
      _passwordCache.remove(passId);
      _loadingStates.remove(passId);
      
      if (_allPasses != null) {
        _allPasses!.removeWhere((pass) => pass.PassId == passId);
      }
      
      _safeNotifyListeners();
    } catch (e) {
      print('Error deleting password: $e');
      rethrow;
    }
  }

  // Clear specific password cache (useful for forcing refresh)
  void clearPasswordCache(int passId) {
    _passwordCache.remove(passId);
    _loadingStates.remove(passId);
  }

  // Clear all caches (useful for logout or major data changes)
  void clearAllCaches() {
    _passwordCache.clear();
    _loadingStates.clear();
    _allPasses = null;
    _isLoadingAllPasses = false;
    _safeNotifyListeners();
  }

  // Refresh specific password data
  Future<void> refreshPasswordData(int passId) async {
    clearPasswordCache(passId);
    await loadPasswordData(passId);
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    clearAllCaches();
    await loadAllPasses();
  }
}