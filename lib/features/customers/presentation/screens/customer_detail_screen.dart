import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/customer.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/billing_specifics.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/settings/presentation/controllers/settings_controller.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../../../features/invoices/domain/entities/invoice.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  Customer? _customer;
  List<Invoice>? _invoices;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final customerRepo = ref.read(customerRepositoryProvider);
    final invoiceRepo = ref.read(invoiceRepositoryProvider);

    final customerResult = await customerRepo.getCustomer(widget.customerId);
    customerResult.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
      },
      (customer) async {
        _customer = customer;
        final invoicesResult = await invoiceRepo.getInvoices(customerId: customer.id);
        invoicesResult.fold(
          (failure) {
            setState(() {
              _invoices = [];
              _isLoading = false;
            });
          },
          (paginated) {
            setState(() {
              _invoices = paginated.results;
              _isLoading = false;
            });
          }
        );
      }
    );
  }

  void _showPayCreditDialog(double totalDue) {
    final amountController = TextEditingController(text: totalDue.toStringAsFixed(2));
    String paymentMethod = 'CASH';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setState) => AlertDialog(
          title: const Text('Pay Credit Balance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PaymentMethodSelector(
                selectedMethod: paymentMethod,
                onSelected: (val) => setState(() => paymentMethod = val),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: amountController,
                label: 'Amount to Pay',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(innerContext),
              child: const Text('Cancel'),
            ),
            PrimaryButton(
              label: 'Pay Now',
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;
                
                final result = await ref.read(customerRepositoryProvider).payCustomerCredit(
                  widget.customerId,
                  amount,
                  paymentMethod,
                );
                
                result.fold(
                  (l) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${l.message}')));
                  },
                  (r) {
                    Navigator.pop(innerContext);
                    _fetchData(); // Refresh to update invoices
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful'), backgroundColor: AppColors.success));
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await ref.read(customerRepositoryProvider).deleteCustomer(widget.customerId);
              result.fold(
                (l) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.message), backgroundColor: AppColors.error));
                },
                (r) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted'), backgroundColor: AppColors.success));
                    context.pop();
                  }
                }
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final currency = ref.watch(settingsProvider).settings?.currency ?? '\$';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: Center(child: Text(_error ?? 'Customer not found')),
      );
    }

    final totalDue = _invoices
        ?.where((i) => i.status != 'PAID')
        .fold(0.0, (sum, i) => sum! + i.balanceDue) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_customer!.name),
        actions: [
          if (user?.role == UserRole.admin || user?.role == UserRole.manager)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details Card
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(_customer!.name, style: AppTextStyles.h3),
                    subtitle: Text('Customer ID: ${_customer!.id}'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(_customer!.email?.isNotEmpty == true ? _customer!.email! : 'N/A'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Phone'),
                    subtitle: Text(_customer!.phone?.isNotEmpty == true ? _customer!.phone! : 'N/A'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Credit Due Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: totalDue > 0 ? AppColors.errorBg : AppColors.successBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: totalDue > 0 ? AppColors.error : AppColors.success),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Credit Due', style: TextStyle(color: totalDue > 0 ? AppColors.error : AppColors.success, fontWeight: FontWeight.bold)),
                      Text('$currency${totalDue.toStringAsFixed(2)}', style: TextStyle(color: totalDue > 0 ? AppColors.error : AppColors.success, fontSize: 24, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (totalDue > 0)
                    PrimaryButton(
                      label: 'Pay Balance',
                      onPressed: () => _showPayCreditDialog(totalDue),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Transaction History', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            
            if (_invoices == null || _invoices!.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No transactions found', style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: _invoices!.map((inv) => ListRow(
                    title: 'Invoice #${inv.id}',
                    subtitle: '${inv.createdAt?.substring(0, 10)}',
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$currency${inv.grandTotal.toStringAsFixed(2)}', style: AppTextStyles.financialLine),
                        const SizedBox(height: 4),
                        StatusChip(
                          label: inv.status,
                          backgroundColor: inv.status == 'PAID' ? AppColors.successBg : (inv.status == 'PARTIAL' ? AppColors.warningBg : AppColors.errorBg),
                          textColor: inv.status == 'PAID' ? AppColors.success : (inv.status == 'PARTIAL' ? AppColors.warning : AppColors.error),
                        ),
                      ],
                    ),
                    onTap: () {
                      context.push('/invoices/${inv.id}', extra: inv);
                    },
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
