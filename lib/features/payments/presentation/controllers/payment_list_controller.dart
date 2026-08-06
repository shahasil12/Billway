import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payment.dart';
import '../../../../core/providers.dart';

class PaymentListState {
  final List<Payment> payments;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int page;

  PaymentListState({
    this.payments = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.page = 1,
  });

  PaymentListState copyWith({
    List<Payment>? payments,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? page,
  }) {
    return PaymentListState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      page: page ?? this.page,
    );
  }
}

class PaymentListController extends StateNotifier<PaymentListState> {
  final Ref ref;

  PaymentListController(this.ref) : super(PaymentListState()) {
    fetchPayments();
  }

  Future<void> fetchPayments({bool isRefresh = false}) async {
    if (state.isLoading) return;
    if (isRefresh) {
      state = state.copyWith(page: 1, hasMore: true, payments: []);
    }

    if (!state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(paymentRepositoryProvider);
    final result = await repository.getPayments(page: state.page);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (paginated) {
        state = state.copyWith(
          isLoading: false,
          payments: [...state.payments, ...paginated.results],
          hasMore: paginated.next != null,
          page: state.page + 1,
        );
      },
    );
  }
}

final paymentListProvider = StateNotifierProvider<PaymentListController, PaymentListState>((ref) {
  return PaymentListController(ref);
});
