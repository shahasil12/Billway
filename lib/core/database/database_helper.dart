import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('billway.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const textType = 'TEXT';
      const intType = 'INTEGER';
      const realType = 'REAL';
      await db.execute('''
CREATE TABLE IF NOT EXISTS settings (
  id $intType PRIMARY KEY,
  business_name $textType NOT NULL,
  business_address $textType NOT NULL,
  phone_number $textType NOT NULL,
  gst_number $textType,
  invoice_prefix $textType NOT NULL,
  invoice_footer $textType NOT NULL,
  default_tax_percentage $realType NOT NULL,
  currency $textType NOT NULL,
  updated_at $textType
)
''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const intType = 'INTEGER';
    const realType = 'REAL';

    // Customers Table
    // remote_id is the ID from the server. If null, it was created offline.
    await db.execute('''
CREATE TABLE customers (
  local_id $idType,
  id $intType UNIQUE, 
  name $textType NOT NULL,
  email $textType,
  phone $textType,
  created_at $textType,
  is_synced $intType DEFAULT 1
)
''');

    // Categories Table
    await db.execute('''
CREATE TABLE categories (
  local_id $idType,
  id $intType UNIQUE,
  name $textType NOT NULL,
  description $textType,
  created_at $textType,
  is_synced $intType DEFAULT 1
)
''');

    // Products Table
    await db.execute('''
CREATE TABLE products (
  local_id $idType,
  id $intType UNIQUE,
  name $textType NOT NULL,
  category_id $intType,
  category_name $textType,
  price $realType NOT NULL,
  tax_percentage $realType,
  barcode $textType,
  description $textType,
  image_url $textType,
  stock $intType,
  status $intType,
  created_at $textType,
  is_synced $intType DEFAULT 1
)
''');

    // Invoices Table
    await db.execute('''
CREATE TABLE invoices (
  local_id $idType,
  id $intType UNIQUE,
  customer_id $intType NOT NULL,
  reference $textType,
  subtotal $realType,
  discount_percentage $realType,
  discount_amount $realType,
  tax_total $realType,
  grand_total $realType,
  amount_paid $realType,
  balance_due $realType,
  payment_method $textType,
  status $textType,
  created_at $textType,
  items_json $textType, -- Storing items as JSON string for simplicity in offline mode
  is_synced $intType DEFAULT 1
)
''');

    // POS Sessions Table
    await db.execute('''
CREATE TABLE pos_sessions (
  local_id $idType,
  id $textType UNIQUE, -- backend might use string ID for session
  user_id $intType NOT NULL,
  opening_cash $realType NOT NULL,
  closing_cash $realType,
  expected_cash $realType,
  cash_difference $realType,
  status $textType NOT NULL,
  opened_at $textType NOT NULL,
  closed_at $textType,
  is_synced $intType DEFAULT 1
)
''');

    // Settings Table (singleton row, id=1)
    await db.execute('''
CREATE TABLE IF NOT EXISTS settings (
  id $intType PRIMARY KEY,
  business_name $textType NOT NULL,
  business_address $textType NOT NULL,
  phone_number $textType NOT NULL,
  gst_number $textType,
  invoice_prefix $textType NOT NULL,
  invoice_footer $textType NOT NULL,
  default_tax_percentage $realType NOT NULL,
  currency $textType NOT NULL,
  updated_at $textType
)
''');

    // Sync Queue Table
    await db.execute('''
CREATE TABLE sync_queue (
  id $idType,
  action $textType NOT NULL, -- CREATE, UPDATE, DELETE, SESSION_OPEN, SESSION_CLOSE
  entity_type $textType NOT NULL, -- CUSTOMER, PRODUCT, INVOICE, POS_SESSION
  payload $textType NOT NULL, -- JSON string of the data
  status $textType NOT NULL, -- PENDING, FAILED
  created_at $textType NOT NULL
)
''');
  }

  Future<Map<String, dynamic>> getDashboardSummaryData() async {
    final db = await instance.database;
    
    // Get today's date bounds (for simplistic SQLite date matching)
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];
    
    // Query Total Products
    final productsCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    final totalProducts = Sqflite.firstIntValue(productsCountResult) ?? 0;

    // Query Total Customers
    final customersCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    final totalCustomers = Sqflite.firstIntValue(customersCountResult) ?? 0;

    // Query Today's Invoices Count and Sales
    final invoicesResult = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(grand_total) as total_sales 
      FROM invoices 
      WHERE created_at LIKE ?
    ''', ['$todayStr%']);
    
    final todaysInvoiceCount = invoicesResult.isNotEmpty ? (invoicesResult.first['count'] as int? ?? 0) : 0;
    final todaysSales = invoicesResult.isNotEmpty ? (invoicesResult.first['total_sales'] as double? ?? 0.0) : 0.0;

    // Recent Invoices (limit 5)
    final recentInvoicesResult = await db.query(
      'invoices',
      orderBy: 'created_at DESC',
      limit: 5,
    );

    return {
      'totalProducts': totalProducts,
      'totalCustomers': totalCustomers,
      'todaysInvoiceCount': todaysInvoiceCount,
      'todaysSales': todaysSales,
      'recentInvoices': recentInvoicesResult,
    };
  }

  /// Returns the cached settings row, or null if never fetched.
  Future<Map<String, dynamic>?> getLocalSettings() async {
    final db = await instance.database;
    final rows = await db.query('settings', limit: 1);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Upserts (insert or replace) a settings row locally.
  Future<void> saveLocalSettings(Map<String, dynamic> data) async {
    final db = await instance.database;
    final row = {...data, 'updated_at': DateTime.now().toIso8601String()};
    await db.insert('settings', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Upserts a list of categories from the server.
  Future<void> upsertCategories(List<Map<String, dynamic>> categories) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final cat in categories) {
      batch.insert('categories', {...cat, 'is_synced': 1},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Returns all locally cached categories.
  Future<List<Map<String, dynamic>>> getLocalCategories({String? search}) async {
    final db = await instance.database;
    if (search != null && search.isNotEmpty) {
      return db.query('categories',
          where: 'name LIKE ?',
          whereArgs: ['%$search%'],
          orderBy: 'name ASC');
    }
    return db.query('categories', orderBy: 'name ASC');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
