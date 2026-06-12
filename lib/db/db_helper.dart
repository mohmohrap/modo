import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expenses.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        expense_date TEXT NOT NULL,
        expense_time TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<int> addExpense(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('expenses', data);
  }

  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await database;
    return db.query(
      'expenses',
      orderBy: 'expense_date DESC, expense_time DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getRecentExpenses({int limit = 5}) async {
    final db = await database;
    return db.query(
      'expenses',
      orderBy: 'expense_date DESC, expense_time DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions() async {
    return getRecentExpenses(limit: 5);
  }

  Future<double> getTodaySpending() async {
    final db = await database;
    final res = await db.rawQuery(
      "SELECT SUM(amount) as total FROM expenses WHERE expense_date = date('now')"
    );
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getWeekSpending() async {
    final db = await database;
    final res = await db.rawQuery(
      "SELECT SUM(amount) as total FROM expenses WHERE expense_date >= date('now', 'weekday 0', '-7 days')"
    );
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getMonthSpending() async {
    final db = await database;
    final res = await db.rawQuery(
      "SELECT SUM(amount) as total FROM expenses WHERE strftime('%Y-%m', expense_date) = strftime('%Y-%m', 'now')"
    );
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, dynamic>?> getTopCategoryThisMonth() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      WHERE strftime('%Y-%m', expense_date) = strftime('%Y-%m', 'now')
      GROUP BY category
      ORDER BY total DESC
      LIMIT 1
    ''');
    return res.isNotEmpty ? res.first : null;
  }

  Future<List<Map<String, dynamic>>> getExpensesByDateRange(
    String from,
    String to,
  ) async {
    final db = await database;
    return db.rawQuery('''
      SELECT * FROM expenses
      WHERE expense_date BETWEEN ? AND ?
      ORDER BY expense_date DESC, expense_time DESC
    ''', [from, to]);
  }

  Future<List<Map<String, dynamic>>> getCategoryTotalsThisMonth() async {
    final db = await database;

    return db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      WHERE strftime('%Y-%m', expense_date) = strftime('%Y-%m','now')
      GROUP BY category
      ORDER BY total DESC
    ''');
  }
}
