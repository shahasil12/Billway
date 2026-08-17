import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../database/database_helper.dart';
import '../network/api_client.dart';

class SyncService {
  final DatabaseHelper dbHelper;
  final ApiClient apiClient;
  bool _isSyncing = false;

  SyncService({required this.dbHelper, required this.apiClient}) {
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
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
    // Don't call syncPendingData() here — it could block the caller if Render is slow.
    // The connectivity listener above will handle syncing when network is available.
  }

  Future<void> syncPendingData() async {
    if (_isSyncing) return;
    
    // Check connectivity first
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.mobile) && !connectivityResult.contains(ConnectivityResult.wifi)) {
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

      if (action == 'CREATE') {
        final response = await apiClient.dio.post(endpoint, data: payload);
        if (response.statusCode == 201 || response.statusCode == 200) {
           final remoteId = response.data['id'];
           final localId = payload['local_id'];
           if (localId != null) {
              await _updateLocalId(entityType, localId, remoteId);
           }
        }
      } else if (action == 'UPDATE') {
        final id = payload['id'];
        if (id == null) return false;
        await apiClient.dio.put('$endpoint$id/', data: payload);
      } else if (action == 'DELETE') {
        final id = payload['id'];
        if (id == null) return false;
        await apiClient.dio.delete('$endpoint$id/');
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
}
