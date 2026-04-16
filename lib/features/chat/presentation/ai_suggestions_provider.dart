import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../habits/presentation/habit_provider.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_provider.dart';
import '../domain/ai_action_model.dart';

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

final aiSuggestionsProvider =
    NotifierProvider<AISuggestionNotifier, List<AISuggestion>>(() {
      return AISuggestionNotifier();
    });

class AISuggestionNotifier extends Notifier<List<AISuggestion>> {
  // Tracks manually or auto-dismissed suggestion IDs so they stay hidden
  // even after build() recomputes from new task/habit data.
  final Set<String> _dismissedIds = {};

  @override
  List<AISuggestion> build() {
    final overdue = ref.watch(overdueTasksProvider);
    final habits = ref.watch(habitsProvider);

    List<AISuggestion> newSuggestions = [];

    // 1. Overdue Bottleneck
    if (overdue.length >= 3) {
      newSuggestions.add(
        AISuggestion(
          id: 'reschedule_overdue',
          title: 'Overdue Cleanup 🧹',
          description:
              'You have ${overdue.length} overdue tasks. Want me to move them to tomorrow?',
          icon: LucideIcons.calendarClock,
          action: AIAction(
            id: 'reschedule_all_${DateTime.now().millisecondsSinceEpoch}',
            type: AIActionType.rescheduleAll,
            parameters: {
              'newDate': DateTime.now()
                  .add(const Duration(days: 1))
                  .toIso8601String()
                  .split('T')[0],
            },
          ),
        ),
      );
    }

    // 2. High Priority Focus
    final highPriorityPending = overdue
        .where((t) => t.priority == TaskPriority.high)
        .length;
    if (highPriorityPending > 0) {
      newSuggestions.add(
        AISuggestion(
          id: 'focus_high_priority',
          title: 'Priority Alert 🎯',
          description:
              'You have $highPriorityPending high-priority tasks pending. Take a focus break?',
          icon: LucideIcons.target,
        ),
      );
    }

    // 3. Habit Streak Saver
    for (final habit in habits) {
      if (!habit.completedToday && habit.streak >= 3) {
        newSuggestions.add(
          AISuggestion(
            id: 'save_streak_${habit.id}',
            title: 'Save your streak! 🔥',
            description:
                'Don\'t let "${habit.name}" break its ${habit.streak} day streak. You got this!',
            icon: LucideIcons.flame,
          ),
        );
      }
    }

    // Filter out already-dismissed suggestions
    final visible = newSuggestions.where((s) => !_dismissedIds.contains(s.id)).toList();

    // Schedule auto-dismiss via microtask — avoids side-effects inside build()
    Future.microtask(() => _scheduleAutoDismiss(visible));

    return visible;
  }

  // Auto-dismiss scheduling extracted out of build() to avoid Riverpod anti-pattern
  void _scheduleAutoDismiss(List<AISuggestion> suggestions) {
    for (final s in suggestions) {
      final pendingKey = '__sched_${s.id}';
      if (!_dismissedIds.contains(pendingKey)) {
        _dismissedIds.add(pendingKey);
        Future.delayed(const Duration(seconds: 30), () {
          dismissSuggestion(s.id);
        });
      }
    }
  }

  void dismissSuggestion(String id) {
    _dismissedIds.add(id);
    state = state.where((s) => s.id != id).toList();
  }

  void dismissAll() {
    for (final s in state) {
      _dismissedIds.add(s.id);
    }
    state = [];
  }
}
