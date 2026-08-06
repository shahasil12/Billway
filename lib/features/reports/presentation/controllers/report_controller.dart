import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/report.dart';
import '../../../../core/providers.dart';
import 'package:intl/intl.dart';

class ReportState {
  final Report? report;
  final bool isLoading;
  final String? error;
  final String dateRangeLabel;
  final String? startDate;
  final String? endDate;

  ReportState({
    this.report,
    this.isLoading = false,
    this.error,
    this.dateRangeLabel = 'Last 30 Days',
    this.startDate,
    this.endDate,
  });

  ReportState copyWith({
    Report? report,
    bool? isLoading,
    String? error,
    String? dateRangeLabel,
    String? startDate,
    String? endDate,
  }) {
    return ReportState(
      report: report ?? this.report,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      dateRangeLabel: dateRangeLabel ?? this.dateRangeLabel,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class ReportController extends StateNotifier<ReportState> {
  final Ref ref;

  ReportController(this.ref) : super(ReportState()) {
    fetchReport();
  }

  Future<void> fetchReport({String? startDate, String? endDate, String? label}) async {
    state = state.copyWith(
      isLoading: true, 
      error: null,
      startDate: startDate,
      endDate: endDate,
      dateRangeLabel: label ?? state.dateRangeLabel,
    );

    final repository = ref.read(reportRepositoryProvider);
    final result = await repository.getReport(startDate: startDate, endDate: endDate);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (report) {
        state = state.copyWith(isLoading: false, report: report);
      },
    );
  }

  void setDateRange(String label) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    String? start;
    String? end = formatter.format(now);

    switch (label) {
      case 'Today':
        start = end;
        break;
      case 'This Week':
        start = formatter.format(now.subtract(Duration(days: now.weekday - 1)));
        break;
      case 'This Month':
        start = formatter.format(DateTime(now.year, now.month, 1));
        break;
      case 'Last 30 Days':
      default:
        start = formatter.format(now.subtract(const Duration(days: 30)));
        label = 'Last 30 Days';
        break;
    }
    
    fetchReport(startDate: start, endDate: end, label: label);
  }
}

final reportProvider = StateNotifierProvider<ReportController, ReportState>((ref) {
  return ReportController(ref);
});
