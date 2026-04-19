import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/habit.dart';
import '../../tasks/presentation/task_provider.dart';
import '../../chat/presentation/feedback_provider.dart';
import '../../../core/utils/service_failure.dart';


final habitsStreamProvider = StreamProvider<List<Habit>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.getHabits();
});

final habitsProvider = NotifierProvider<HabitNotifier, List<Habit>>(HabitNotifier.new);

class HabitNotifier extends Notifier<List<Habit>> {
  @override
  List<Habit> build() {
    return ref.watch(habitsStreamProvider).value ?? [];
  }

  Future<void> addHabit(Habit habit) async {
    final previousState = state;
    state = [...state, habit];
    try {
      await ref.read(firestoreServiceProvider)?.saveHabit(habit);
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => addHabit(habit),
      );
    }
  }

  int _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    // Deduplicate dates first
    final uniqueDates = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));
    
    if (uniqueDates.first.isBefore(yesterdayDate)) return 0;
    
    int streak = 0;
    DateTime currentCheck = uniqueDates.first;
    for (final date in uniqueDates) {
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
      streak: _calculateStreak(updatedDates),
    );

    final previousState = state;
    state = [for (final h in state) if (h.id == id) updatedHabit else h];
    try {
      await ref.read(firestoreServiceProvider)?.saveHabit(updatedHabit);
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => toggleHabitDay(id, date),
      );
    }
  }

  Future<void> updateHabit(String id, {String? name, String? icon}) async {
    final habitIndex = state.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    final updatedHabit = state[habitIndex].copyWith(name: name, icon: icon);
    final previousState = state;
    state = [for (final h in state) if (h.id == id) updatedHabit else h];
    try {
      await ref.read(firestoreServiceProvider)?.saveHabit(updatedHabit);
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => updateHabit(id, name: name, icon: icon),
      );
    }
  }

  Future<void> deleteHabit(String id) async {
    final previousState = state;
    state = state.where((h) => h.id != id).toList();
    try {
      await ref.read(firestoreServiceProvider)?.deleteHabit(id);
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => deleteHabit(id),
      );
    }
  }
}
