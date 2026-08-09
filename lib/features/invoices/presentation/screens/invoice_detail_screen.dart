import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../domain/entities/invoice.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../payments/domain/entities/payment.dart';
import '../controllers/invoice_list_controller.dart';
import '../../../payments/presentation/controllers/payment_list_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:intl/intl.dart';
import '../../../../core/printing/pdf_invoice_generator.dart';
import '../widgets/thermal_printer_dialog.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final Invoice invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _isDownloading = false;
  late Invoice _invoice;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
  }
  
  void _refreshInvoice() async {
    final result = await ref.read(invoiceRepositoryProvider).getInvoice(_invoice.id!);
    result.fold(
      (l) => null,
      (r) {
        if (mounted) {
          setState(() {
            _invoice = r;
          });
        }
      }
    );
  }

  void _showRecordPaymentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _RecordPaymentBottomSheet(
          invoice: _invoice,
          onPaymentRecorded: () {
            _refreshInvoice();
            ref.read(invoiceListProvider.notifier).fetchInvoices(isRefresh: true);
            ref.read(paymentListProvider.notifier).fetchPayments(isRefresh: true);
          },
        );
      }
    );
  }

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

  void _showPrintOptionsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Print A4 (PDF)'),
                onTap: () async {
                  Navigator.pop(context);
                  final settings = ref.read(settingsProvider).settings;
                  if (settings != null) {
                    await PdfInvoiceGenerator.printInvoice(_invoice, settings);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt),
                title: const Text('Print Thermal Receipt'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => ThermalPrinterDialog(invoice: _invoice),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(settingsProvider).settings?.currency ?? '\$';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${_invoice.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _showPrintOptionsSheet,
            tooltip: 'Print',
          ),
          IconButton(
            icon: _isDownloading ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface, strokeWidth: 2)) : const Icon(Icons.download),
            onPressed: _isDownloading ? null : _downloadAndOpenPdf,
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Invoice',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Invoice?'),
                  content: Text('Are you sure you want to delete Invoice #${_invoice.id}? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                final result = await ref.read(invoiceRepositoryProvider).deleteInvoice(_invoice.id!);
                result.fold(
                  (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
                  (_) {
                    ref.read(invoiceListProvider.notifier).fetchInvoices(isRefresh: true);
                    ref.refresh(dashboardSummaryProvider); // Refresh dashboard when deleted
                    if (mounted) context.pop();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice deleted')));
                  },
                );
              }
            },
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
                    Text(_invoice.customer?.name ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (_invoice.customer?.email != null) Text(_invoice.customer!.email!),
                    if (_invoice.customer?.phone != null) Text(_invoice.customer!.phone!),
                    if (_invoice.reference != null && _invoice.reference!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Reference: ${_invoice.reference}', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.indigo)),
                    ],
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn('Date', _invoice.createdAt != null ? _invoice.createdAt!.substring(0, 10) : 'N/A'),
                        _buildInfoColumn('Payment', _invoice.paymentMethod),
                        _buildInfoColumn('Status', _invoice.status, color: _invoice.status == 'PAID' ? Colors.green : Colors.orange),
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
                itemCount: _invoice.items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _invoice.items[index];
                  return ListTile(
                    title: Text(item.productName ?? 'Product'),
                    subtitle: Text('${item.quantity} x $currency${item.unitPrice?.toStringAsFixed(2) ?? '0.00'} (Tax: ${item.taxPercentage}%)'),
                    trailing: Text('$currency${item.lineTotal?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    _buildTotalRow('Subtotal', _invoice.subtotal, currency: currency),
                    if (_invoice.discountAmount > 0)
                      _buildTotalRow('Discount (${_invoice.discountPercentage}%)', -_invoice.discountAmount, color: Colors.red, currency: currency),
                    _buildTotalRow('Tax', _invoice.taxTotal, currency: currency),
                    const Divider(),
                    _buildTotalRow('Grand Total', _invoice.grandTotal, isBold: true, size: 20, currency: currency),
                    const Divider(),
                    _buildTotalRow('Amount Paid', _invoice.amountPaid, color: Colors.green, currency: currency),
                    _buildTotalRow('Balance Due', _invoice.balanceDue, isBold: true, size: 20, color: _invoice.balanceDue > 0 ? Colors.red : Colors.green, currency: currency),
                  ],
                ),
              ),
            ),
            if (_invoice.payments.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _invoice.payments.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final payment = _invoice.payments[index];
                    final date = payment.paymentDate != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(payment.paymentDate!).toLocal()) : '';
                    return ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text('Paid via ${payment.paymentMethod}'),
                      subtitle: Text(date),
                      trailing: Text('\$${payment.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: _invoice.balanceDue > 0 ? FloatingActionButton.extended(
        onPressed: _showRecordPaymentSheet,
        icon: const Icon(Icons.payment),
        label: const Text('Record Payment'),
      ) : null,
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

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, double size = 16, Color color = Colors.black, String currency = '\$'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('$currency${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: size, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}

class _RecordPaymentBottomSheet extends ConsumerStatefulWidget {
  final Invoice invoice;
  final VoidCallback onPaymentRecorded;
  const _RecordPaymentBottomSheet({required this.invoice, required this.onPaymentRecorded});

  @override
  ConsumerState<_RecordPaymentBottomSheet> createState() => _RecordPaymentBottomSheetState();
}

class _RecordPaymentBottomSheetState extends ConsumerState<_RecordPaymentBottomSheet> {
  late TextEditingController _amountController;
  String _paymentMethod = 'CASH';
  final _refController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.invoice.balanceDue.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _isLoading = true);
    final payment = Payment(
      invoiceId: widget.invoice.id!,
      amount: amount,
      paymentMethod: _paymentMethod,
      referenceNumber: _refController.text.isNotEmpty ? _refController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final result = await ref.read(paymentRepositoryProvider).createPayment(payment);
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) {
        widget.onPaymentRecorded();
        if (mounted) Navigator.pop(context);
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(settingsProvider).settings?.currency ?? '\$';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Record Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(labelText: 'Amount', border: const OutlineInputBorder(), prefixText: currency),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
            initialValue: _paymentMethod,
            items: ['CASH', 'CARD', 'UPI', 'OTHER'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) => setState(() => _paymentMethod = val!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _refController,
            decoration: const InputDecoration(labelText: 'Reference Number (Optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface) : const Text('Save Payment'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
