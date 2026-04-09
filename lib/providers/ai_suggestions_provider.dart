import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'app_providers.dart';
import '../models/app_models.dart';
import '../models/ai_action_model.dart';

class AISuggestion {
  final String id;
  final String title;
  final String description;
  final AIAction? action;
  final dynamic icon;

  AISuggestion({
    required this.id,
    required this.title,
    required this.description,
    this.action,
    this.icon,
  });
}

final aiSuggestionsProvider = NotifierProvider<AISuggestionNotifier, List<AISuggestion>>(() {
  return AISuggestionNotifier();
});

class AISuggestionNotifier extends Notifier<List<AISuggestion>> {
  @override
  List<AISuggestion> build() {
    // Re-run whenever tasks or habits change
    final overdue = ref.watch(overdueTasksProvider);
    final habits = ref.watch(habitsProvider);
    
    List<AISuggestion> newSuggestions = [];

    // 1. Overdue Bottleneck
    if (overdue.length >= 3) {
      newSuggestions.add(AISuggestion(
        id: 'reschedule_overdue',
        title: 'Overdue Cleanup 🧹',
        description: 'You have ${overdue.length} overdue tasks. Want me to move them to tomorrow?',
        icon: LucideIcons.calendarClock,
        action: AIAction(
          id: 'reschedule_all_${DateTime.now().millisecondsSinceEpoch}',
          type: AIActionType.rescheduleAll,
          parameters: {'newDate': DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0]},
        ),
      ));
    }

    // 2. High Priority Focus
    final highPriorityPending = overdue.where((t) => t.priority == TaskPriority.high).length;
    if (highPriorityPending > 0) {
      newSuggestions.add(AISuggestion(
        id: 'focus_high_priority',
        title: 'Priority Alert 🎯',
        description: 'You have $highPriorityPending high-priority tasks pending. Take a focus break?',
        icon: LucideIcons.target,
      ));
    }

    // 3. Habit Streak Saver
    for (final habit in habits) {
      if (!habit.completedToday && habit.streak >= 3) {
        newSuggestions.add(AISuggestion(
          id: 'save_streak_${habit.id}',
          title: 'Save your streak! 🔥',
          description: 'Don\'t let "${habit.name}" break its ${habit.streak} day streak. You got this!',
          icon: LucideIcons.flame,
        ));
      }
    }

    return newSuggestions;
  }

  void dismissSuggestion(String id) {
    state = state.where((s) => s.id != id).toList();
  }
}
