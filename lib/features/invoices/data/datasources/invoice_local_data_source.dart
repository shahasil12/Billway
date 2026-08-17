import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/invoice_model.dart';
import '../../domain/entities/invoice.dart';

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
      where = 'reference LIKE ?';
      whereArgs = ['%$search%'];
    }

    if (status != null && status.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'status = ?';
      whereArgs.add(status);
    }
    
    if (customerId != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'customer_id = ?';
      whereArgs.add(customerId);
    }

    final maps = await db.query(
      'invoices',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'local_id DESC',
    );

    return maps.map((map) {
      List<InvoiceItemModel> items = [];
      if (map['items_json'] != null) {
        final List<dynamic> itemsList = jsonDecode(map['items_json'] as String);
        items = itemsList.map((i) => InvoiceItemModel.fromJson(i)).toList();
      }

      return InvoiceModel(
        id: (map['id'] ?? map['local_id']) as int,
        customerId: map['customer_id'] as int,
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
    final maps = await db.query(
      'invoices',
      where: 'id = ? OR local_id = ?',
      whereArgs: [id, id],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      List<InvoiceItemModel> items = [];
      if (map['items_json'] != null) {
        final List<dynamic> itemsList = jsonDecode(map['items_json'] as String);
        items = itemsList.map((i) => InvoiceItemModel.fromJson(i)).toList();
      }

      return InvoiceModel(
        id: (map['id'] ?? map['local_id']) as int,
        customerId: map['customer_id'] as int,
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

    for (var invoice in invoices) {
      if (invoice.id == null) continue;
      
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
