import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String _dbName = 'tasks.db';
  static const int _dbVersion = 1;

  static const String tableTask = 'tasks';
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colDescription = 'description';
  static const String colPriority = 'priority';
  static const String colIsDone = 'is_done';
  static const String colCreatedAt = 'created_at';

  /// الحصول على قاعدة البيانات (تُنشأ عند أول استخدام)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// تهيئة قاعدة البيانات وإنشاء الجداول
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// إنشاء الجداول عند إنشاء قاعدة البيانات لأول مرة
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTask (
        $colId        INTEGER PRIMARY KEY AUTOINCREMENT,
        $colTitle     TEXT    NOT NULL,
        $colDescription TEXT  DEFAULT '',
        $colPriority  TEXT    DEFAULT 'متوسط',
        $colIsDone    INTEGER DEFAULT 0,
        $colCreatedAt TEXT    DEFAULT (datetime('now'))
      )
    ''');
  }

  /// ترقية قاعدة البيانات عند تغيير الإصدار
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // مثال: إضافة عمود جديد عند الترقية
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE $tableTask ADD COLUMN due_date TEXT');
    // }
  }

  // ─────────────────────────────────────────
  //  CRUD Operations
  // ─────────────────────────────────────────

  /// إدراج مهمة جديدة — يُعيد id السجل المُضاف
  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert(
      tableTask,
      task,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// جلب جميع المهام مُرتّبةً (غير المكتملة أولاً، ثم حسب التاريخ)
  Future<List<Map<String, dynamic>>> fetchAllTasks() async {
    final db = await database;
    return await db.query(
      tableTask,
      orderBy: '$colIsDone ASC, $colCreatedAt DESC',
    );
  }

  /// جلب مهمة واحدة بالمعرّف
  Future<Map<String, dynamic>?> fetchTaskById(int id) async {
    final db = await database;
    final result = await db.query(
      tableTask,
      where: '$colId = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// جلب المهام حسب حالة الإنجاز
  Future<List<Map<String, dynamic>>> fetchTasksByStatus(bool isDone) async {
    final db = await database;
    return await db.query(
      tableTask,
      where: '$colIsDone = ?',
      whereArgs: [isDone ? 1 : 0],
      orderBy: '$colCreatedAt DESC',
    );
  }

  /// جلب المهام حسب الأولوية
  Future<List<Map<String, dynamic>>> fetchTasksByPriority(String priority) async {
    final db = await database;
    return await db.query(
      tableTask,
      where: '$colPriority = ?',
      whereArgs: [priority],
      orderBy: '$colCreatedAt DESC',
    );
  }

  /// تحديث مهمة — يُعيد عدد الصفوف المُحدَّثة
  Future<int> updateTask(int id, Map<String, dynamic> values) async {
    final db = await database;
    return await db.update(
      tableTask,
      values,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// تبديل حالة الإنجاز (مكتملة / غير مكتملة)
  Future<int> toggleTaskDone(int id, bool currentStatus) async {
    final db = await database;
    return await db.update(
      tableTask,
      {colIsDone: currentStatus ? 0 : 1},
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// حذف مهمة بالمعرّف — يُعيد عدد الصفوف المحذوفة
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      tableTask,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// حذف جميع المهام المكتملة
  Future<int> deleteCompletedTasks() async {
    final db = await database;
    return await db.delete(
      tableTask,
      where: '$colIsDone = ?',
      whereArgs: [1],
    );
  }

  /// إحصائيات سريعة: الكل / المكتملة / غير المكتملة
  Future<Map<String, int>> getTaskStats() async {
    final db = await database;

    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $tableTask');
    final doneResult  = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableTask WHERE $colIsDone = 1');
    final pendingResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableTask WHERE $colIsDone = 0');

    return {
      'total':   Sqflite.firstIntValue(totalResult)   ?? 0,
      'done':    Sqflite.firstIntValue(doneResult)    ?? 0,
      'pending': Sqflite.firstIntValue(pendingResult) ?? 0,
    };
  }

  /// إغلاق قاعدة البيانات (استخدم عند الحاجة فقط)
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
