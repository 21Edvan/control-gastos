import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'category_model.dart';
import 'transaction_model.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('money_control.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de categorías
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // Tabla de transacciones
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        note TEXT,
        payment_method TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Insertar categorías iniciales
    await _insertInitialCategories(db);
  }

  Future<void> _insertInitialCategories(Database db) async {
    final batch = db.batch();

    // Ingresos
    batch.insert('categories', {'name': 'Salario', 'type': 'income'});
    batch.insert('categories', {'name': 'Ingresos extra', 'type': 'income'});
    batch.insert('categories', {'name': 'Freelance', 'type': 'income'});

    // Gastos
    batch.insert('categories', {'name': 'Comida', 'type': 'expense'});
    batch.insert('categories', {'name': 'Transporte', 'type': 'expense'});
    batch.insert('categories', {'name': 'Servicios', 'type': 'expense'});
    batch.insert('categories', {'name': 'Deudas', 'type': 'expense'});
    batch.insert('categories', {'name': 'Renta', 'type': 'expense'});
    batch.insert('categories', {'name': 'Otros', 'type': 'expense'});

    await batch.commit(noResult: true);
  }

  // ────────────────────────────────────────
  // CATEGORIES
  // ────────────────────────────────────────

  Future<List<Category>> getCategoriesByType(String type) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );

    return maps.map((m) => Category.fromMap(m)).toList();
  }

  // ────────────────────────────────────────
  // TRANSACTIONS
  // ────────────────────────────────────────

  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalByTypeForMonth(String type, DateTime month) async {
    final db = await database;

    final firstDay = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);

    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = ?
        AND date >= ?
        AND date < ?
    ''', [
      type,
      firstDay.toIso8601String(),
      nextMonth.toIso8601String(),
    ]);

    final total = result.first['total'] as num?;
    return total?.toDouble() ?? 0.0;
  }

  Future<double> getBalanceForMonth(DateTime month) async {
    final incomes = await getTotalByTypeForMonth('income', month);
    final expenses = await getTotalByTypeForMonth('expense', month);
    return incomes - expenses;
  }
}
