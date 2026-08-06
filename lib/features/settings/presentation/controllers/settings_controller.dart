import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/settings.dart';
import '../../../../core/providers.dart';

class SettingsState {
  final Settings? settings;
  final bool isLoading;
  final String? error;

  SettingsState({
    this.settings,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    Settings? settings,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  final Ref ref;

  SettingsController(this.ref) : super(SettingsState()) {
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    final repository = ref.read(settingsRepositoryProvider);
    final result = await repository.getSettings();

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (settings) => state = state.copyWith(isLoading: false, settings: settings),
    );
  }

  Future<bool> updateSettings(Settings settings) async {
    state = state.copyWith(isLoading: true, error: null);
    final repository = ref.read(settingsRepositoryProvider);
    final result = await repository.updateSettings(settings);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (updatedSettings) {
        state = state.copyWith(isLoading: false, settings: updatedSettings);
        return true;
      },
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(ref);
});
