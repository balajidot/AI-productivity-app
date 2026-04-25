import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../../settings/presentation/settings_provider.dart';

// ─── Constants ──────────────────────────────────────────────────────────────
const int kFreezeTokensPerMonth = 3;

// ─── State ───────────────────────────────────────────────────────────────────
class StreakFreezeState {
  final int usedThisMonth;
  final String monthKey; // 'yyyy-MM'

  const StreakFreezeState({required this.usedThisMonth, required this.monthKey});

  int get remaining => (kFreezeTokensPerMonth - usedThisMonth).clamp(0, kFreezeTokensPerMonth);
  bool get hasTokens => usedThisMonth < kFreezeTokensPerMonth;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class StreakFreezeNotifier extends Notifier<StreakFreezeState> {
  static const _countKey = 'freeze_monthly_count';
  static const _monthKeyPref = 'freeze_monthly_key';

  String get _thisMonthKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  @override
  StreakFreezeState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedMonth = prefs.getString(_monthKeyPref) ?? '';
    final thisMonth = _thisMonthKey;

    // New month → reset
    if (savedMonth != thisMonth) {
      return StreakFreezeState(usedThisMonth: 0, monthKey: thisMonth);
    }
    return StreakFreezeState(
      usedThisMonth: prefs.getInt(_countKey) ?? 0,
      monthKey: thisMonth,
    );
  }

  /// Returns true and records usage. Returns false if no tokens left or not Pro.
  bool useFreeze() {
    final isPro = ref.read(isPremiumProvider);
    if (!isPro) return false;
    if (!state.hasTokens) return false;

    final prefs = ref.read(sharedPreferencesProvider);
    final thisMonth = _thisMonthKey;
    final newCount = (state.monthKey == thisMonth ? state.usedThisMonth : 0) + 1;

    prefs.setString(_monthKeyPref, thisMonth);
    prefs.setInt(_countKey, newCount);
    state = StreakFreezeState(usedThisMonth: newCount, monthKey: thisMonth);
    return true;
  }

  /// Refunds a token if a transaction fails.
  void refundFreeze() {
    if (state.usedThisMonth > 0) {
      final newCount = state.usedThisMonth - 1;
      ref.read(sharedPreferencesProvider).setInt(_countKey, newCount);
      state = StreakFreezeState(usedThisMonth: newCount, monthKey: state.monthKey);
    }
  }
}

final streakFreezeProvider = NotifierProvider<StreakFreezeNotifier, StreakFreezeState>(
  StreakFreezeNotifier.new,
);
