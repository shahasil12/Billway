import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../controllers/category_list_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/app_buttons.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(categoryListProvider.notifier).fetchCategories();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(categoryListProvider.notifier).setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryListProvider);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            child: PrimaryButton(
              label: 'Add Category',
              onPressed: () => context.push('/categories/add'),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? AppSpacing.p32 : AppSpacing.p16,
              vertical: AppSpacing.p8,
            ),
            child: SearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hint: 'Search categories...',
            ),
          ),
        ),
      ),
      body: _buildBody(context, state, isTablet),
    );
  }

  Widget _buildBody(BuildContext context, CategoryListState state, bool isTablet) {
    if (state.isLoading && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.p16),
            Text(state.error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: AppSpacing.p16),
            SizedBox(
              width: 120,
              child: PrimaryButton(
                label: 'Retry',
                onPressed: () => ref.read(categoryListProvider.notifier).fetchCategories(isRefresh: true),
              ),
            ),
          ],
        ),
      );
    }

    if (state.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.p16),
            const Text('No categories yet', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.p24),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: 'Add First Category',
                onPressed: () => context.push('/categories/add'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(categoryListProvider.notifier).fetchCategories(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? AppSpacing.p32 : 0,
          vertical: AppSpacing.p16,
        ),
        itemCount: state.categories.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.categories.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.p16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final category = state.categories[index];
          
          final row = ListRow(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.p8),
              ),
              child: const Icon(Icons.category, color: AppColors.primary),
            ),
            title: category.name,
            subtitle: category.description ?? 'No description',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                  onPressed: () => context.push('/categories/edit', extra: category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _confirmDelete(category.id!),
                ),
              ],
            ),
          );

          if (isTablet) {
            return AppCard(
              padding: EdgeInsets.zero,
              child: row,
            );
          }
          return row;
        },
      ),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you wish to delete this category?"),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("CANCEL")),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), 
              child: const Text("DELETE", style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      ref.read(categoryListProvider.notifier).deleteCategory(id);
    }
  }
}
