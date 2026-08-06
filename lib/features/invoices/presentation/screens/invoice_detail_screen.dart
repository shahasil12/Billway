import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../domain/entities/invoice.dart';
import '../../../../core/network/api_client.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final Invoice invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _isDownloading = false;

  Future<void> _downloadAndOpenPdf() async {
    setState(() => _isDownloading = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get(
        'invoices/${widget.invoice.id}/pdf/',
        options: Options(responseType: ResponseType.bytes),
      );
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/invoice_${widget.invoice.id}.pdf');
      await file.writeAsBytes(response.data);
      
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to open PDF')));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${invoice.id}'),
        actions: [
          IconButton(
            icon: _isDownloading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.picture_as_pdf),
            onPressed: _isDownloading ? null : _downloadAndOpenPdf,
            tooltip: 'View PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Billed To', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(invoice.customer?.name ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (invoice.customer?.email != null) Text(invoice.customer!.email!),
                    if (invoice.customer?.phone != null) Text(invoice.customer!.phone!),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn('Date', invoice.createdAt != null ? invoice.createdAt!.substring(0, 10) : 'N/A'),
                        _buildInfoColumn('Payment', invoice.paymentMethod),
                        _buildInfoColumn('Status', invoice.status, color: invoice.status == 'PAID' ? Colors.green : Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Order Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invoice.items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = invoice.items[index];
                  return ListTile(
                    title: Text(item.productName ?? 'Product'),
                    subtitle: Text('${item.quantity} x \$${item.unitPrice?.toStringAsFixed(2) ?? '0.00'} (Tax: ${item.taxPercentage}%)'),
                    trailing: Text('\$${item.lineTotal?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTotalRow('Subtotal', invoice.subtotal),
                    if (invoice.discountAmount > 0)
                      _buildTotalRow('Discount (${invoice.discountPercentage}%)', -invoice.discountAmount, color: Colors.red),
                    _buildTotalRow('Tax', invoice.taxTotal),
                    const Divider(),
                    _buildTotalRow('Grand Total', invoice.grandTotal, isBold: true, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, double size = 16, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
