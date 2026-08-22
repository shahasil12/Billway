import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../network/api_client.dart';

class SyncService {
  final DatabaseHelper dbHelper;
  final ApiClient apiClient;
  bool _isSyncing = false;

  SyncService({required this.dbHelper, required this.apiClient}) {
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none) || results.length > 1) {
        syncPendingData();
      }
    });
  }

  Future<void> addToQueue(String action, String entityType, Map<String, dynamic> payload, {int? localId}) async {
    final db = await dbHelper.database;
    await db.insert('sync_queue', {
      'action': action,
      'entity_type': entityType,
      'payload': jsonEncode({...payload, if(localId != null) 'local_id': localId}),
      'status': 'PENDING',
      'created_at': DateTime.now().toIso8601String(),
    });
    // Trigger sync immediately but don't await to avoid blocking UI
    syncPendingData();
  }

  Future<void> syncPendingData() async {
    if (_isSyncing) return;
    
    // Check connectivity first
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none) && connectivityResult.length == 1) {
       return;
    }

    _isSyncing = true;
    final db = await dbHelper.database;

    try {
      final pendingTasks = await db.query(
        'sync_queue',
        where: 'status = ?',
        whereArgs: ['PENDING'],
        orderBy: 'id ASC',
      );

      for (var task in pendingTasks) {
        final id = task['id'] as int;
        final action = task['action'] as String;
        final entityType = task['entity_type'] as String;
        final payloadStr = task['payload'] as String;
        final payload = jsonDecode(payloadStr) as Map<String, dynamic>;

        bool success = await _processTask(action, entityType, payload);

        if (success) {
          await db.update(
            'sync_queue',
            {'status': 'COMPLETED'},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _processTask(String action, String entityType, Map<String, dynamic> payload) async {
    try {
      String endpoint = '';
      if (entityType == 'CUSTOMER') endpoint = 'customers/';
      else if (entityType == 'PRODUCT') endpoint = 'products/';
      else if (entityType == 'INVOICE') endpoint = 'invoices/';

      if (action == 'CREATE' || action == 'UPDATE') {
        final db = await dbHelper.database;
        await _resolveForeignKeys(db, entityType, payload);
        
        // Handle local image upload for products
        if (entityType == 'PRODUCT') {
          final String? imageUrl = payload['image_url'] ?? payload['image'];
          if (imageUrl != null && !imageUrl.startsWith('http')) {
            final remoteUrl = await apiClient.uploadImage(imageUrl);
            if (remoteUrl != null) {
              payload['image'] = remoteUrl;
              payload['image_url'] = remoteUrl; // Keep both consistent depending on API expectation
              
              // IMPORTANT: Update local database so the app can load the new image
              final localId = payload['local_id'] ?? payload['id'];
              if (localId != null) {
                await db.update(
                  'products',
                  {'image': remoteUrl},
                  where: 'local_id = ? OR id = ?',
                  whereArgs: [localId, localId],
                );
              }
            } else {
              return false; // Retry later if image upload fails
            }
          }
        }
      }

      if (action == 'CREATE') {
        final response = await apiClient.dio.post(endpoint, data: payload);
        if (response.statusCode == 201 || response.statusCode == 200) {
           final remoteId = response.data['id'];
           final localId = payload['local_id'];
           if (localId != null) {
              await _updateLocalId(entityType, localId, remoteId);
           }
        }
      } else if (action == 'UPDATE' || action == 'DELETE') {
        int? id = payload['id'];
        if (id == null) return false;

        // Resolve the actual remote ID if the payload has a local ID
        final db = await dbHelper.database;
        String table = '';
        if (entityType == 'CUSTOMER') table = 'customers';
        else if (entityType == 'PRODUCT') table = 'products';
        else if (entityType == 'INVOICE') table = 'invoices';
        
        if (table.isNotEmpty) {
           final maps = await db.query(table, columns: ['id'], where: 'local_id = ? OR id = ?', whereArgs: [id, id]);
           if (maps.isNotEmpty && maps.first['id'] != null) {
               id = maps.first['id'] as int;
               payload['id'] = id;
           }
        }

        if (action == 'UPDATE') {
          await apiClient.dio.put('$endpoint$id/', data: payload);
        } else {
          await apiClient.dio.delete('$endpoint$id/');
        }
      } else if (action == 'SESSION_OPEN') {
        final response = await apiClient.dio.post('pos/sessions/open/', data: payload);
        if (response.statusCode == 200 || response.statusCode == 201) {
            final remoteId = response.data['id'];
            final localId = payload['local_id'];
            if (localId != null) {
                await _updateLocalId('POS_SESSION', localId, remoteId);
            }
        }
      } else if (action == 'SESSION_CLOSE') {
        final id = payload['id']; // This should be the remote ID
        if (id == null) return false;
        await apiClient.dio.post('pos/sessions/$id/close/', data: payload);
      }
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 404) {
          // Bad request or not found. Mark as completed/failed to avoid infinite loops.
          return true; // We pretend success to remove it from queue or handle better
      }
      return false; // Will retry later
    } catch (e) {
      return false; 
    }
  }

  Future<void> _updateLocalId(String entityType, int localId, dynamic remoteId) async {
      final db = await dbHelper.database;
      String table = '';
      if (entityType == 'CUSTOMER') table = 'customers';
      else if (entityType == 'PRODUCT') table = 'products';
      else if (entityType == 'INVOICE') table = 'invoices';
      else if (entityType == 'POS_SESSION') table = 'pos_sessions';
      
      if (table.isNotEmpty) {
          await db.update(
              table, 
              {'id': remoteId is int ? remoteId : remoteId.toString(), 'is_synced': 1}, 
              where: 'local_id = ? OR id = ?', 
              whereArgs: [localId, localId] 
          );
      }
  }

  Future<void> _resolveForeignKeys(Database db, String entityType, Map<String, dynamic> payload) async {
    if (entityType == 'INVOICE') {
      final customerId = payload['customer'];
      if (customerId != null && customerId != 0) {
        final maps = await db.query('customers', columns: ['id'], where: 'local_id = ? OR id = ?', whereArgs: [customerId, customerId]);
        if (maps.isNotEmpty && maps.first['id'] != null) {
          payload['customer'] = maps.first['id'];
        }
      }

      final items = payload['items'] as List?;
      if (items != null) {
        for (var item in items) {
          final productId = item['product'];
          if (productId != null) {
            final maps = await db.query('products', columns: ['id'], where: 'local_id = ? OR id = ?', whereArgs: [productId, productId]);
            if (maps.isNotEmpty && maps.first['id'] != null) {
              item['product'] = maps.first['id'];
            }
          }
        }
      }
    } else if (entityType == 'PRODUCT') {
      final categoryId = payload['category'];
      if (categoryId != null && categoryId != 0) {
        final maps = await db.query('categories', columns: ['id'], where: 'local_id = ? OR id = ?', whereArgs: [categoryId, categoryId]);
        if (maps.isNotEmpty && maps.first['id'] != null) {
          payload['category'] = maps.first['id'];
        }
      }
    }
  }
}
