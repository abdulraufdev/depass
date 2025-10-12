import 'dart:io';
import 'package:depass/models/note.dart';
import 'package:depass/models/pass.dart';
import 'package:depass/models/vault.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DBService {
  DBService._();
  static final DBService instance = DBService._();

  static Database? _database;
  static const String _databaseName = 'depass.db';
  static const int _databaseVersion = 1;
  
  static String _databasePassword = 'depass';

  // Table names
  static const String _notesTable = 'notes';
  static const String _vaultsTable = 'vaults';
  static const String _passTable = 'pass';

  // Get database instance - Thread-safe initialization
  Future<Database> getDB() async {
    if (_database != null) {
      return _database!;
    }
    // Start initialization
    _database = await _openDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _openDatabase() async {
    final databasesPath = await getApplicationDocumentsDirectory();
    final path = join(databasesPath.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      password: _databasePassword,
      onCreate: _onCreate,
    );
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create vaults table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_vaultsTable (
        VaultId INTEGER PRIMARY KEY AUTOINCREMENT,
        VaultTitle TEXT NOT NULL,
        CreatedAt INTEGER NOT NULL,
        UpdatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_passTable (
        PassId INTEGER PRIMARY KEY AUTOINCREMENT,
        VaultId INTEGER NOT NULL,
        PassTitle TEXT NOT NULL,
        CreatedAt INTEGER NOT NULL,
        FOREIGN KEY (VaultId) REFERENCES $_vaultsTable (VaultId)
      )
    ''');

    // Create notes table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_notesTable (
        NoteId INTEGER PRIMARY KEY AUTOINCREMENT,
        Description TEXT NOT NULL,
        Type TEXT NOT NULL CHECK (Type IN ('text', 'password', 'email', 'website')),
        CreatedAt INTEGER NOT NULL,
        UpdatedAt INTEGER NOT NULL,
        PassId INTEGER,
        FOREIGN KEY (PassId) REFERENCES $_passTable (PassId)
      )
    ''');

    // Create default vault
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(_vaultsTable, {
      'VaultTitle': 'Default',
      'CreatedAt': now,
      'UpdatedAt': now,
    });
  }

  // // Handle database open
  // Future<void> _onOpen(Database db) async {
  //   // Enable foreign key constraints
  //   await db.execute('PRAGMA foreign_keys = ON');
  // }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Delete database file
  Future<void> deleteDatabase() async {
    // Close database first if it's open
    await close();

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _database = null;
  }

  // ========== VAULT CRUD OPERATIONS ==========

  // Create a new vault
  Future<void> createVault(String title, {int? vaultId}) async {
    final db = await getDB();
    if (vaultId != null) {
      await db.insert(_vaultsTable, {
        'VaultId': vaultId,
        'VaultTitle': title,
        'CreatedAt': DateTime.now().millisecondsSinceEpoch,
        'UpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await db.insert(_vaultsTable, {
        'VaultTitle': title,
        'CreatedAt': DateTime.now().millisecondsSinceEpoch,
        'UpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // Get all vaults
  Future<List<Vault>> getAllVaults() async {
    final db = await getDB();
    final List<Map<String, dynamic>> maps = await db.query(_vaultsTable);
    return List.generate(maps.length, (i) {
      return Vault.fromMap(maps[i]);
    });
  }

  // Get vault by ID
  Future<Vault?> getVaultById(int id) async {
    final db = await getDB();
    final List<Map<String, dynamic>> maps = await db.query(
      _vaultsTable,
      where: 'VaultId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Vault.fromMap(maps.first);
    }
    return null;
  }

  // Update vault
  Future<void> updateVault(int id, String newTitle) async {
    final db = await getDB();
    await db.update(
      _vaultsTable,
      {
        'VaultTitle': newTitle,
        'UpdatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'VaultId = ?',
      whereArgs: [id],
    );
  }

  // Delete vault (only if the vault is empty)
  Future<bool> deleteVault(int id) async {
    final db = await getDB();

    // Check if the vault is empty
    final List<Map<String, dynamic>> passes = await db.query(
      _passTable,
      where: 'VaultId = ?',
      whereArgs: [id],
    );

    if (passes.isEmpty) {
      // If empty, delete the vault
      await db.delete(_vaultsTable, where: 'VaultId = ?', whereArgs: [id]);
      return true;
    } else {
      // If not empty, you might want to handle this case
      return false;
    }
  }

  // ========== PASS CRUD OPERATIONS ==========

  // Create a new pass


  // Get pass by Id
  Future<List<Pass>> getAllPasses() async {
    final db = await getDB();
    final List<Map<String, dynamic>> maps = await db.query(_passTable);
    return List.generate(maps.length, (i) {
      return Pass.fromMap(maps[i]);
    });
  }

  Future<Pass> getPassById(int passId) async {
    final db = await getDB();
    final List<Map<String, dynamic>> maps = await db.query(_passTable, where: 'PassId = ?', whereArgs: [passId]);
    return Pass.fromMap(maps.first);
  }

  // Update pass
  Future<void> updatePass(int passId, String newTitle) async {
    final db = await getDB();
    await db.update(
      _passTable,
      {
        'PassTitle': newTitle,
      },
      where: 'PassId = ?',
      whereArgs: [passId],
    );
  }

  // Delete pass
  Future<void> deletePass(int id) async {
    final db = await getDB();
    
    // First delete all notes associated with this pass
    await db.delete(_notesTable, where: 'PassId = ?', whereArgs: [id]);
    
    // Then delete the pass itself
    await db.delete(_passTable, where: 'PassId = ?', whereArgs: [id]);
  }

  // move pass
  Future<void> movePass(int passId, int vaultId) async {
    final db = await getDB();
    await db.update(
        _passTable,
        {
          'VaultId': vaultId,
        },
        where: 'PassId = ?',
        whereArgs: [passId],
      );
  }

  // ========== NOTE CRUD OPERATIONS ==========

  // Create a new note
  Future<void> createNote({
    required String description,
    required String type,
    required int passId,
  }) async {
    final db = await getDB();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(_notesTable, {
      'Description': description,
      'Type': type,
      'CreatedAt': now,
      'UpdatedAt': now,
      'PassId': passId,
    });
  }

  // Create bulk notes through transaction
  Future<void> createBulkNotes({
    required List<Map<String, dynamic>> notes,
    required String title,
    int vaultId = 1,
  }) async {
    final db = await getDB();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db
        .transaction((tx) async {
      final passId = await tx.insert(_passTable, {
        'PassTitle': title,
        'CreatedAt': now,
        'VaultId': vaultId, // Default vault ID
      });
          for (Map<String, dynamic> note in notes) {
            await tx.rawInsert(
              '''
      INSERT INTO $_notesTable 
      (Description, Type, CreatedAt, UpdatedAt, PassId) 
      VALUES(?, ?, ?, ?, ?);
      ''',
              [note['Description'], note['Type'], now, now, passId],
            );
          }
        })
        .whenComplete(() {
          print("transaction completeeeed.");
        });
  }

  // Get all notes
  Future<List<Note>> getAllNotes() async {
    final db = await getDB();
    final List<Map<String, dynamic>> maps = await db.query(_notesTable);
    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  // Get note by ID
  Future<Note?> getNoteById(int id) async {
    final db = await getDB();
    final List<Map<String, dynamic>> maps = await db.query(
      _notesTable,
      where: 'NoteId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  // Get notes by pass ID
  Future<List<Map<String, dynamic>>> getNotesByPassId(int passId) async {
    final db = await getDB();
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT n.NoteId as NoteId, n.CreatedAt as CreatedAt, n.Description as Description, n.Type as Type, p.PassTitle as PassTitle, p.PassId as PassId FROM $_notesTable as n 
    INNER JOIN $_passTable as p on n.PassId = p.passId 
    WHERE p.PassId = ?''',
      [passId],
    );

    return maps;
  }

  // Update note
  Future<void> updateNote(int id, String newDescription, String newType) async {
    final db = await getDB();
    await db.update(
      _notesTable,
      {
        'Description': newDescription,
        'Type': newType,
        'UpdatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'NoteId = ?',
      whereArgs: [id],
    );
  }

  // Delete note
  Future<void> deleteNote(int id) async {
    final db = await getDB();
    await db.delete(_notesTable, where: 'NoteId = ?', whereArgs: [id]);
  }

  // ========== UTILITY FUNCTIONS ==========

  // Get total pass count
  Future<int> getTotalPassCount() async {
    final db = await getDB();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_passTable',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get pass count by vault
  Future<int> getPassCountByVault(int vaultId) async {
    final db = await getDB();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_passTable WHERE VaultID = ?',
      [vaultId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Backup database to JSON

  // Restore database from JSON

  // Clean up old notes (optional maintenance function)
  Future<void> clearAllData() async {
    final db = await getDB();
    await db.delete(_notesTable);
    await db.delete(_passTable);
    await db.delete(_vaultsTable);
    
  }
}
