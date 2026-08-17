import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/billing_specifics.dart';
import '../../../../core/theme/app_colors.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  void _showPayCreditDialog(BuildContext context, double totalDue) {
    final amountController = TextEditingController(text: totalDue.toStringAsFixed(2));
    String paymentMethod = 'CASH';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
              onPressed: () => Navigator.pop(context),
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
                  (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${l.message}'))),
                  (r) {
                    Navigator.pop(context);
                    // Refresh screen
                    this.setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful'), backgroundColor: AppColors.success));
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // In a real app you might want to fetch details from API 
    // or pass the customer object directly to avoid extra fetches.
    // For this example, we assume we want to view it. 
    
    // As a simple implementation, we can just use a FutureBuilder 
    // to fetch the specific customer by ID.
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Details')),
      body: FutureBuilder(
        future: ref.read(customerRepositoryProvider).getCustomer(widget.customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final result = snapshot.data;
          if (result == null) return const Center(child: Text('Not found'));

            return result.fold(
              (failure) => Center(child: Text(failure.message)),
              (customer) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(customer.name, style: const TextStyle(fontSize: 22)),
                    const Divider(height: 32),
                    const Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(customer.email?.isNotEmpty == true ? customer.email! : 'N/A', style: const TextStyle(fontSize: 18)),
                    const Divider(height: 32),
                    const Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(customer.phone?.isNotEmpty == true ? customer.phone! : 'N/A', style: const TextStyle(fontSize: 18)),
                    const Divider(height: 32),
                    const Text('Created At', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(customer.createdAt ?? 'N/A', style: const TextStyle(fontSize: 18)),
                    const Divider(height: 32),
                    
                    // Simple credit simulation - in a real app this would come from the API
                    // as a `totalDue` field on the customer object. We will just show a UI for it.
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Credit Due', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                              Text('Use Pay Balance to clear tab', style: TextStyle(color: AppColors.error, fontSize: 12)),
                            ],
                          ),
                          PrimaryButton(
                            label: 'Pay Balance',
                            onPressed: () => _showPayCreditDialog(context, 0.0), // In a real app this would be `customer.totalDue`
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            );
        }
      ),
    );
  }
}
