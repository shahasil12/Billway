import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/category_list_controller.dart';
import 'dart:async';

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

    ref.listen<CategoryListState>(categoryListProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(categoryListProvider.notifier).fetchCategories(isRefresh: true),
        child: state.categories.isEmpty && state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.categories.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('No categories found.')),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: state.categories.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.categories.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final category = state.categories[index];
                      return Dismissible(
                        key: ValueKey(category.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm"),
                                content: const Text("Are you sure you wish to delete this category?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("CANCEL")),
                                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("DELETE")),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          ref.read(categoryListProvider.notifier).deleteCategory(category.id!);
                        },
                        child: ListTile(
                          title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(category.description ?? 'No description'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.push('/categories/edit', extra: category),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/categories/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
