import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_buttons.dart';

class CategoryFormWidget extends StatefulWidget {
  final Category? initialCategory;
  final Function(Category) onSubmit;
  final bool isLoading;

  const CategoryFormWidget({
    super.key,
    this.initialCategory,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<CategoryFormWidget> createState() => _CategoryFormWidgetState();
}

class _CategoryFormWidgetState extends State<CategoryFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCategory?.name ?? '');
    _descriptionController = TextEditingController(text: widget.initialCategory?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final category = Category(
        id: widget.initialCategory?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      widget.onSubmit(category);
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
            label: 'Category Name *',
            controller: _nameController,
            validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: AppSpacing.p16),
          AppTextField(
            label: 'Description',
            controller: _descriptionController,
          ),
          const SizedBox(height: AppSpacing.p32),
          if (widget.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            PrimaryButton(
              isLarge: true,
              label: widget.initialCategory == null ? 'Create Category' : 'Update Category',
              onPressed: _submit,
            ),
        ],
      ),
    );
  }
}
