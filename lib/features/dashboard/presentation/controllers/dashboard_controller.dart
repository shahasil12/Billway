import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../../../core/providers.dart';

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getDashboardSummary();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (summary) => summary,
  );
});
