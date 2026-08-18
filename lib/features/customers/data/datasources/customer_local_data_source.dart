import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/customer_model.dart';
import '../../domain/entities/customer.dart';

abstract class CustomerLocalDataSource {
  Future<List<CustomerModel>> getCustomers({String? search});
  Future<CustomerModel?> getCustomer(int id);
  Future<CustomerModel> createCustomer(CustomerModel customer);
  Future<CustomerModel> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(int id);
  Future<void> upsertCustomers(List<CustomerModel> customers); // used to save data fetched from API
}

class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  final DatabaseHelper dbHelper;

  CustomerLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<CustomerModel>> getCustomers({String? search}) async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (search != null && search.isNotEmpty) {
      maps = await db.query(
        'customers',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: ['%$search%', '%$search%'],
        orderBy: 'local_id DESC',
      );
    } else {
      maps = await db.query('customers', orderBy: 'local_id DESC');
    }

    return maps.map((map) {
      return CustomerModel(
        id: (map['id'] ?? map['local_id']) as int,
        name: map['name'] as String,
        email: map['email'] as String?,
        phone: map['phone'] as String?,
        createdAt: map['created_at'] as String?,
      );
    }).toList();
  }

  @override
  Future<CustomerModel?> getCustomer(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'id = ? OR local_id = ?',
      whereArgs: [id, id],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      return CustomerModel(
        id: (map['id'] ?? map['local_id']) as int,
        name: map['name'] as String,
        email: map['email'] as String?,
        phone: map['phone'] as String?,
        createdAt: map['created_at'] as String?,
      );
    }
    return null;
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final db = await dbHelper.database;
    
    final data = {
      'id': customer.id, // might be null if offline
      'name': customer.name,
      'email': customer.email,
      'phone': customer.phone,
      'created_at': customer.createdAt ?? DateTime.now().toIso8601String(),
      'is_synced': customer.id != null ? 1 : 0, 
    };

    final localId = await db.insert('customers', data, conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Return customer with localId if it doesn't have a remote one
    return CustomerModel(
      id: customer.id ?? localId,
      name: customer.name,
      email: customer.email,
      phone: customer.phone,
      createdAt: data['created_at'] as String?,
    );
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final db = await dbHelper.database;
    
    final data = {
      'name': customer.name,
      'email': customer.email,
      'phone': customer.phone,
      'is_synced': 0, // Mark as dirty
    };

    await db.update(
      'customers',
      data,
      where: 'id = ? OR local_id = ?',
      whereArgs: [customer.id, customer.id],
    );

    return customer;
  }

  @override
  Future<void> deleteCustomer(int id) async {
    final db = await dbHelper.database;
    await db.delete(
      'customers',
      where: 'id = ? OR local_id = ?',
      whereArgs: [id, id],
    );
  }

  @override
  Future<void> upsertCustomers(List<CustomerModel> customers) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    final dirtyDocs = await db.query('customers', columns: ['id'], where: 'is_synced = 0');
    final dirtyIds = dirtyDocs.map((e) => e['id']).toSet();

    final pendingDeletes = await db.query(
      'sync_queue',
      columns: ['payload'],
      where: "entity_type = 'CUSTOMER' AND action = 'DELETE' AND status = 'PENDING'",
    );
    final deletedIds = pendingDeletes.map((e) {
      final payloadStr = e['payload'] as String;
      // Extract "id": <number> using regex or simple parsing
      final match = RegExp(r'"id":\s*(\d+)').firstMatch(payloadStr);
      return match != null ? int.parse(match.group(1)!) : null;
    }).where((id) => id != null).toSet();

    for (var customer in customers) {
      if (customer.id == null) continue;
      if (dirtyIds.contains(customer.id)) continue;
      if (deletedIds.contains(customer.id)) continue;
      batch.insert(
        'customers',
        {
          'id': customer.id,
          'name': customer.name,
          'email': customer.email,
          'phone': customer.phone,
          'created_at': customer.createdAt,
          'is_synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }
}
