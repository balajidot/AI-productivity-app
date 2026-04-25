import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/shared_prefs_provider.dart';
import '../../settings/presentation/settings_provider.dart';

// ─── Constants ──────────────────────────────────────────────────────────────
const int kFreeAiMessagesPerDay = 15;

// ─── State ───────────────────────────────────────────────────────────────────
class AiUsageState {
  final int usedToday;
  final String dateKey; // 'yyyy-MM-dd'

  const AiUsageState({required this.usedToday, required this.dateKey});

  int get remaining => (kFreeAiMessagesPerDay - usedToday).clamp(0, kFreeAiMessagesPerDay);
  bool get isLimitReached => usedToday >= kFreeAiMessagesPerDay;
  double get usagePercent => (usedToday / kFreeAiMessagesPerDay).clamp(0.0, 1.0);
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class AiUsageNotifier extends Notifier<AiUsageState> {
  static const _countKey = 'ai_daily_count';
  static const _dateKey = 'ai_daily_date';

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  AiUsageState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedDate = prefs.getString(_dateKey) ?? '';
    final today = _todayKey;

    // New day → reset counter
    if (savedDate != today) {
      return AiUsageState(usedToday: 0, dateKey: today);
    }
    final count = prefs.getInt(_countKey) ?? 0;
    return AiUsageState(usedToday: count, dateKey: today);
  }

  /// Returns true if message can be sent. False if limit reached (free users).
  bool canSendMessage() {
    final isPro = ref.read(isPremiumProvider);
    if (isPro) return true;
    return !state.isLimitReached;
  }

  /// Call AFTER a message is actually sent.
  void recordMessageSent() {
    final isPro = ref.read(isPremiumProvider);
    if (isPro) return; // Pro users — don't track

    final prefs = ref.read(sharedPreferencesProvider);
    final today = _todayKey;

    // Reset if new day
    if (state.dateKey != today) {
      prefs.setString(_dateKey, today);
      prefs.setInt(_countKey, 1);
      state = AiUsageState(usedToday: 1, dateKey: today);
      return;
    }

    final newCount = state.usedToday + 1;
    prefs.setString(_dateKey, today);
    prefs.setInt(_countKey, newCount);
    state = AiUsageState(usedToday: newCount, dateKey: today);
  }
}

final aiUsageProvider = NotifierProvider<AiUsageNotifier, AiUsageState>(
  AiUsageNotifier.new,
);
