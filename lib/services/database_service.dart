import 'dart:io';
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
      CREATE TABLE $_vaultsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        color TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create notes table
    await db.execute('''
      CREATE TABLE $_notesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT,
        tags TEXT,
        isPinned INTEGER NOT NULL DEFAULT 0,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        color TEXT,
        vaultId INTEGER,
        FOREIGN KEY (vaultId) REFERENCES $_vaultsTable (id) ON DELETE SET NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_notes_title ON $_notesTable (title)');
    await db.execute('CREATE INDEX idx_notes_category ON $_notesTable (category)');
    await db.execute('CREATE INDEX idx_notes_vault ON $_notesTable (vaultId)');
    await db.execute('CREATE INDEX idx_notes_pinned ON $_notesTable (isPinned)');
    await db.execute('CREATE INDEX idx_notes_favorite ON $_notesTable (isFavorite)');
    await db.execute('CREATE INDEX idx_notes_created ON $_notesTable (createdAt)');
    await db.execute('CREATE INDEX idx_notes_updated ON $_notesTable (updatedAt)');

    // Create default vault
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(_vaultsTable, {
      'name': 'Default',
      'description': 'Default vault for notes',
      'createdAt': now,
      'updatedAt': now,
      'isDefault': 1,
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
  

  // Get all vaults
  

  // Get vault by ID
  
  // Get default vault
  

  // Update vault
  
  // Delete vault (and move its notes to default vault)
  
    // Move notes to default vault
  

  // ========== NOTE CRUD OPERATIONS ==========

  // Create a new note


  // Get all notes

  // Get note by ID

  // Get notes by vault ID
  
  // Get pinned notes
  

  // Get favorite notes


  // Get notes by category
 

  // Search notes by title and content


  // Search notes by tags


  // Get recent notes (last 30 days)
  

  // Update note


  // Toggle note pin status


  // Toggle note favorite status


  // Move note to vault


  // Delete note

  // Delete notes by vault ID


  // ========== UTILITY FUNCTIONS ==========

  // Get total notes count


  // Get notes count by vault


  // Get all unique categories
  

  // Get all unique tags


  // Get database statistics


  // Backup database to JSON


  // Restore database from JSON


  // Clean up old notes (optional maintenance function)
}