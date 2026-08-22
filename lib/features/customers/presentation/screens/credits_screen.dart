import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../controllers/customer_list_controller.dart';
import '../../domain/entities/customer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers.dart';

class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerListProvider);
    final l10n = AppLocalizations.of(context);
    final title = l10n?.credits ?? 'Credits';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: state.isLoading && state.customers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.customers.isEmpty
              ? Center(child: Text('Error: ${state.error}'))
              : Builder(
                  builder: (context) {
                    final creditCustomers = state.customers.where((c) => c.creditBalance > 0).toList();
                    if (creditCustomers.isEmpty) {
                      return const Center(child: Text('No customers with outstanding credits.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.p16),
                      itemCount: creditCustomers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.p12),
                      itemBuilder: (context, index) {
                        final customer = creditCustomers[index];
                        return AppCard(
                          child: ListTile(
                            title: Text(customer.name, style: AppTextStyles.h3),
                            subtitle: Text(customer.phone ?? ''),
                            trailing: Text(
                              '₹${customer.creditBalance.toStringAsFixed(2)}',
                              style: AppTextStyles.h2.copyWith(color: AppColors.error),
                            ),
                            onTap: () => _showPayCreditDialog(context, ref, customer),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }

  void _showPayCreditDialog(BuildContext context, WidgetRef ref, Customer customer) {
    final amountController = TextEditingController(text: customer.creditBalance.toStringAsFixed(2));
    final l10n = AppLocalizations.of(context);
    final payStr = l10n?.payCredit ?? 'Pay Credit';
    final cancelStr = l10n?.cancel ?? 'Cancel';
    final saveStr = l10n?.save ?? 'Save';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$payStr - ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance: ₹${customer.creditBalance.toStringAsFixed(2)}'),
            const SizedBox(height: AppSpacing.p16),
            AppTextField(
              controller: amountController,
              label: 'Amount to Pay',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(cancelStr),
          ),
          PrimaryButton(
            label: saveStr,
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount > 0 && amount <= customer.creditBalance) {
                // Update locally
                final syncService = ref.read(syncServiceProvider);
                final dbHelper = ref.read(databaseHelperProvider);
                final db = await dbHelper.database;
                
                final newBalance = customer.creditBalance - amount;
                await db.update(
                  'customers',
                  {'credit_balance': newBalance},
                  where: 'id = ? OR local_id = ?',
                  whereArgs: [customer.id, customer.id],
                );
                
                // Add to sync queue
                await syncService.addToQueue('PAY_CREDIT', 'CUSTOMER', {
                  'customer_id': customer.id,
                  'amount': amount,
                  'payment_method': 'CASH',
                }, localId: customer.id);
                
                // Refresh provider
                ref.invalidate(customerListProvider);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Credit payment of ₹$amount saved.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
