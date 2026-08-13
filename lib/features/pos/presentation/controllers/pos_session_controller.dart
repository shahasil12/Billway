import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pos_session.dart';
import '../../domain/repositories/pos_repository.dart';

class POSSessionState {
  final bool isLoading;
  final String? error;
  final POSSession? session;

  POSSessionState({
    this.isLoading = false,
    this.error,
    this.session,
  });

  POSSessionState copyWith({
    bool? isLoading,
    String? error,
    POSSession? session,
    bool clearError = false,
  }) {
    return POSSessionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      session: session ?? this.session,
    );
  }
}

class POSSessionController extends StateNotifier<POSSessionState> {
  final POSRepository _repository;

  POSSessionController(this._repository) : super(POSSessionState()) {
    checkCurrentSession();
  }

  Future<void> checkCurrentSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getCurrentSession();
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (session) => state = state.copyWith(isLoading: false, session: session),
    );
  }

  Future<bool> openSession(double openingCash) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.openSession(openingCash);
    
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (session) {
        state = state.copyWith(isLoading: false, session: session);
        return true;
      },
    );
  }

  Future<bool> closeSession(double closingCash) async {
    if (state.session == null) return false;
    
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.closeSession(state.session!.id, closingCash);
    
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (session) {
        state = state.copyWith(isLoading: false, session: null);
        return true;
      },
    );
  }
}
