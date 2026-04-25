import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/habit.dart';
import '../../tasks/presentation/task_provider.dart';
import '../../chat/presentation/feedback_provider.dart';
import '../../../core/utils/service_failure.dart';
import 'streak_freeze_provider.dart';


final habitsStreamProvider = StreamProvider<List<Habit>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.getHabits();
});

final habitsProvider = NotifierProvider<HabitNotifier, List<Habit>>(HabitNotifier.new);

class HabitNotifier extends Notifier<List<Habit>> {
  // FIX H3: Mutation guard — prevents the Firestore stream (arriving after
  // a write) from overwriting an in-progress optimistic update.
  bool _isMutating = false;

  @override
  List<Habit> build() {
    final streamData = ref.watch(habitsStreamProvider).value ?? [];
    // Only replace state from stream when no optimistic mutation is in flight.
    if (_isMutating) return state;
    return streamData;
  }

  Future<void> addHabit(Habit habit) async {
    final previousState = state;
    _isMutating = true;
    state = [...state, habit];
    try {
      await ref.read(firestoreServiceProvider)?.saveHabit(habit);
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => addHabit(habit),
      );
    } finally {
      _isMutating = false;
    }
  }

  int _calculateStreak(List<DateTime> completedDates, {List<DateTime> frozenDates = const []}) {
    if (completedDates.isEmpty && frozenDates.isEmpty) return 0;
    // Merge completed + frozen dates — frozen dates count as "present"
    final allDates = [
      ...completedDates,
      ...frozenDates,
    ].map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    if (allDates.isEmpty) return 0;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));
    
    if (allDates.first.isBefore(yesterdayDate)) return 0;

    int streak = 0;
    DateTime currentCheck = allDates.first;
    for (final date in allDates) {
      if (date == currentCheck) {
        streak++;
        currentCheck = currentCheck.subtract(const Duration(days: 1));
      } else if (date.isBefore(currentCheck)) {
        break;
      }
    }
    return streak;
  }

  Future<void> toggleHabitDay(String id, DateTime date) async {
    final habitIndex = state.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    final habit = state[habitIndex];
    final dateOnly = DateTime(date.year, date.month, date.day);
    final isCompleted = habit.completedDates.any((d) => DateTime(d.year, d.month, d.day) == dateOnly);

    final updatedDates = isCompleted
        ? habit.completedDates.where((d) => DateTime(d.year, d.month, d.day) != dateOnly).toList()
        : [...habit.completedDates, dateOnly];

    final updatedHabit = habit.copyWith(
      completedDates: updatedDates,
      streak: _calculateStreak(updatedDates, frozenDates: habit.frozenDates),
    );

    final previousState = state;
    _isMutating = true;
    state = [for (final h in state) if (h.id == id) updatedHabit else h];
    try {
      await ref.read(firestoreServiceProvider)?.saveHabit(updatedHabit);
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => toggleHabitDay(id, date),
      );
    } finally {
      _isMutating = false;
    }
  }

  Future<void> updateHabit(String id, {String? name, String? icon}) async {
    final habitIndex = state.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    final updatedHabit = state[habitIndex].copyWith(name: name, icon: icon);
    final previousState = state;
    _isMutating = true;
    state = [for (final h in state) if (h.id == id) updatedHabit else h];
    try {
      await ref.read(firestoreServiceProvider)?.saveHabit(updatedHabit);
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => updateHabit(id, name: name, icon: icon),
      );
    } finally {
      _isMutating = false;
    }
  }

  Future<void> deleteHabit(String id) async {
    final previousState = state;
    _isMutating = true;
    state = state.where((h) => h.id != id).toList();
    try {
      await ref.read(firestoreServiceProvider)?.deleteHabit(id);
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => deleteHabit(id),
      );
    } finally {
      _isMutating = false;
    }
  }

  /// Pro feature: Apply a Streak Freeze token to today for a specific habit.
  /// Returns false if not Pro, no tokens left, or habit not found.
  Future<bool> freezeStreak(String id) async {
    final habitIndex = state.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return false;

    final consumed = ref.read(streakFreezeProvider.notifier).useFreeze();
    if (!consumed) return false;

    final habit = state[habitIndex];
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final alreadyFrozen = habit.frozenDates.any(
      (d) => DateTime(d.year, d.month, d.day) == todayOnly,
    );
    if (alreadyFrozen) return true;

    final updatedFrozen = [...habit.frozenDates, todayOnly];
    final updatedHabit = habit.copyWith(
      frozenDates: updatedFrozen,
      streak: _calculateStreak(habit.completedDates, frozenDates: updatedFrozen),
    );

    final previousState = state;
    _isMutating = true;
    state = [for (final h in state) if (h.id == id) updatedHabit else h];
    try {
      await ref.read(firestoreServiceProvider)?.saveHabit(updatedHabit);
      return true;
    } catch (e) {
      state = previousState;
      // Refund token on failure
      ref.read(streakFreezeProvider.notifier).refundFreeze();
      
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => freezeStreak(id),
      );
      return false;
    } finally {
      _isMutating = false;
    }
  }
}
