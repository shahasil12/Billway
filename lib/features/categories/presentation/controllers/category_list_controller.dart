import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import '../../../../core/providers.dart';

class CategoryListState {
  final List<Category> categories;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int page;
  final String searchQuery;

  CategoryListState({
    this.categories = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.page = 1,
    this.searchQuery = '',
  });

  CategoryListState copyWith({
    List<Category>? categories,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? page,
    String? searchQuery,
  }) {
    return CategoryListState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CategoryListController extends StateNotifier<CategoryListState> {
  final Ref ref;

  CategoryListController(this.ref) : super(CategoryListState()) {
    fetchCategories();
  }

  Future<void> fetchCategories({bool isRefresh = false}) async {
    if (state.isLoading) return;
    if (isRefresh) {
      state = state.copyWith(page: 1, hasMore: true, categories: []);
    }

    if (!state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(categoryRepositoryProvider);
    final result = await repository.getCategories(page: state.page, search: state.searchQuery);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (paginated) {
        state = state.copyWith(
          isLoading: false,
          categories: [...state.categories, ...paginated.results],
          hasMore: paginated.next != null,
          page: state.page + 1,
        );
      },
    );
  }

  void setSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
    fetchCategories(isRefresh: true);
  }

  Future<bool> deleteCategory(int id) async {
    final repository = ref.read(categoryRepositoryProvider);
    final result = await repository.deleteCategory(id);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          categories: state.categories.where((c) => c.id != id).toList(),
        );
        return true;
      },
    );
  }
}

final categoryListProvider = StateNotifierProvider<CategoryListController, CategoryListState>((ref) {
  return CategoryListController(ref);
});
