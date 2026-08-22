import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../../../../core/providers.dart';

class ProductListState {
  final List<Product> products;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int page;
  final String searchQuery;
  final int? categoryId;

  ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.page = 1,
    this.searchQuery = '',
    this.categoryId,
  });

  ProductListState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? page,
    String? searchQuery,
    int? categoryId,
    bool clearCategory = false,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }
}

class ProductListController extends StateNotifier<ProductListState> {
  final Ref ref;

  ProductListController(this.ref) : super(ProductListState()) {
    fetchProducts();
  }

  Future<void> fetchProducts({bool isRefresh = false}) async {
    if (state.isLoading) return;
    if (isRefresh) {
      state = state.copyWith(page: 1, hasMore: true, products: []);
    }

    if (!state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(productRepositoryProvider);
    final result = await repository.getProducts(
      page: state.page, 
      search: state.searchQuery,
      categoryId: state.categoryId,
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (paginated) {
        state = state.copyWith(
          isLoading: false,
          products: [...state.products, ...paginated.results],
          hasMore: paginated.next != null,
          page: state.page + 1,
        );
      },
    );
  }

  void setSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
    fetchProducts(isRefresh: true);
  }

  void setCategoryFilter(int? categoryId) {
    if (categoryId == state.categoryId) return;
    state = state.copyWith(categoryId: categoryId, clearCategory: categoryId == null);
    fetchProducts(isRefresh: true);
  }

  void resetFilters() {
    if (state.searchQuery.isEmpty && state.categoryId == null) {
      if (state.products.isEmpty && !state.isLoading) fetchProducts();
      return;
    }
    state = state.copyWith(searchQuery: '', clearCategory: true);
    fetchProducts(isRefresh: true);
  }

  Future<bool> deleteProduct(int id) async {
    final repository = ref.read(productRepositoryProvider);
    final result = await repository.deleteProduct(id);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          products: state.products.where((p) => p.id != id).toList(),
        );
        return true;
      },
    );
  }
}

final productListProvider = StateNotifierProvider<ProductListController, ProductListState>((ref) {
  return ProductListController(ref);
});
