import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/category.dart';
import '../widgets/category_form_widget.dart';
import '../../../../core/providers.dart';
import '../controllers/category_list_controller.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final Category? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  ConsumerState<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  bool _isLoading = false;

  void _handleSubmit(Category category) async {
    setState(() => _isLoading = true);
    final repo = ref.read(categoryRepositoryProvider);
    
    final result = widget.category == null 
        ? await repo.createCategory(category)
        : await repo.updateCategory(category);
        
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
        }
      },
      (_) {
        ref.read(categoryListProvider.notifier).fetchCategories(isRefresh: true);
        if (mounted) context.pop();
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
      ),
      body: CategoryFormWidget(
        initialCategory: widget.category,
        onSubmit: _handleSubmit,
        isLoading: _isLoading,
      ),
    );
  }
}
