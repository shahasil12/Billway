import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/invoice.dart';
import '../../../../core/providers.dart';

class InvoiceListState {
  final List<Invoice> invoices;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int page;
  final String searchQuery;

  InvoiceListState({
    this.invoices = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.page = 1,
    this.searchQuery = '',
  });

  InvoiceListState copyWith({
    List<Invoice>? invoices,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? page,
    String? searchQuery,
  }) {
    return InvoiceListState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class InvoiceListController extends StateNotifier<InvoiceListState> {
  final Ref ref;

  InvoiceListController(this.ref) : super(InvoiceListState()) {
    fetchInvoices();
  }

  Future<void> fetchInvoices({bool isRefresh = false}) async {
    if (state.isLoading) return;
    if (isRefresh) {
      state = state.copyWith(page: 1, hasMore: true, invoices: []);
    }

    if (!state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(invoiceRepositoryProvider);
    final result = await repository.getInvoices(
      page: state.page, 
      search: state.searchQuery,
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (paginated) {
        state = state.copyWith(
          isLoading: false,
          invoices: [...state.invoices, ...paginated.results],
          hasMore: paginated.next != null,
          page: state.page + 1,
        );
      },
    );
  }

  void setSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
    fetchInvoices(isRefresh: true);
  }
}

final invoiceListProvider = StateNotifierProvider<InvoiceListController, InvoiceListState>((ref) {
  return InvoiceListController(ref);
});
