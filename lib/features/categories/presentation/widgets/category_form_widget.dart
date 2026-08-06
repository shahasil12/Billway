import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

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
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Category Name *', border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: widget.isLoading 
                ? const CircularProgressIndicator()
                : Text(widget.initialCategory == null ? 'Create Category' : 'Update Category'),
          ),
        ],
      ),
    );
  }
}
