import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/invoice_model.dart';
import '../../domain/entities/invoice.dart';
import '../../../customers/data/models/customer_model.dart';

abstract class InvoiceLocalDataSource {
  Future<List<InvoiceModel>> getInvoices({String? search, String? status, int? customerId});
  Future<InvoiceModel?> getInvoice(int id);
  Future<InvoiceModel> createInvoice(InvoiceModel invoice);
  Future<InvoiceModel> updateInvoice(InvoiceModel invoice);
  Future<void> deleteInvoice(int id);
  Future<void> upsertInvoices(List<InvoiceModel> invoices);
}

class InvoiceLocalDataSourceImpl implements InvoiceLocalDataSource {
  final DatabaseHelper dbHelper;

  InvoiceLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<InvoiceModel>> getInvoices({String? search, String? status, int? customerId}) async {
    final db = await dbHelper.database;
    
    String where = '';
    List<dynamic> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      where = 'i.reference LIKE ?';
      whereArgs = ['%$search%'];
    }

    if (status != null && status.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'i.status = ?';
      whereArgs.add(status);
    }
    
    if (customerId != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'i.customer_id = ?';
      whereArgs.add(customerId);
    }

    final maps = await db.rawQuery('''
      SELECT 
        i.*,
        c.id as c_id,
        c.local_id as c_local_id,
        c.name as c_name,
        c.email as c_email,
        c.phone as c_phone
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id OR i.customer_id = c.local_id
      ${where.isNotEmpty ? 'WHERE $where' : ''}
      ORDER BY i.local_id DESC
    ''', whereArgs.isEmpty ? null : whereArgs);

    return maps.map((map) {
      List<InvoiceItemModel> items = [];
      if (map['items_json'] != null) {
        final List<dynamic> itemsList = jsonDecode(map['items_json'] as String);
        items = itemsList.map((i) => InvoiceItemModel.fromJson(i)).toList();
      }

      CustomerModel? customer;
      if (map['c_name'] != null) {
        customer = CustomerModel(
          id: (map['c_id'] ?? map['c_local_id']) as int?,
          name: map['c_name'] as String,
          email: map['c_email'] as String?,
          phone: map['c_phone'] as String?,
        );
      }

      return InvoiceModel(
        id: (map['id'] ?? map['local_id']) as int,
        customerId: map['customer_id'] as int,
        customer: customer,
        reference: map['reference'] as String?,
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
        discountPercentage: (map['discount_percentage'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
        taxTotal: (map['tax_total'] as num?)?.toDouble() ?? 0.0,
        grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
        amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
        balanceDue: (map['balance_due'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: map['payment_method'] as String? ?? 'CASH',
        status: map['status'] as String? ?? 'UNPAID',
        createdAt: map['created_at'] as String?,
        items: items,
      );
    }).toList();
  }

  @override
  Future<InvoiceModel?> getInvoice(int id) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT 
        i.*,
        c.id as c_id,
        c.local_id as c_local_id,
        c.name as c_name,
        c.email as c_email,
        c.phone as c_phone
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id OR i.customer_id = c.local_id
      WHERE i.id = ? OR i.local_id = ?
    ''', [id, id]);

    if (maps.isNotEmpty) {
      final map = maps.first;
      List<InvoiceItemModel> items = [];
      if (map['items_json'] != null) {
        final List<dynamic> itemsList = jsonDecode(map['items_json'] as String);
        items = itemsList.map((i) => InvoiceItemModel.fromJson(i)).toList();
      }

      CustomerModel? customer;
      if (map['c_name'] != null) {
        customer = CustomerModel(
          id: (map['c_id'] ?? map['c_local_id']) as int?,
          name: map['c_name'] as String,
          email: map['c_email'] as String?,
          phone: map['c_phone'] as String?,
        );
      }

      return InvoiceModel(
        id: (map['id'] ?? map['local_id']) as int,
        customerId: map['customer_id'] as int,
        customer: customer,
        reference: map['reference'] as String?,
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
        discountPercentage: (map['discount_percentage'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
        taxTotal: (map['tax_total'] as num?)?.toDouble() ?? 0.0,
        grandTotal: (map['grand_total'] as num?)?.toDouble() ?? 0.0,
        amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
        balanceDue: (map['balance_due'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: map['payment_method'] as String? ?? 'CASH',
        status: map['status'] as String? ?? 'UNPAID',
        createdAt: map['created_at'] as String?,
        items: items,
      );
    }
    return null;
  }

  @override
  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    final db = await dbHelper.database;
    
    final itemsList = invoice.items.map((e) => {
      'product': e.productId,
      'product_name': e.productName,
      'product_category': e.productCategory,
      'quantity': e.quantity,
      'unit_price': e.unitPrice,
      'tax_percentage': e.taxPercentage,
      'tax_amount': e.taxAmount,
      'line_total': e.lineTotal,
    }).toList();
    
    final data = {
      'id': invoice.id,
      'customer_id': invoice.customerId,
      'reference': invoice.reference ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
      'subtotal': invoice.subtotal,
      'discount_percentage': invoice.discountPercentage,
      'discount_amount': invoice.discountAmount,
      'tax_total': invoice.taxTotal,
      'grand_total': invoice.grandTotal,
      'amount_paid': invoice.amountPaid,
      'balance_due': invoice.balanceDue,
      'payment_method': invoice.paymentMethod,
      'status': invoice.status,
      'created_at': invoice.createdAt ?? DateTime.now().toIso8601String(),
      'items_json': jsonEncode(itemsList),
      'is_synced': invoice.id != null ? 1 : 0, 
    };

    final localId = await db.insert('invoices', data, conflictAlgorithm: ConflictAlgorithm.replace);
    
    return InvoiceModel(
      id: invoice.id ?? localId,
      customerId: invoice.customerId,
      reference: data['reference'] as String?,
      subtotal: invoice.subtotal,
      discountPercentage: invoice.discountPercentage,
      discountAmount: invoice.discountAmount,
      taxTotal: invoice.taxTotal,
      grandTotal: invoice.grandTotal,
      amountPaid: invoice.amountPaid,
      balanceDue: invoice.balanceDue,
      paymentMethod: invoice.paymentMethod,
      status: invoice.status,
      createdAt: data['created_at'] as String?,
      items: invoice.items,
    );
  }

  @override
  Future<InvoiceModel> updateInvoice(InvoiceModel invoice) async {
    final db = await dbHelper.database;
    
    final itemsList = invoice.items.map((e) => {
      'product': e.productId,
      'product_name': e.productName,
      'product_category': e.productCategory,
      'quantity': e.quantity,
      'unit_price': e.unitPrice,
      'tax_percentage': e.taxPercentage,
      'tax_amount': e.taxAmount,
      'line_total': e.lineTotal,
    }).toList();

    final data = {
      'customer_id': invoice.customerId,
      'subtotal': invoice.subtotal,
      'discount_percentage': invoice.discountPercentage,
      'discount_amount': invoice.discountAmount,
      'tax_total': invoice.taxTotal,
      'grand_total': invoice.grandTotal,
      'amount_paid': invoice.amountPaid,
      'balance_due': invoice.balanceDue,
      'payment_method': invoice.paymentMethod,
      'status': invoice.status,
      'items_json': jsonEncode(itemsList),
      'is_synced': 0, // Mark as dirty
    };

    await db.update(
      'invoices',
      data,
      where: 'id = ? OR local_id = ?',
      whereArgs: [invoice.id, invoice.id],
    );

    return invoice;
  }

  @override
  Future<void> deleteInvoice(int id) async {
    final db = await dbHelper.database;
    await db.delete(
      'invoices',
      where: 'id = ? OR local_id = ?',
      whereArgs: [id, id],
    );
  }

  @override
  Future<void> upsertInvoices(List<InvoiceModel> invoices) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    final dirtyDocs = await db.query('invoices', columns: ['id'], where: 'is_synced = 0');
    final dirtyIds = dirtyDocs.map((e) => e['id']).toSet();

    final pendingDeletes = await db.query(
      'sync_queue',
      columns: ['payload'],
      where: "entity_type = 'INVOICE' AND action = 'DELETE' AND status = 'PENDING'",
    );
    final deletedIds = pendingDeletes.map((e) {
      final payloadStr = e['payload'] as String;
      final match = RegExp(r'"id":\s*(\d+)').firstMatch(payloadStr);
      return match != null ? int.parse(match.group(1)!) : null;
    }).where((id) => id != null).toSet();

    for (var invoice in invoices) {
      if (invoice.id == null) continue;
      if (dirtyIds.contains(invoice.id)) continue;
      if (deletedIds.contains(invoice.id)) continue;
      
      final itemsList = invoice.items.map((e) => {
        'product': e.productId,
        'product_name': e.productName,
        'product_category': e.productCategory,
        'quantity': e.quantity,
        'unit_price': e.unitPrice,
        'tax_percentage': e.taxPercentage,
        'tax_amount': e.taxAmount,
        'line_total': e.lineTotal,
      }).toList();

      batch.insert(
        'invoices',
        {
          'id': invoice.id,
          'customer_id': invoice.customerId,
          'reference': invoice.reference,
          'subtotal': invoice.subtotal,
          'discount_percentage': invoice.discountPercentage,
          'discount_amount': invoice.discountAmount,
          'tax_total': invoice.taxTotal,
          'grand_total': invoice.grandTotal,
          'amount_paid': invoice.amountPaid,
          'balance_due': invoice.balanceDue,
          'payment_method': invoice.paymentMethod,
          'status': invoice.status,
          'created_at': invoice.createdAt,
          'items_json': jsonEncode(itemsList),
          'is_synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }
}
