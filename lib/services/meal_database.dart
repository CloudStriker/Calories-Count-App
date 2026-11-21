import 'package:calsnap/models/meal_entry.dart';
import 'package:calsnap/utils/date_format.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

abstract class MealStore {
  Future<List<MealEntry>> getMealsForDate(DateTime date);
  Future<void> insertMeal(MealEntry meal);
  Future<void> updateSyncStatus({
    required String mealId,
    required HealthSyncStatus status,
    String? error,
    String? recordId,
  });
  Future<void> deleteMeal(String mealId);
}

class SqliteMealStore implements MealStore {
  static const String _dbName = 'calsnap.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'meals';

  Database? _database;
  Future<Database>? _openingDb;

  Future<Database> _getDb() async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    return _openingDb ??= _open();
  }

  Future<Database> _open() async {
    final dbPath = p.join(await getDatabasesPath(), _dbName);
    final opened = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            eaten_at INTEGER NOT NULL,
            category TEXT NOT NULL,
            title TEXT NOT NULL,
            photo_path TEXT,
            user_note TEXT,
            items_json TEXT NOT NULL,
            total_calories REAL NOT NULL,
            total_protein REAL NOT NULL,
            total_carbs REAL NOT NULL,
            total_fat REAL NOT NULL,
            sync_status TEXT NOT NULL,
            sync_error TEXT,
            health_record_id TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_meals_eaten_at ON $_tableName(eaten_at)',
        );
      },
    );
    _database = opened;
    return opened;
  }

  @override
  Future<List<MealEntry>> getMealsForDate(DateTime date) async {
    final db = await _getDb();
    final dayStart = startOfDay(date);
    final nextDayStart = dayStart.add(const Duration(days: 1));
    final rows = await db.query(
      _tableName,
      where: 'eaten_at >= ? AND eaten_at < ?',
      whereArgs: <Object?>[
        dayStart.millisecondsSinceEpoch,
        nextDayStart.millisecondsSinceEpoch,
      ],
      orderBy: 'eaten_at DESC',
    );
    return rows.map(MealEntry.fromDbMap).toList();
  }

  @override
  Future<void> insertMeal(MealEntry meal) async {
    final db = await _getDb();
    await db.insert(
      _tableName,
      meal.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateSyncStatus({
    required String mealId,
    required HealthSyncStatus status,
    String? error,
    String? recordId,
  }) async {
    final db = await _getDb();
    await db.update(
      _tableName,
      <String, Object?>{
        'sync_status': status.storageKey,
        'sync_error': error,
        if (recordId != null) 'health_record_id': recordId,
      },
      where: 'id = ?',
      whereArgs: <Object?>[mealId],
    );
  }

  @override
  Future<void> deleteMeal(String mealId) async {
    final db = await _getDb();
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: <Object?>[mealId],
    );
  }
}
