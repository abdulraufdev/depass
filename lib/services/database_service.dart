import 'dart:io';
import 'package:depass/models/note.dart';
import 'package:depass/models/vault.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _database;
  static Future<Database>? _initializationFuture;
  static const String _databaseName = 'depass_notes.db';
  static const int _databaseVersion = 1;

  // Database password for encryption (in production, this should be derived from user's master password)
  static const String _databasePassword = 'your_secure_database_password';

  // Table names
  static const String _notesTable = 'notes';
  static const String _vaultsTable = 'vaults';
  static const String _passTable = 'pass';

  // Get database instance - Thread-safe initialization
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    
    // If initialization is already in progress, wait for it
    if (_initializationFuture != null) {
      return await _initializationFuture!;
    }
    
    // Start initialization
    _initializationFuture = _initDatabase();
    _database = await _initializationFuture!;
    _initializationFuture = null;
    
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      password: _databasePassword,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
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

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema migrations here
    if (oldVersion < 2) {
      // Example: Add new column in version 2
      // await db.execute('ALTER TABLE $_notesTable ADD COLUMN newColumn TEXT');
    }
  }

  // Handle database open
  Future<void> _onOpen(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _initializationFuture = null;
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
  Future<void> createVault(String title) async {
    final db = await database;
    await db.insert(_vaultsTable, {
      'VaultTitle': title,
      'CreatedAt': DateTime.now().millisecondsSinceEpoch,
      'UpdatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Get all vaults
  Future<List<Vault>> getAllVaults() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_vaultsTable);
    return List.generate(maps.length, (i) {
      return Vault.fromMap(maps[i]);
    });
  }

  // Get vault by ID
  Future<Vault?> getVaultById(int id) async {
    final db = await database;
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
    final db = await database;
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
  Future<void> deleteVault(int id) async {
    final db = await database;

    // Check if the vault is empty
    final List<Map<String, dynamic>> passes = await db.query(
      _passTable,
      where: 'VaultId = ?',
      whereArgs: [id],
    );

    if (passes.isEmpty) {
      // If empty, delete the vault
      await db.delete(
        _vaultsTable,
        where: 'VaultId = ?',
        whereArgs: [id],
      );
    } else {
      // If not empty, you might want to handle this case
      // For example, you could show a message to the user
    }
  }

  // ========== NOTE CRUD OPERATIONS ==========

  // Create a new note
  Future<void> createNote({
    required String description,
    required String type,
    int? passId,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(_notesTable, {
      'Description': description,
      'Type': type,
      'CreatedAt': now,
      'UpdatedAt': now,
      'PassId': passId,
    });
  }

  // Get all notes
  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_notesTable);
    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  // Get note by ID
  Future<Note?> getNoteById(int id) async {
    final db = await database;
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
  Future<List<Note>> getNotesByPassId(int passId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _notesTable,
      where: 'PassId = ?',
      whereArgs: [passId],
    );
    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  // Update note
  Future<void> updateNote(int id, String newDescription, String newType) async {
    final db = await database;
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
    final db = await database;
    await db.delete(
      _notesTable,
      where: 'NoteId = ?',
      whereArgs: [id],
    );
  }

  // ========== UTILITY FUNCTIONS ==========

  // Get total pass count
  Future<int> getTotalPassCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_passTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }


  // Get pass count by vault
  Future<int> getPassCountByVault(int vaultId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_passTable WHERE VaultID = ?',
      [vaultId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }


  // Backup database to JSON


  // Restore database from JSON


  // Clean up old notes (optional maintenance function)
}