import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/product_model.dart';
import '../../domain/entities/product.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProducts({String? search, int? categoryId});
  Future<ProductModel?> getProduct(int id);
  Future<ProductModel> createProduct(ProductModel product);
  Future<ProductModel> updateProduct(ProductModel product);
  Future<void> deleteProduct(int id);
  Future<void> upsertProducts(List<ProductModel> products);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final DatabaseHelper dbHelper;

  ProductLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<ProductModel>> getProducts({String? search, int? categoryId}) async {
    final db = await dbHelper.database;
    
    String where = '';
    List<dynamic> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      where = 'name LIKE ? OR barcode LIKE ?';
      whereArgs = ['%$search%', '%$search%'];
    }

    if (categoryId != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'category_id = ?';
      whereArgs.add(categoryId);
    }

    final maps = await db.query(
      'products',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'local_id DESC',
    );

    return maps.map((map) {
      return ProductModel(
        id: (map['id'] ?? map['local_id']) as int,
        name: map['name'] as String,
        categoryId: map['category_id'] as int?,
        categoryName: map['category_name'] as String?,
        price: (map['price'] as num).toDouble(),
        taxPercentage: (map['tax_percentage'] as num).toDouble(),
        barcode: map['barcode'] as String?,
        description: map['description'] as String?,
        image: map['image_url'] as String?,
        stock: map['stock'] as int,
        status: map['status'] == 1,
        createdAt: map['created_at'] as String?,
      );
    }).toList();
  }

  @override
  Future<ProductModel?> getProduct(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'id = ? OR local_id = ?',
      whereArgs: [id, id],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      return ProductModel(
        id: (map['id'] ?? map['local_id']) as int,
        name: map['name'] as String,
        categoryId: map['category_id'] as int?,
        categoryName: map['category_name'] as String?,
        price: (map['price'] as num).toDouble(),
        taxPercentage: (map['tax_percentage'] as num).toDouble(),
        barcode: map['barcode'] as String?,
        description: map['description'] as String?,
        image: map['image_url'] as String?,
        stock: map['stock'] as int,
        status: map['status'] == 1,
        createdAt: map['created_at'] as String?,
      );
    }
    return null;
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    final db = await dbHelper.database;
    
    final data = {
      'id': product.id,
      'name': product.name,
      'category_id': product.categoryId,
      'category_name': product.categoryName,
      'price': product.price,
      'tax_percentage': product.taxPercentage,
      'barcode': product.barcode,
      'description': product.description,
      'image_url': product.image,
      'stock': product.stock,
      'status': product.status == true ? 1 : 0,
      'created_at': product.createdAt ?? DateTime.now().toIso8601String(),
      'is_synced': product.id != null ? 1 : 0, 
    };

    final localId = await db.insert('products', data, conflictAlgorithm: ConflictAlgorithm.replace);
    
    return ProductModel(
      id: product.id ?? localId,
      name: product.name,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      price: product.price,
      taxPercentage: product.taxPercentage,
      barcode: product.barcode,
      description: product.description,
      image: product.image,
      stock: product.stock,
      status: product.status,
      createdAt: data['created_at'] as String?,
    );
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    final db = await dbHelper.database;
    
    final data = {
      'name': product.name,
      'category_id': product.categoryId,
      'category_name': product.categoryName,
      'price': product.price,
      'tax_percentage': product.taxPercentage,
      'barcode': product.barcode,
      'description': product.description,
      'image_url': product.image,
      'stock': product.stock,
      'status': product.status == true ? 1 : 0,
      'is_synced': 0, // Mark as dirty
    };

    await db.update(
      'products',
      data,
      where: 'id = ? OR local_id = ?',
      whereArgs: [product.id, product.id],
    );

    return product;
  }

  @override
  Future<void> deleteProduct(int id) async {
    final db = await dbHelper.database;
    await db.delete(
      'products',
      where: 'id = ? OR local_id = ?',
      whereArgs: [id, id],
    );
  }

  @override
  Future<void> upsertProducts(List<ProductModel> products) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    for (var product in products) {
      if (product.id == null) continue;
      batch.insert(
        'products',
        {
          'id': product.id,
          'name': product.name,
          'category_id': product.categoryId,
          'category_name': product.categoryName,
          'price': product.price,
          'tax_percentage': product.taxPercentage,
          'barcode': product.barcode,
          'description': product.description,
          'image_url': product.image,
          'stock': product.stock,
          'status': product.status == true ? 1 : 0,
          'created_at': product.createdAt,
          'is_synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }
}
