import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class PrivacySettings {
  final int id;
  final double opacity;
  final String mode; // 'dim' or 'slit'
  final int colorValue;
  final double slitHeight;
  final bool autoStartOnBoot;

  PrivacySettings({
    this.id = 1,
    required this.opacity,
    required this.mode,
    required this.colorValue,
    required this.slitHeight,
    this.autoStartOnBoot = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'opacity': opacity,
      'mode': mode,
      'colorValue': colorValue,
      'slitHeight': slitHeight,
      'autoStartOnBoot': autoStartOnBoot ? 1 : 0,
    };
  }

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      id: map['id'] as int? ?? 1,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 0.75,
      mode: map['mode'] as String? ?? 'dim',
      colorValue: map['colorValue'] as int? ?? 0xFF000000,
      slitHeight: (map['slitHeight'] as num?)?.toDouble() ?? 130.0,
      autoStartOnBoot: (map['autoStartOnBoot'] as int? ?? 0) == 1,
    );
  }
}

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'privacy_screen.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table for user settings
        await db.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY,
            opacity REAL NOT NULL,
            mode TEXT NOT NULL,
            colorValue INTEGER NOT NULL,
            slitHeight REAL NOT NULL,
            autoStartOnBoot INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // Table for protection session logs (e.g. tracking how many times & when you shielded in transit)
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            durationSeconds INTEGER NOT NULL,
            mode TEXT NOT NULL
          )
        ''');

        // Seed initial default settings
        await db.insert('settings', {
          'id': 1,
          'opacity': 0.75,
          'mode': 'dim',
          'colorValue': 0xFF000000,
          'slitHeight': 130.0,
          'autoStartOnBoot': 0,
        });
      },
    );
  }

  /// Get current saved settings
  Future<PrivacySettings> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return PrivacySettings.fromMap(maps.first);
    }

    return PrivacySettings(
      opacity: 0.75,
      mode: 'dim',
      colorValue: 0xFF000000,
      slitHeight: 130.0,
    );
  }

  /// Save / Update settings
  Future<void> saveSettings(PrivacySettings settings) async {
    final db = await database;
    await db.insert(
      'settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Log a privacy session (for analytics/history dashboard)
  Future<void> logSession({
    required DateTime timestamp,
    required int durationSeconds,
    required String mode,
  }) async {
    final db = await database;
    await db.insert('sessions', {
      'timestamp': timestamp.toIso8601String(),
      'durationSeconds': durationSeconds,
      'mode': mode,
    });
  }

  /// Get total protected sessions count
  Future<int> getTotalProtectedSessions() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM sessions');
    return Sqflite.firstIntValue(res) ?? 0;
  }
}
