import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer.dart';
import '../../../../core/providers.dart';

class CustomerListState {
  final List<Customer> customers;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int page;
  final String searchQuery;

  CustomerListState({
    this.customers = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.page = 1,
    this.searchQuery = '',
  });

  CustomerListState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? page,
    String? searchQuery,
  }) {
    return CustomerListState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CustomerListController extends StateNotifier<CustomerListState> {
  final Ref ref;

  CustomerListController(this.ref) : super(CustomerListState()) {
    fetchCustomers();
  }

  Future<void> fetchCustomers({bool isRefresh = false}) async {
    if (state.isLoading) return;
    if (isRefresh) {
      state = state.copyWith(page: 1, hasMore: true, customers: []);
    }

    if (!state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(customerRepositoryProvider);
    final result = await repository.getCustomers(page: state.page, search: state.searchQuery);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (paginated) {
        state = state.copyWith(
          isLoading: false,
          customers: [...state.customers, ...paginated.results],
          hasMore: paginated.next != null,
          page: state.page + 1,
        );
      },
    );
  }

  void setSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
    fetchCustomers(isRefresh: true);
  }

  Future<bool> deleteCustomer(int id) async {
    final repository = ref.read(customerRepositoryProvider);
    final result = await repository.deleteCustomer(id);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          customers: state.customers.where((c) => c.id != id).toList(),
        );
        return true;
      },
    );
  }
}

final customerListProvider = StateNotifierProvider<CustomerListController, CustomerListState>((ref) {
  return CustomerListController(ref);
});
