import 'package:flutter/material.dart';
import '../../domain/entities/customer.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

class CustomerFormWidget extends StatefulWidget {
  final Customer? initialCustomer;
  final Function(Customer) onSubmit;
  final bool isLoading;

  const CustomerFormWidget({
    super.key,
    this.initialCustomer,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<CustomerFormWidget> createState() => _CustomerFormWidgetState();
}

class _CustomerFormWidgetState extends State<CustomerFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCustomer?.name ?? '');
    _emailController = TextEditingController(text: widget.initialCustomer?.email ?? '');
    _phoneController = TextEditingController(text: widget.initialCustomer?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final customer = Customer(
        id: widget.initialCustomer?.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      widget.onSubmit(customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.p24),
        children: [
          AppTextField(
            label: 'Full Name *',
            controller: _nameController,
            validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: AppSpacing.p16),
          AppTextField(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.p16),
          AppTextField(
            label: 'Phone *',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              if (value.length < 10) {
                return 'Phone number must be at least 10 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.p32),
          if (widget.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            PrimaryButton(
              isLarge: true,
              label: widget.initialCustomer == null ? 'Create Customer' : 'Update Customer',
              onPressed: _submit,
            ),
        ],
      ),
    );
  }
}
