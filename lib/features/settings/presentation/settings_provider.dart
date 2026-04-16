import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_settings.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import 'subscription_provider.dart';

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const String _settingsKey = 'app_settings_v1';

  @override
  AppSettings build() {
    // Read synchronously from the SharedPreferences instance injected in
    // main.dart's ProviderScope — no async gap, settings load immediately.
    final prefs = ref.watch(sharedPreferencesProvider);
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        return AppSettings.fromMap(
          jsonDecode(settingsJson) as Map<String, dynamic>,
        );
      } catch (e) {
        debugPrint('Error loading settings: $e');
      }
    }
    return const AppSettings();
  }

  void _save() {
    ref.read(sharedPreferencesProvider).setString(
      _settingsKey,
      jsonEncode(state.toMap()),
    );
  }

  void updateSmartAnalysis(bool value) {
    state = state.copyWith(smartAnalysis: value);
    _save();
  }

  void updateAITone(String value) {
    state = state.copyWith(aiTone: value);
    _save();
  }

  void updateTheme(String value) {
    state = state.copyWith(themeMode: value);
    _save();
  }

  void updateNotificationsEnabled(bool value) {
    state = state.copyWith(notificationsEnabled: value);
    _save();
  }

  void updateCelebration(bool value) {
    state = state.copyWith(enableCelebration: value);
    _save();
  }

  void updateSound(bool value) {
    state = state.copyWith(enableSound: value);
    _save();
  }

  void updateAiModel(String value) {
    state = state.copyWith(aiModelId: value);
    _save();
  }

  void updatePomodoroDuration(int value) {
    state = state.copyWith(pomodoroDuration: value);
    _save();
  }

  void updateShortBreakDuration(int value) {
    state = state.copyWith(shortBreakDuration: value);
    _save();
  }

  void updateLongBreakDuration(int value) {
    state = state.copyWith(longBreakDuration: value);
    _save();
  }

  void updateZenMode(bool value) {
    state = state.copyWith(zenModeEnabled: value);
    _save();
  }

  void updateHideCompletedTasks(bool value) {
    state = state.copyWith(hideCompletedTasks: value);
    _save();
  }
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, int>(NavigationNotifier.new);

class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;


  void set(int index) => state = index;
}

final isPremiumProvider = Provider<bool>((ref) {
  final subState = ref.watch(subscriptionProvider);
  return subState.isPro; 
});
