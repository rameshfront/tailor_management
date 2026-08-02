import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/customer.dart';
import '../models/measurement.dart';
import '../models/order.dart';
import '../utils/constants.dart';

/// Singleton database helper using sqflite
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile TEXT NOT NULL UNIQUE,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number TEXT NOT NULL UNIQUE,
        customer_id INTEGER NOT NULL,
        order_date TEXT NOT NULL,
        delivery_date TEXT,
        dress_type TEXT NOT NULL,
        dress_name TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        cloth_photo TEXT,
        reference_photo TEXT,
        finished_photo TEXT,
        total_amount REAL NOT NULL DEFAULT 0,
        advance_amount REAL NOT NULL DEFAULT 0,
        payment_status TEXT NOT NULL DEFAULT 'Pending',
        order_status TEXT NOT NULL DEFAULT 'Pending',
        payment_method TEXT,
        delivered_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL UNIQUE,
        chest REAL,
        shoulder REAL,
        neck REAL,
        sleeve REAL,
        waist REAL,
        hip REAL,
        pant_length REAL,
        bottom REAL,
        custom_measurements TEXT DEFAULT '{}',
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Insert default settings
    final batch = db.batch();
    batch.insert('settings', {'key': AppConstants.keyShopName, 'value': AppConstants.defaultShopName});
    batch.insert('settings', {'key': AppConstants.keyOwnerName, 'value': 'Owner'});
    batch.insert('settings', {'key': AppConstants.keyPhone, 'value': ''});
    batch.insert('settings', {'key': AppConstants.keyAddress, 'value': ''});
    batch.insert('settings', {'key': AppConstants.keyCurrency, 'value': AppConstants.defaultCurrency});
    batch.insert('settings', {'key': AppConstants.keyThemeMode, 'value': 'light'});
    await batch.commit(noResult: true);

    // Insert sample data for demo
    await _insertSampleData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now();
    // Sample customers
    final c1 = await db.insert('customers', {
      'name': 'Ravi Kumar',
      'mobile': '9876543210',
      'address': '12 Main Street, Chennai',
      'notes': 'Regular customer',
      'created_at': now.toIso8601String(),
    });
    final c2 = await db.insert('customers', {
      'name': 'Priya Sharma',
      'mobile': '9123456789',
      'address': '45 Park Lane, Chennai',
      'notes': '',
      'created_at': now.toIso8601String(),
    });

    // Sample orders
    final o1 = await db.insert('orders', {
      'order_number': 'ORD2601001',
      'customer_id': c1,
      'order_date': now.subtract(const Duration(days: 5)).toIso8601String(),
      'delivery_date': now.add(const Duration(days: 2)).toIso8601String(),
      'dress_type': 'Shirt',
      'dress_name': 'Formal Shirt',
      'quantity': 2,
      'notes': 'Blue check fabric',
      'total_amount': 1200.0,
      'advance_amount': 600.0,
      'payment_status': 'Partial',
      'order_status': 'Stitching',
      'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
    });
    await db.insert('orders', {
      'order_number': 'ORD2601002',
      'customer_id': c2,
      'order_date': now.subtract(const Duration(days: 2)).toIso8601String(),
      'delivery_date': now.add(const Duration(days: 5)).toIso8601String(),
      'dress_type': 'Salwar Kameez',
      'dress_name': 'Wedding Salwar',
      'quantity': 1,
      'notes': 'Red and gold',
      'total_amount': 3500.0,
      'advance_amount': 1500.0,
      'payment_status': 'Partial',
      'order_status': 'Cutting',
      'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    });

    // Sample measurement
    await db.insert('measurements', {
      'order_id': o1,
      'chest': 40.0,
      'shoulder': 17.0,
      'neck': 15.0,
      'sleeve': 25.0,
      'waist': 36.0,
      'hip': 38.0,
      'pant_length': null,
      'bottom': null,
      'custom_measurements': '{}',
    });
  }

  // ─── CUSTOMERS ───────────────────────────────────────────────────────────

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return db.insert('customers', customer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return db.update('customers', customer.toMap(),
        where: 'id = ?', whereArgs: [customer.id]);
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map(Customer.fromMap).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<Customer?> getCustomerByMobile(String mobile) async {
    final db = await database;
    final maps =
        await db.query('customers', where: 'mobile = ?', whereArgs: [mobile]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'name LIKE ? OR mobile LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map(Customer.fromMap).toList();
  }

  // ─── ORDERS ──────────────────────────────────────────────────────────────

  Future<int> insertOrder(Order order) async {
    final db = await database;
    return db.insert('orders', order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> updateOrder(Order order) async {
    final db = await database;
    return db.update('orders', order.toMap(),
        where: 'id = ?', whereArgs: [order.id]);
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT o.*, c.name AS customer_name, c.mobile AS customer_mobile
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      ORDER BY o.created_at DESC
    ''');
    return maps.map(Order.fromMap).toList();
  }

  Future<Order?> getOrderById(int id) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT o.*, c.name AS customer_name, c.mobile AS customer_mobile
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE o.id = ?
    ''', [id]);
    if (maps.isEmpty) return null;
    final order = Order.fromMap(maps.first);
    final measurement = await getMeasurementByOrderId(id);
    return order.copyWith(measurement: measurement);
  }

  Future<List<Order>> getOrdersByCustomer(int customerId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT o.*, c.name AS customer_name, c.mobile AS customer_mobile
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE o.customer_id = ?
      ORDER BY o.created_at DESC
    ''', [customerId]);
    return maps.map(Order.fromMap).toList();
  }

  Future<List<Order>> getOrdersByStatus(String status) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT o.*, c.name AS customer_name, c.mobile AS customer_mobile
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE o.order_status = ?
      ORDER BY o.created_at DESC
    ''', [status]);
    return maps.map(Order.fromMap).toList();
  }

  Future<List<Order>> getTodaysOrders() async {
    final db = await database;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    final maps = await db.rawQuery('''
      SELECT o.*, c.name AS customer_name, c.mobile AS customer_mobile
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE o.order_date BETWEEN ? AND ?
      ORDER BY o.created_at DESC
    ''', [start, end]);
    return maps.map(Order.fromMap).toList();
  }

  Future<List<Order>> searchOrders(String query) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT o.*, c.name AS customer_name, c.mobile AS customer_mobile
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE c.name LIKE ? OR c.mobile LIKE ? OR o.order_number LIKE ? OR o.dress_type LIKE ?
      ORDER BY o.created_at DESC
    ''', ['%$query%', '%$query%', '%$query%', '%$query%']);
    return maps.map(Order.fromMap).toList();
  }

  Future<List<Order>> getOrdersByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT o.*, c.name AS customer_name, c.mobile AS customer_mobile
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE o.order_date BETWEEN ? AND ?
      ORDER BY o.order_date DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);
    return maps.map(Order.fromMap).toList();
  }

  // ─── DASHBOARD STATS ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day).toIso8601String();
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    final todayOrders = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM orders WHERE order_date BETWEEN ? AND ?',
      [todayStart, todayEnd],
    )) ?? 0;

    final pendingOrders = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM orders WHERE order_status NOT IN ('Delivered')",
    )) ?? 0;

    final readyOrders = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM orders WHERE order_status = 'Ready'",
    )) ?? 0;

    final deliveredOrders = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM orders WHERE order_status = 'Delivered'",
    )) ?? 0;

    final todayIncome = (await db.rawQuery(
      'SELECT IFNULL(SUM(advance_amount), 0) as total FROM orders WHERE order_date BETWEEN ? AND ?',
      [todayStart, todayEnd],
    )).first['total'] as double? ?? 0.0;

    final pendingBalance = (await db.rawQuery(
      "SELECT IFNULL(SUM(total_amount - advance_amount), 0) as total FROM orders WHERE payment_status != 'Paid'",
    )).first['total'] as double? ?? 0.0;

    return {
      'todayOrders': todayOrders,
      'pendingOrders': pendingOrders,
      'readyOrders': readyOrders,
      'deliveredOrders': deliveredOrders,
      'todayIncome': todayIncome,
      'pendingBalance': pendingBalance,
    };
  }

  // ─── MEASUREMENTS ────────────────────────────────────────────────────────

  Future<int> insertOrUpdateMeasurement(Measurement measurement) async {
    final db = await database;
    return db.insert('measurements', measurement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Measurement?> getMeasurementByOrderId(int orderId) async {
    final db = await database;
    final maps = await db
        .query('measurements', where: 'order_id = ?', whereArgs: [orderId]);
    if (maps.isEmpty) return null;
    return Measurement.fromMap(maps.first);
  }

  // ─── SETTINGS ────────────────────────────────────────────────────────────

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final maps = await db.query('settings');
    return {for (final m in maps) m['key'] as String: m['value'] as String};
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── REPORTS ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDressWiseReport() async {
    final db = await database;
    return db.rawQuery('''
      SELECT dress_type, COUNT(*) as count,
             SUM(total_amount) as total_revenue,
             SUM(advance_amount) as collected,
             SUM(total_amount - advance_amount) as pending
      FROM orders
      GROUP BY dress_type
      ORDER BY count DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getCustomerWiseReport() async {
    final db = await database;
    return db.rawQuery('''
      SELECT c.name, c.mobile, COUNT(o.id) as order_count,
             SUM(o.total_amount) as total_spent,
             SUM(o.advance_amount) as paid,
             SUM(o.total_amount - o.advance_amount) as balance
      FROM customers c
      LEFT JOIN orders o ON c.id = o.customer_id
      GROUP BY c.id
      ORDER BY order_count DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 10}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT c.name, c.mobile, COUNT(o.id) as order_count,
             SUM(o.total_amount) as total_spent
      FROM customers c
      LEFT JOIN orders o ON c.id = o.customer_id
      GROUP BY c.id
      ORDER BY total_spent DESC
      LIMIT ?
    ''', [limit]);
  }

  // ─── BACKUP ──────────────────────────────────────────────────────────────

  Future<String> getDatabasePath() async {
    final dir = await getDatabasesPath();
    return p.join(dir, AppConstants.dbName);
  }

  Future<String> exportDatabase() async {
    final srcPath = await getDatabasePath();
    final docsDir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final destPath =
        p.join(docsDir.path, 'tailor_backup_${DateTime.now().millisecondsSinceEpoch}.db');
    await File(srcPath).copy(destPath);
    return destPath;
  }

  Future<void> importDatabase(String srcPath) async {
    // Close database before replacing
    await _database?.close();
    _database = null;
    final destPath = await getDatabasePath();
    await File(srcPath).copy(destPath);
    // Re-open
    _database = await _initDatabase();
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
