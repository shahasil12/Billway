import 'package:flutter/material.dart';
import '../../domain/entities/customer.dart';

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
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length < 10) {
                return 'Phone number must be at least 10 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: widget.isLoading 
                ? const CircularProgressIndicator()
                : Text(widget.initialCustomer == null ? 'Create Customer' : 'Update Customer'),
          ),
        ],
      ),
    );
  }
}
