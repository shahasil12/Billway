import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import '../../domain/entities/invoice.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../payments/domain/entities/payment.dart';
import '../controllers/invoice_list_controller.dart';
import '../../../payments/presentation/controllers/payment_list_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../../core/printing/pdf_invoice_generator.dart';
import '../widgets/thermal_printer_dialog.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_inputs.dart';

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
      backgroundColor: Colors.transparent,
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.p24),
                  child: Text('Print Options', style: AppTextStyles.h2),
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
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
                  leading: const Icon(Icons.receipt, color: AppColors.primary),
                  title: const Text('Print Thermal Receipt'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => ThermalPrinterDialog(invoice: _invoice),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.p24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(settingsProvider).settings?.currency ?? '\$';
    final isTablet = MediaQuery.of(context).size.width >= 600;
    
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
            icon: _isDownloading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Icon(Icons.download),
            onPressed: _isDownloading ? null : _downloadAndOpenPdf,
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
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
                      child: const Text('Delete', style: TextStyle(color: AppColors.error)),
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
          const SizedBox(width: AppSpacing.p8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? AppSpacing.p32 : AppSpacing.p16,
          vertical: AppSpacing.p16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: AppSpacing.p24),
            _buildItemsSection(currency),
            const SizedBox(height: AppSpacing.p24),
            _buildTotalsSection(currency),
            if (_invoice.payments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.p24),
              _buildPaymentHistorySection(currency),
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

  Widget _buildHeaderSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Billed To', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.p4),
                    Text(_invoice.customer?.name ?? 'Unknown', style: AppTextStyles.h2),
                    if (_invoice.customer?.email != null) Text(_invoice.customer!.email!, style: AppTextStyles.bodyMedium),
                    if (_invoice.customer?.phone != null) Text(_invoice.customer!.phone!, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              StatusChip(
                label: _invoice.status,
                status: _invoice.status == 'PAID' ? StatusType.success : StatusType.warning,
              ),
            ],
          ),
          if (_invoice.reference != null && _invoice.reference!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.p16),
            Text('Ref: ${_invoice.reference}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.p16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('Date', _invoice.createdAt != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(_invoice.createdAt!).toLocal()) : 'N/A'),
              _buildInfoColumn('Method', _invoice.paymentMethod),
              _buildInfoColumn('Items', '${_invoice.items.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.p4),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildItemsSection(String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Items', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.p16),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _invoice.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _invoice.items[index];
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.p16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName ?? 'Product', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('${item.quantity} x $currency${item.unitPrice?.toStringAsFixed(2)}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      '$currency${item.lineTotal?.toStringAsFixed(2)}',
                      style: AppTextStyles.financialLine.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSection(String currency) {
    return AppCard(
      color: AppColors.primaryLight,
      child: Column(
        children: [
          _buildTotalRow('Subtotal', _invoice.subtotal, currency),
          if (_invoice.discountAmount > 0)
            _buildTotalRow('Discount (${_invoice.discountPercentage}%)', -_invoice.discountAmount, currency, isDiscount: true),
          _buildTotalRow('Tax', _invoice.taxTotal, currency),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.p12),
            child: Divider(height: 1),
          ),
          _buildTotalRow('Grand Total', _invoice.grandTotal, currency, isBold: true, isLarge: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.p12),
            child: Divider(height: 1),
          ),
          _buildTotalRow('Amount Paid', _invoice.amountPaid, currency, color: AppColors.success),
          _buildTotalRow('Balance Due', _invoice.balanceDue, currency, 
            isBold: true, isLarge: true, color: _invoice.balanceDue > 0 ? AppColors.error : AppColors.success),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, String currency, {
    bool isBold = false, 
    bool isLarge = false, 
    Color color = AppColors.textPrimary,
    bool isDiscount = false,
  }) {
    final style = isLarge 
        ? AppTextStyles.h2.copyWith(color: color)
        : AppTextStyles.bodyMedium.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400, 
            color: color
          );
          
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.p4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style.copyWith(color: isLarge ? color : AppColors.textSecondary)),
          Text(
            '${isDiscount ? '-' : ''}$currency${amount.abs().toStringAsFixed(2)}', 
            style: isLarge ? AppTextStyles.financialLine.copyWith(fontWeight: FontWeight.w700, color: color, fontSize: 20) 
                         : AppTextStyles.financialLine.copyWith(fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: color)
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistorySection(String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment History', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.p16),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _invoice.payments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final payment = _invoice.payments[index];
              final date = payment.paymentDate != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(payment.paymentDate!).toLocal()) : '';
              
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.p8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: AppColors.success, size: 20),
                ),
                title: Text('Paid via ${payment.paymentMethod}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(date, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                trailing: Text(
                  '$currency${payment.amount.toStringAsFixed(2)}', 
                  style: AppTextStyles.financialLine.copyWith(fontWeight: FontWeight.w700, color: AppColors.success),
                ),
              );
            },
          ),
        ),
      ],
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

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.p24,
        left: AppSpacing.p24,
        right: AppSpacing.p24,
        top: AppSpacing.p24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Record Payment', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.p24),
          
          AppTextField(
            label: 'Amount ($currency)',
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.p16),
          
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Payment Method',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide.none,
              ),
            ),
            value: _paymentMethod,
            items: ['CASH', 'CARD', 'UPI', 'OTHER'].map((m) => DropdownMenuItem(value: m, child: Text(m, style: AppTextStyles.bodyMedium))).toList(),
            onChanged: (val) => setState(() => _paymentMethod = val!),
          ),
          const SizedBox(height: AppSpacing.p16),
          
          AppTextField(
            label: 'Reference Number (Optional)',
            controller: _refController,
          ),
          const SizedBox(height: AppSpacing.p16),
          
          AppTextField(
            label: 'Notes (Optional)',
            controller: _notesController,
          ),
          const SizedBox(height: AppSpacing.p32),
          
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              isLarge: true,
              label: 'Save Payment',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
