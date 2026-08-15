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
      version: 1,
      onCreate: _createDB,
    );
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

    // Sync Queue Table
    await db.execute('''
CREATE TABLE sync_queue (
  id $idType,
  action $textType NOT NULL, -- CREATE, UPDATE, DELETE
  entity_type $textType NOT NULL, -- CUSTOMER, PRODUCT, INVOICE
  payload $textType NOT NULL, -- JSON string of the data
  status $textType NOT NULL, -- PENDING, FAILED
  created_at $textType NOT NULL
)
''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
