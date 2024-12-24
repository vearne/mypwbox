import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _dbName = 'encrypted_password_manager.db';
  static const _dbVersion = 1;
  static const _tableName = 'passwords';

  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _dbName);

    return await openDatabase(
      path,
      password: 'your-encryption-password', // 加密的密码
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        account TEXT NOT NULL,
        password TEXT NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<int> insert(Map<String, dynamic> row) async {
    final db = await getDatabase();
    return await db.insert(_tableName, row);
  }

  static Future<List<Map<String, dynamic>>> queryAll() async {
    final db = await getDatabase();
    return await db.query(_tableName);
  }

  static Future<int> update(int id, Map<String, dynamic> row) async {
    final db = await getDatabase();
    return await db.update(
      _tableName,
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> delete(int id) async {
    final db = await getDatabase();
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
