import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/customer.dart';
import '../widgets/customer_form_widget.dart';
import '../../../../core/providers.dart';
import '../controllers/customer_list_controller.dart';

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final Customer? customer;

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  ConsumerState<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  bool _isLoading = false;

  void _handleSubmit(Customer customer) async {
    setState(() => _isLoading = true);
    final repo = ref.read(customerRepositoryProvider);
    
    final result = widget.customer == null 
        ? await repo.createCustomer(customer)
        : await repo.updateCustomer(customer);
        
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
        }
      },
      (_) {
        ref.read(customerListProvider.notifier).fetchCustomers(isRefresh: true);
        if (mounted) context.pop();
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'Add Customer'),
      ),
      body: CustomerFormWidget(
        initialCustomer: widget.customer,
        onSubmit: _handleSubmit,
        isLoading: _isLoading,
      ),
    );
  }
}
