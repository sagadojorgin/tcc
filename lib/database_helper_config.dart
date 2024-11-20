import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> getDatabase() async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE config (
          id INTEGER PRIMARY KEY,
          consumptionLimit INTEGER,
          isDarkTheme INTEGER DEFAULT 0, -- 0 para tema claro, 1 para tema escuro
          costPerKwh REAL DEFAULT 0.0 -- Adicionando o custo do kilowatt/hora
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
          ALTER TABLE config ADD COLUMN isDarkTheme INTEGER DEFAULT 0
        ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
          ALTER TABLE config ADD COLUMN costPerKwh REAL DEFAULT 0.0
        ''');
        }
      },
      version: 3, // Atualize a versão para 3
    );
  }

  Future<void> saveConsumptionLimit(int limit) async {
    final db = await getDatabase();
    await db.insert(
      'config',
      {'consumptionLimit': limit},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> getConsumptionLimit() async {
    final db = await getDatabase();
    final result = await db.query('config', columns: ['consumptionLimit']);
    if (result.isNotEmpty) {
      return result.first['consumptionLimit'] as int?;
    }
    return null;
  }

  Future<void> saveThemePreference(bool isDarkTheme) async {
    final db = await getDatabase();
    await db.insert(
      'config',
      {'isDarkTheme': isDarkTheme ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> getThemePreference() async {
    final db = await getDatabase();
    final result = await db.query('config', columns: ['isDarkTheme']);
    if (result.isNotEmpty) {
      return result.first['isDarkTheme'] == 1;
    }
    return false; // Retorna claro por padrão, caso não exista valor salvo
  }

  Future<void> saveCostPerKwh(double cost) async {
    final db = await getDatabase();
    await db.insert(
      'config',
      {'costPerKwh': cost},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double?> getCostPerKwh() async {
    final db = await getDatabase();
    final result = await db.query('config', columns: ['costPerKwh']);
    if (result.isNotEmpty) {
      return result.first['costPerKwh'] as double?;
    }
    return null; // Retorna null se não encontrar nenhum valor
  }
}

//isso aqui vai tudo para a main dps