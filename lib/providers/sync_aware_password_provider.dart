import 'package:depass/services/sync_chain_service.dart';
import 'package:depass/services/database_service.dart';
import 'package:depass/providers/password_provider.dart';
import 'package:depass/models/note.dart';
import 'package:depass/models/sync_chain.dart';
import 'package:flutter/foundation.dart';

/// Extension to integrate sync chain functionality with password provider
extension SyncChainIntegration on PasswordProvider {
  
  static final SyncChainService _syncChainService = SyncChainService();
  static final DBService _dbService = DBService.instance;
  
  /// Sync password update to connected devices
  Future<void> syncPasswordUpdateToChain(int passId) async {
    try {
      if (_syncChainService.currentSyncChain?.status != SyncChainStatus.connected) {
        return; // Not connected, skip sync
      }
      
      // Get the updated password data
      final allPasses = await _dbService.getAllPasses();
      final pass = allPasses.where((p) => p.PassId == passId).firstOrNull;
      
      if (pass != null) {
        final notesData = await _dbService.getNotesByPassId(passId);
        final notes = notesData.map((noteData) => Note(
          NoteId: noteData['NoteId'] ?? 0,
          Description: noteData['Description'] ?? '',
          Type: noteData['Type'] ?? '',
          PassId: noteData['PassId'] ?? 0,
          CreatedAt: noteData['CreatedAt'] ?? 0,
          UpdatedAt: noteData['UpdatedAt'] ?? 0,
        )).toList();
        
        await _syncChainService.syncPasswordUpdate(pass, notes);
      }
    } catch (e) {
      debugPrint('Error syncing password update: $e');
    }
  }
  
  /// Initialize sync chain service and set up listeners
  Future<void> initializeSyncChain() async {
    try {
      await _syncChainService.initialize();
      
      // Listen for password sync messages
      _syncChainService.messageStream.listen((message) {
        if (message.type == SyncMessageType.passwordUpdate || 
            message.type == SyncMessageType.passwordSync) {
          // Refresh all data when receiving sync updates
          refreshAllData();
        }
      });
    } catch (e) {
      debugPrint('Error initializing sync chain: $e');
    }
  }
  
  /// Get sync chain service instance
  SyncChainService get syncChainService => _syncChainService;
}

/// Convenience methods for sync-aware password operations
class SyncAwarePasswordProvider extends PasswordProvider {
  
  final SyncChainService _syncChainService = SyncChainService();
  
  @override
  Future<void> updatePasswordTitle(int passId, String newTitle) async {
    await super.updatePasswordTitle(passId, newTitle);
    await _syncPasswordUpdate(passId);
  }
  
  @override
  Future<void> updateNote(int noteId, String newDescription, String type) async {
    await super.updateNote(noteId, newDescription, type);
    
    // Find the pass ID for this note to sync the entire password
    final allPasses = await DBService.instance.getAllPasses();
    for (final pass in allPasses) {
      final notes = await DBService.instance.getNotesByPassId(pass.PassId);
      if (notes.any((note) => note['NoteId'] == noteId)) {
        await _syncPasswordUpdate(pass.PassId);
        break;
      }
    }
  }
  
  @override
  Future<void> createNote({
    required String description,
    required String type,
    required int passId,
  }) async {
    await super.createNote(description: description, type: type, passId: passId);
    await _syncPasswordUpdate(passId);
  }
  
  @override
  Future<void> createPassword({
    required List<Map<String, dynamic>> notes,
    required String title,
    int vaultId = 1,
  }) async {
    await super.createPassword(notes: notes, title: title, vaultId: vaultId);
    
    // Find the newly created password and sync it
    final allPasses = await DBService.instance.getAllPasses();
    final newPass = allPasses.where((p) => p.PassTitle == title).lastOrNull;
    if (newPass != null) {
      await _syncPasswordUpdate(newPass.PassId);
    }
  }
  
  @override
  Future<void> movePassword(int passId, int newVaultId) async {
    await super.movePassword(passId, newVaultId);
    await _syncPasswordUpdate(passId);
  }
  
  /// Helper method to sync password updates
  Future<void> _syncPasswordUpdate(int passId) async {
    try {
      if (_syncChainService.currentSyncChain?.status != SyncChainStatus.connected) {
        return; // Not connected, skip sync
      }
      
      // Get the updated password data
      final allPasses = await DBService.instance.getAllPasses();
      final pass = allPasses.where((p) => p.PassId == passId).firstOrNull;
      
      if (pass != null) {
        final notesData = await DBService.instance.getNotesByPassId(passId);
        final notes = notesData.map((noteData) => Note(
          NoteId: noteData['NoteId'] ?? 0,
          Description: noteData['Description'] ?? '',
          Type: noteData['Type'] ?? '',
          PassId: noteData['PassId'] ?? 0,
          CreatedAt: noteData['CreatedAt'] ?? 0,
          UpdatedAt: noteData['UpdatedAt'] ?? 0,
        )).toList();
        
        await _syncChainService.syncPasswordUpdate(pass, notes);
      }
    } catch (e) {
      debugPrint('Error syncing password update: $e');
    }
  }
}