import 'dart:convert';
import 'dart:developer';
import 'package:file_picker/file_picker.dart';
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
    print(
      'setCurrentVault called with vaultId: $vaultId, current: $_currentVaultId, allPasses: ${_allPasses?.length}',
    );
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
      _allPasses = passes
          .where((pass) => vaultId == 0 || pass.VaultId == vaultId)
          .toList();
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
        final passIndex = _allPasses!.indexWhere(
          (pass) => pass.PassId == passId,
        );
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
  Future<void> updateNote(
    int noteId,
    String newDescription,
    String type,
  ) async {
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

  // Move a password to another vault
  Future<void> movePassword(int passId, int newVaultId) async {
    try {
      await _dbService.movePass(passId, newVaultId);
      // Update all passes cache
      if (_allPasses != null) {
        final passIndex = _allPasses!.indexWhere(
          (pass) => pass.PassId == passId,
        );
        if (passIndex != -1) {
          _allPasses![passIndex] = Pass(
            PassId: _allPasses![passIndex].PassId,
            PassTitle: _allPasses![passIndex].PassTitle,
            CreatedAt: _allPasses![passIndex].CreatedAt,
            VaultId: newVaultId,
          );
        }
      }

      _safeNotifyListeners();
    } catch (e) {
      print('Error moving password: $e');
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

  // Export all passwords to JSON
  Future<Map<String, dynamic>> exportToJSON() async {
    try {
      // Ensure we have all passes loaded
      if (_allPasses == null) {
        await loadAllPasses();
      }

      final exportData = <String, dynamic>{
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'total_passwords': _allPasses?.length ?? 0,
        'passwords': <Map<String, dynamic>>[],
      };

      if (_allPasses != null && _allPasses!.isNotEmpty) {
        for (final pass in _allPasses!) {
          // Load password data if not cached
          if (!_passwordCache.containsKey(pass.PassId)) {
            await loadPasswordData(pass.PassId);
          }

          final passwordData = _passwordCache[pass.PassId] ?? [];

          // Group notes by type for better organization
          final Map<String, List<Map<String, dynamic>>> groupedNotes = {};
          for (final noteData in passwordData) {
            final type = noteData['Type'] ?? 'other';
            if (!groupedNotes.containsKey(type)) {
              groupedNotes[type] = [];
            }
            groupedNotes[type]!.add({
              'description': noteData['Description'],
              'created_at': DateTime.fromMillisecondsSinceEpoch(
                noteData['CreatedAt'] ?? 0,
              ).toIso8601String(),
              'updated_at': DateTime.fromMillisecondsSinceEpoch(
                noteData['UpdatedAt'] ?? 0,
              ).toIso8601String(),
            });
          }

          (exportData['passwords'] as List<Map<String, dynamic>>).add({
            'id': pass.PassId,
            'title': pass.PassTitle,
            'vault_id': pass.VaultId,
            'created_at': DateTime.fromMillisecondsSinceEpoch(
              pass.CreatedAt,
            ).toIso8601String(),
            'fields': groupedNotes,
            'total_fields': passwordData.length,
          });
        }
      }

      return exportData;
    } catch (e) {
      print('Error exporting to JSON: $e');
      rethrow;
    }
  }

  // Export specific password to JSON
  Future<Map<String, dynamic>> exportPasswordToJSON(int passId) async {
    try {
      final pass = _allPasses?.firstWhere((p) => p.PassId == passId);
      if (pass == null) {
        throw Exception('Password with ID $passId not found');
      }

      // Load password data if not cached
      if (!_passwordCache.containsKey(passId)) {
        await loadPasswordData(passId);
      }

      final passwordData = _passwordCache[passId] ?? [];

      // Group notes by type
      final Map<String, List<String>> groupedNotes = {};
      for (final noteData in passwordData) {
        final type = noteData['Type'] ?? 'other';
        if (!groupedNotes.containsKey(type)) {
          groupedNotes[type] = [];
        }
        groupedNotes[type]!.add(noteData['Description']);
      }

      return {
        'version': '1.0',
        'export_date': DateTime.now().toIso8601String(),
        'password': {
          'id': pass!.PassId,
          'title': pass.PassTitle,
          'vault_id': pass.VaultId,
          'created_at': DateTime.fromMillisecondsSinceEpoch(
            pass.CreatedAt,
          ).toIso8601String(),
          'fields': groupedNotes,
          'total_fields': passwordData.length,
        },
      };
    } catch (e) {
      print('Error exporting password to JSON: $e');
      rethrow;
    }
  }

  // Save JSON to file
  Future<String> saveJSONToFile(
    Map<String, dynamic> jsonData, {
    String? fileName,
  }) async {
    try {
      ;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultFileName = 'password_export_$timestamp.json';

      final output = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: fileName ?? defaultFileName,
        bytes: utf8.encode(
          const JsonEncoder.withIndent('  ').convert(jsonData),
        ),
      );

      if (output == null) {
        throw 'File save cancelled';
      }

      return output;
    } catch (e) {
      log('Error saving JSON to file: $e');
      rethrow;
    }
  }

  // Helper method to escape CSV values
  String _escapeCsvValue(String value) {
    // If value contains comma, newline, or quote, wrap in quotes and escape quotes
    if (value.contains(',') || value.contains('\\n') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // Export all passwords to CSV file
  Future<String> exportAllPasswordsToCSV() async {
    try {
      final csvData = await exportToCSV();
      return await saveCSVToFile(csvData);
    } catch (e) {
      log('Error exporting all passwords to file: $e');
      rethrow;
    }
  }

  // Export specific password to JSON file
  Future<String> exportPasswordToFile(int passId, {String? fileName}) async {
    try {
      final jsonData = await exportPasswordToJSON(passId);
      final pass = _allPasses?.firstWhere((p) => p.PassId == passId);
      final defaultFileName = 'password_${pass?.PassTitle}.json';
      return await saveJSONToFile(
        jsonData,
        fileName: fileName ?? defaultFileName,
      );
    } catch (e) {
      log('Error exporting password to file: $e');
      rethrow;
    }
  }

  Future<String> exportToCSV() async {
    try {
      // Ensure we have all passes loaded
      if (_allPasses == null) {
        await loadAllPasses();
      }

      // CSV header
      String csvContent =
          'Password ID,Title,Vault ID,Vault Name,Created Date,Field Type,Field Content,Field Created Date\n';

      if (_allPasses != null && _allPasses!.isNotEmpty) {
        for (final pass in _allPasses!) {
          // Load password data if not cached
          if (!_passwordCache.containsKey(pass.PassId)) {
            await loadPasswordData(pass.PassId);
          }

          final passwordData = _passwordCache[pass.PassId] ?? [];
          final vaultData = await _dbService.getVaultById(pass.VaultId);
          final vaultName = vaultData != null ? vaultData.VaultTitle : '';
          final passCreatedDate = DateTime.fromMillisecondsSinceEpoch(
            pass.CreatedAt,
          ).toIso8601String();

          if (passwordData.isEmpty) {
            // Add row even if no password data
            csvContent +=
                '${_escapeCsvValue(pass.PassId.toString())},${_escapeCsvValue(pass.PassTitle)},${_escapeCsvValue(pass.VaultId.toString())},${_escapeCsvValue(vaultName)},${_escapeCsvValue(passCreatedDate)},,,,\n';
          } else {
            // Add a row for each field
            for (final noteData in passwordData) {
              final fieldType = noteData['Type'] ?? 'other';
              final fieldContent = noteData['Description'] ?? '';
              final fieldCreatedDate = DateTime.fromMillisecondsSinceEpoch(
                noteData['CreatedAt'] ?? 0,
              ).toIso8601String();

              csvContent +=
                  '${_escapeCsvValue(pass.PassId.toString())},${_escapeCsvValue(pass.PassTitle)},${_escapeCsvValue(pass.VaultId.toString())},${_escapeCsvValue(vaultName)},${_escapeCsvValue(passCreatedDate)},${_escapeCsvValue(fieldType)},${_escapeCsvValue(fieldContent)},${_escapeCsvValue(fieldCreatedDate)}\n';
            }
          }
        }
      }
      log('CSV export completed, length: \n${csvContent.length}');
      return csvContent;
    } catch (e) {
      log('Error exporting to CSV: $e');
      rethrow;
    }
  }

  Future<String> saveCSVToFile(String csvData) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultFileName = 'depass_export_$timestamp.csv';

      final output = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: defaultFileName,
        bytes: utf8.encode(csvData),
      );

      if (output == null) {
        throw 'File save cancelled';
      }

      return output;
    } catch (e) {
      log('Error saving CSV to file: $e');
      rethrow;
    }
  }
}
