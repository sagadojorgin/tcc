import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'alarms.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE alarms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_time TEXT,
            end_time TEXT,
            seg INTEGER,
            ter INTEGER,
            qua INTEGER,
            qui INTEGER,
            sex INTEGER,
            sab INTEGER,
            dom INTEGER,
            is_active INTEGER
          )
        ''');
      },
    );
  }

  // Inserção de um novo alarme
  Future<int> insertAlarm(Map<String, dynamic> alarm) async {
    final db = await database;
    int result = await db.insert('alarms', alarm);
    print('Alarme inserido: $alarm');
    return result;
  }

  // Recuperação de todos os alarmes
  Future<List<Map<String, dynamic>>> getAllAlarms() async {
    final db = await database;
    return await db.query('alarms');
  }

  // Atualização de um alarme específico
  Future<int> updateAlarm(int id, Map<String, dynamic> updatedAlarm) async {
    final db = await database;
    int result = await db.update(
      'alarms',
      updatedAlarm,
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Alarme atualizado: ID $id, Novos dados: $updatedAlarm');
    return result;
  }

  // Exclusão de um alarme específico
  Future<int> deleteAlarm(int id) async {
    final db = await database;
    return await db.delete(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

//isso aqui tbm