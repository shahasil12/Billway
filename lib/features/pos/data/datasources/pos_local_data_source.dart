import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/pos_session.dart';

abstract class POSLocalDataSource {
  Future<POSSession?> getCurrentSession();
  Future<POSSession> openSession(POSSession session);
  Future<POSSession> closeSession(POSSession session);
  Future<void> upsertSessions(List<POSSession> sessions);
}

class POSLocalDataSourceImpl implements POSLocalDataSource {
  final DatabaseHelper dbHelper;

  POSLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<POSSession?> getCurrentSession() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'pos_sessions',
      where: 'status = ?',
      whereArgs: ['OPEN'],
      orderBy: 'local_id DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return _fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<POSSession> openSession(POSSession session) async {
    final db = await dbHelper.database;
    final data = _toMap(session);
    data['is_synced'] = session.id.startsWith('local_') ? 0 : 1;
    
    final localId = await db.insert('pos_sessions', data, conflictAlgorithm: ConflictAlgorithm.replace);
    
    return _fromMap({...data, 'local_id': localId});
  }

  @override
  Future<POSSession> closeSession(POSSession session) async {
    final db = await dbHelper.database;
    final data = _toMap(session);
    data['is_synced'] = 0; // Mark dirty for closing
    
    await db.update(
      'pos_sessions',
      data,
      where: 'id = ? OR local_id = ?',
      whereArgs: [session.id, session.id],
    );

    return session;
  }

  @override
  Future<void> upsertSessions(List<POSSession> sessions) async {
    final db = await dbHelper.database;
    final batch = db.batch();

    for (var session in sessions) {
      final data = _toMap(session);
      data['is_synced'] = 1;
      
      batch.insert(
        'pos_sessions',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Map<String, dynamic> _toMap(POSSession session) {
    return {
      'id': session.id,
      'user_id': session.userId,
      'opening_cash': session.openingCash,
      'closing_cash': session.closingCash,
      'expected_cash': session.expectedCash,
      'cash_difference': session.cashDifference,
      'status': session.status,
      'opened_at': session.openedAt.toIso8601String(),
      'closed_at': session.closedAt?.toIso8601String(),
    };
  }

  POSSession _fromMap(Map<String, dynamic> map) {
    return POSSession(
      id: (map['id'] ?? map['local_id'].toString()) as String,
      userId: map['user_id'] as int,
      openingCash: (map['opening_cash'] as num).toDouble(),
      closingCash: map['closing_cash'] != null ? (map['closing_cash'] as num).toDouble() : null,
      expectedCash: map['expected_cash'] != null ? (map['expected_cash'] as num).toDouble() : null,
      cashDifference: map['cash_difference'] != null ? (map['cash_difference'] as num).toDouble() : null,
      status: map['status'] as String,
      openedAt: DateTime.parse(map['opened_at'] as String),
      closedAt: map['closed_at'] != null ? DateTime.parse(map['closed_at'] as String) : null,
    );
  }
}
