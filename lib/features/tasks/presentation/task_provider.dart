import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/task.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../chat/presentation/feedback_provider.dart';
import '../../dashboard/presentation/celebration_provider.dart';
import '../../../core/utils/service_failure.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/providers/shared_prefs_provider.dart';

// Services
final firestoreServiceProvider = Provider<FirestoreService?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return FirestoreService(uid: user.uid);
});

// --- Paginated Task State ---
class TaskPaginationState {
  static const Object _noChange = Object();

  final List<Task> tasks;
  final DocumentSnapshot? lastDoc;
  final bool isLoading;
  final bool hasMore;
  final bool isShowingRecentOnly;
  final bool hasSeenRecentOnlyBanner;
  final String? error;

  TaskPaginationState({
    this.tasks = const [],
    this.lastDoc,
    this.isLoading = false,
    this.hasMore = true,
    this.isShowingRecentOnly = false,
    this.hasSeenRecentOnlyBanner = false,
    this.error,
  });

  TaskPaginationState copyWith({
    List<Task>? tasks,
    DocumentSnapshot? lastDoc,
    bool? isLoading,
    bool? hasMore,
    bool? isShowingRecentOnly,
    bool? hasSeenRecentOnlyBanner,
    Object? error = _noChange,
  }) {
    return TaskPaginationState(
      tasks: tasks ?? this.tasks,
      lastDoc: lastDoc ?? this.lastDoc,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isShowingRecentOnly: isShowingRecentOnly ?? this.isShowingRecentOnly,
      hasSeenRecentOnlyBanner:
          hasSeenRecentOnlyBanner ?? this.hasSeenRecentOnlyBanner,
      error: identical(error, _noChange) ? this.error : error as String?,
    );
  }
}

// Dedicated metrics query provider (Last 90 days)
final metricsTasksProvider = StreamProvider<List<Task>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.getRecentMetricsTasks(days: 90);
});

// Filters & State
class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String value) => state = value;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(
      SelectedCategoryNotifier.new,
    );

class InsightsRangeNotifier extends Notifier<int> {
  static const _allowedRanges = [7, 30, 90];

  @override
  int build() => 90;

  void set(int value) {
    if (_allowedRanges.contains(value)) {
      state = value;
    }
  }
}

final insightsRangeProvider = NotifierProvider<InsightsRangeNotifier, int>(
  InsightsRangeNotifier.new,
);

class SortByNotifier extends Notifier<String> {
  @override
  String build() => 'date'; // 'date', 'priority', 'category'
  void set(String value) => state = value;
}

final taskSortByProvider = NotifierProvider<SortByNotifier, String>(
  SortByNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  Timer? _debounceTimer;

  @override
  String build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return '';
  }

  void set(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = value;
    });
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class CalendarSelectedDateNotifier extends Notifier<DateTime> {
  static const _key = 'calendar_selected_date';

  @override
  DateTime build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_key);
    if (saved != null) {
      try {
        return DateTime.parse(saved);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  void set(DateTime date) {
    state = date;
    ref.read(sharedPreferencesProvider).setString(_key, date.toIso8601String());
  }
}

final calendarSelectedDateProvider =
    NotifierProvider<CalendarSelectedDateNotifier, DateTime>(
      CalendarSelectedDateNotifier.new,
    );

class CalendarFormatNotifier extends Notifier<String> {
  static const _key = 'calendar_format';

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_key) ?? 'week';
  }

  void set(String format) {
    state = format;
    ref.read(sharedPreferencesProvider).setString(_key, format);
  }
}

final calendarFormatProvider = NotifierProvider<CalendarFormatNotifier, String>(
  CalendarFormatNotifier.new,
);

// For contextual task creation (tracking active tab in TasksScreen)
// Tabs: 0: Today, 1: Tomorrow, 2: Upcoming, 3: Overdue, 4: Completed
class TasksActiveTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int index) => state = index;
}

final tasksActiveTabProvider = NotifierProvider<TasksActiveTabNotifier, int>(
  TasksActiveTabNotifier.new,
);

final tasksProvider = NotifierProvider<TaskNotifier, TaskPaginationState>(
  TaskNotifier.new,
);

class TaskNotifier extends Notifier<TaskPaginationState> {
  final Set<String> _deletingIds = {};
  bool _isInit = false;
  int _dedupRetries = 0; // guards against infinite all-duplicate pages

  @override
  TaskPaginationState build() {
    // We don't watch a stream anymore for the whole list
    // Initial fetch is triggered by init() or build()
    if (!_isInit) {
      _isInit = true;
      // Use Future.microtask to avoid modifying state during build
      Future.microtask(() => loadNextPage());
    }
    return TaskPaginationState();
  }

  Future<void> loadNextPage() async {
    // 1. Double API call protection
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final firestore = ref.read(firestoreServiceProvider);
      if (firestore == null) throw Exception('User not authenticated');

      final snapshot = await firestore.getTasksPage(
        limit: 20,
        startAfter: state.lastDoc,
      );

      final fetchedDocs = snapshot.docs;
      final newTasks = fetchedDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Task.fromMap({...data, 'id': doc.id});
      }).toList();

      // 2. Duplicate prevention
      final existingIds = state.tasks.map((t) => t.id).toSet();
      final filteredNewTasks = newTasks
          .where((t) => !existingIds.contains(t.id))
          .toList();

      if (filteredNewTasks.isEmpty && newTasks.isNotEmpty) {
        // All fetched docs were duplicates. Advance cursor and cap retries to
        // prevent an infinite run if every page is full of duplicates.
        _dedupRetries++;
        if (_dedupRetries >= 3) {
          _dedupRetries = 0;
          state = state.copyWith(isLoading: false, hasMore: false);
        } else {
          state = state.copyWith(isLoading: false, lastDoc: fetchedDocs.last);
        }
        return;
      }
      _dedupRetries = 0; // reset on a clean page

      // 3. Update tasks list
      final combinedTasks = [...state.tasks, ...filteredNewTasks];

      state = state.copyWith(
        tasks: combinedTasks,
        lastDoc: fetchedDocs.isNotEmpty ? fetchedDocs.last : state.lastDoc,
        isLoading: false,
        hasMore: newTasks.length == 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: loadNextPage,
      );
    }
  }

  Future<void> refresh() async {
    state = TaskPaginationState();
    await loadNextPage();
  }

  void dismissRecentOnlyBanner() {
    state = state.copyWith(
      isShowingRecentOnly: false,
      hasSeenRecentOnlyBanner: true,
    );
  }

  FirestoreService? get _firestore => ref.read(firestoreServiceProvider);

  int _getNotificationId(String taskId) {
    return taskId.hashCode.abs() & 0x7FFFFFFF;
  }

  Future<void> _scheduleReminderForTask(Task task) async {
    final settings = ref.read(appSettingsProvider);
    if (!settings.notificationsEnabled) return;

    if (task.time != null && task.status != TaskStatus.completed) {
      if (!task.time!.contains(':')) return;

      final timeParts = task.time!.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;

      final scheduledDate = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        hour,
        minute,
      );

      if (scheduledDate.isAfter(DateTime.now())) {
        await NotificationService().scheduleNotification(
          id: _getNotificationId(task.id),
          title: 'Task Reminder',
          body: 'Start work on: ${task.title}',
          scheduledDate: scheduledDate,
        );
      }
    }
  }

  Future<void> _cancelReminderForTask(String taskId) async {
    await NotificationService().cancelNotification(_getNotificationId(taskId));
  }

  Future<void> resyncAllReminders() async {
    await NotificationService().cancelAllNotifications();

    final settings = ref.read(appSettingsProvider);
    if (!settings.notificationsEnabled) return;

    for (final task in state.tasks) {
      await _scheduleReminderForTask(task);
    }
  }

  Future<void> addTask(Task task) async {
    final previousState = state;
    // Prepend new task for instant feedback
    state = state.copyWith(tasks: [task, ...state.tasks]);
    try {
      await _firestore?.saveTask(task);
      await _scheduleReminderForTask(task);
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => addTask(task),
      );
    }
  }

  Future<void> updateTask(Task task) async {
    final previousState = state;
    state = state.copyWith(
      tasks: [
        for (final t in state.tasks)
          if (t.id == task.id) task else t,
      ],
    );
    try {
      await _cancelReminderForTask(task.id);
      await _firestore?.saveTask(task);
      await _scheduleReminderForTask(task);
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => updateTask(task),
      );
    }
  }

  Future<bool> toggleTask(String id) async {
    final taskIndex = state.tasks.indexWhere((t) => t.id == id);
    if (taskIndex == -1) return false;

    final previousState = state;
    final task = state.tasks[taskIndex];
    final isCompleting = task.status != TaskStatus.completed;
    final updatedTask = task.copyWith(
      status: isCompleting ? TaskStatus.completed : TaskStatus.todo,
    );

    state = state.copyWith(
      tasks: [
        for (final t in state.tasks)
          if (t.id == id) updatedTask else t,
      ],
    );
    try {
      await _firestore?.saveTask(updatedTask);
      if (isCompleting) {
        await _cancelReminderForTask(id);

        // Handle recurrence
        if (task.recurrence != null && task.recurrence!.isNotEmpty) {
          await _handleRecurrence(task);
        }

        final settings = ref.read(appSettingsProvider);
        if (settings.enableCelebration) {
          ref.read(celebrationProvider.notifier).trigger();
        }
      } else {
        await _scheduleReminderForTask(updatedTask);
      }
      return isCompleting;
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => toggleTask(id),
      );
      return !isCompleting;
    }
  }

  Future<void> _handleRecurrence(Task task) async {
    final nextDate = _getNextOccurrenceDate(task.date, task.recurrence!);

    final newTask = task.copyWith(
      id: AppUtils.generateId(prefix: 'task'),
      date: nextDate,
      status: TaskStatus.todo,
    );

    await addTask(newTask);

    final dateLabel = newTask.displayDate;
    ref.read(feedbackProvider.notifier).showMessage(
      '🔁 Next "${task.title}" scheduled for $dateLabel',
    );
  }

  DateTime _getNextOccurrenceDate(DateTime from, String recurrence) {
    final normalized = recurrence.toLowerCase();

    if (normalized == 'daily' || normalized == 'everyday') {
      return from.add(const Duration(days: 1));
    } else if (normalized == 'weekly') {
      return from.add(const Duration(days: 7));
    } else if (normalized == 'monthly') {
      return DateTime(from.year, from.month + 1, from.day);
    } else if (normalized.startsWith('every ')) {
      final dayName = normalized.replaceFirst('every ', '').trim();
      final targetDay = _dayNameToInt(dayName);
      int daysAhead = targetDay - from.weekday;
      if (daysAhead <= 0) daysAhead += 7;
      return from.add(Duration(days: daysAhead));
    }

    return from.add(const Duration(days: 1)); // Default fallback
  }

  int _dayNameToInt(String day) {
    switch (day) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  Future<void> deleteTask(String id) async {
    final previousState = state;
    _deletingIds.add(id);
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != id).toList(),
    );
    try {
      await _cancelReminderForTask(id);
      await _firestore?.deleteTask(id);
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => deleteTask(id),
      );
    } finally {
      _deletingIds.remove(id);
    }
  }

  Future<void> deleteTasks(List<String> ids) async {
    if (ids.isEmpty) return;
    final previousState = state;
    _deletingIds.addAll(ids);
    state = state.copyWith(
      tasks: state.tasks.where((t) => !ids.contains(t.id)).toList(),
    );
    try {
      for (final id in ids) {
        await _cancelReminderForTask(id);
      }
      await _firestore?.deleteTasksBatch(ids);
    } catch (e) {
      state = previousState;
      ref.read(feedbackProvider.notifier).showError(
        ServiceFailure.fromFirestore(e),
        onRetry: () => deleteTasks(ids),
      );
    } finally {
      _deletingIds.removeAll(ids);
    }
  }
}

// Filtered and Sorted Providers
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasksState = ref.watch(tasksProvider);
  final tasks = tasksState.tasks;
  final category = ref.watch(selectedCategoryProvider);
  final search = ref.watch(searchQueryProvider).toLowerCase();
  final sortBy = ref.watch(taskSortByProvider);

  var filtered = List<Task>.from(tasks);

  // 1. Category Filter
  if (category != 'All') {
    filtered = filtered.where((t) => t.category == category).toList();
  }

  // 2. Search Filter
  if (search.isNotEmpty) {
    filtered = filtered
        .where(
          (t) =>
              t.title.toLowerCase().contains(search) ||
              t.category.toLowerCase().contains(search),
        )
        .toList();
  }

  // 3. Sort Logic
  filtered.sort((a, b) {
    switch (sortBy) {
      case 'priority':
        final pCompare = b.priority.index.compareTo(a.priority.index);
        if (pCompare != 0) return pCompare;
        return a.date.compareTo(b.date);
      case 'category':
        final catCompare = a.category.compareTo(b.category);
        if (catCompare != 0) return catCompare;
        return a.date.compareTo(b.date);
      case 'date':
      default:
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        final aMin = a.timeInMinutes;
        final bMin = b.timeInMinutes;
        if (aMin == null && bMin == null) return a.title.compareTo(b.title);
        if (aMin == null) return 1;
        if (bMin == null) return -1;
        return aMin.compareTo(bMin);
    }
  });

  return filtered;
});

final activeTasksProvider = Provider<List<Task>>(
  (ref) => ref
      .watch(filteredTasksProvider)
      .where((t) => t.status != TaskStatus.completed)
      .toList(),
);
final completedTasksProvider = Provider<List<Task>>(
  (ref) => ref
      .watch(filteredTasksProvider)
      .where((t) => t.status == TaskStatus.completed)
      .toList(),
);
final todayTasksProvider = Provider<List<Task>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final category = ref.watch(selectedCategoryProvider);
  final search = ref.watch(searchQueryProvider).toLowerCase();
  final tasks = ref.watch(tasksForDateProvider(today));

  return tasks.where((task) {
    if (category != 'All' && task.category != category) return false;
    if (search.isNotEmpty &&
        !task.title.toLowerCase().contains(search) &&
        !task.category.toLowerCase().contains(search)) {
      return false;
    }
    return true;
  }).toList();
});
final tomorrowTasksProvider = Provider<List<Task>>((ref) {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  final category = ref.watch(selectedCategoryProvider);
  final search = ref.watch(searchQueryProvider).toLowerCase();
  final tasks = ref.watch(tasksForDateProvider(date));

  return tasks.where((task) {
    if (category != 'All' && task.category != category) return false;
    if (search.isNotEmpty &&
        !task.title.toLowerCase().contains(search) &&
        !task.category.toLowerCase().contains(search)) {
      return false;
    }
    return true;
  }).toList();
});
final upcomingTasksProvider = Provider<List<Task>>((ref) {
  final now = DateTime.now();
  final dayAfterTomorrow = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 2));
  final endRange = dayAfterTomorrow.add(
    const Duration(days: 90),
  ); // Show next 3 months

  final tasksAsync = ref.watch(
    calendarTasksProvider(
      DateTimeRange(start: dayAfterTomorrow, end: endRange),
    ),
  );
  final tasks = tasksAsync.value ?? [];

  // Bug #5 Fix: Category & Search filter-ஐ Upcoming tab-லயும் apply பண்றோம்
  final category = ref.watch(selectedCategoryProvider);
  final search = ref.watch(searchQueryProvider).toLowerCase();

  var filtered = tasks;
  if (category != 'All') {
    filtered = filtered.where((t) => t.category == category).toList();
  }
  if (search.isNotEmpty) {
    filtered = filtered
        .where(
          (t) =>
              t.title.toLowerCase().contains(search) ||
              t.category.toLowerCase().contains(search),
        )
        .toList();
  }
  return filtered;
});
final overdueTasksProvider = Provider<List<Task>>((ref) {
  // Bug #8 Fix: metricsTasksProvider (90 days only) பதிலாக
  // tasksProvider (all loaded tasks) பயன்படுத்துகிறோம்
  // இதனால் பழைய overdue tasks-உம் காட்டப்படும்
  final tasks = ref.watch(filteredTasksProvider);
  return tasks.where((t) => t.isOverdue).toList();
});

final productivityMetricsProvider = Provider<Map<String, dynamic>>((ref) {
  final tasksAsync = ref.watch(metricsTasksProvider);
  final tasks = tasksAsync.value ?? [];
  final selectedRange = ref.watch(insightsRangeProvider);

  if (tasks.isEmpty) {
    return {
      'selectedRange': selectedRange,
      'totalHours': '0.0',
      'growth': 0,
      'weeklyProgress': List.generate(7, (_) => 0.0),
      'categoryDistribution': <String, double>{},
    };
  }

  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);
  final rangeStart = todayMidnight.subtract(Duration(days: selectedRange - 1));
  final sevenDaysAgo = todayMidnight.subtract(const Duration(days: 6));
  final previousWeekStart = sevenDaysAgo.subtract(const Duration(days: 7));

  final categoryCounts = <String, int>{};
  final dailyCounts = <DateTime, int>{};
  int completedCount = 0;
  int previousWeekCount = 0;

  for (final task in tasks) {
    if (task.status != TaskStatus.completed) continue;

    final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
    if (!taskDate.isBefore(rangeStart) && !taskDate.isAfter(todayMidnight)) {
      completedCount++;
      categoryCounts[task.category] = (categoryCounts[task.category] ?? 0) + 1;
    }

    if (!taskDate.isBefore(sevenDaysAgo) && !taskDate.isAfter(todayMidnight)) {
      dailyCounts[taskDate] = (dailyCounts[taskDate] ?? 0) + 1;
    }

    if (!taskDate.isBefore(previousWeekStart) &&
        taskDate.isBefore(sevenDaysAgo)) {
      previousWeekCount++;
    }
  }

  final weeklyProgress = List.generate(7, (i) {
    final day = sevenDaysAgo.add(Duration(days: i));
    return (dailyCounts[day] ?? 0).toDouble();
  });

  final categoryDistribution = categoryCounts.map(
    (k, v) => MapEntry(k, completedCount > 0 ? v / completedCount : 0.0),
  );

  final thisWeekCount = weeklyProgress.fold<double>(0.0, (acc, v) => acc + v);
  int growth = 0;
  if (previousWeekCount > 0) {
    growth = ((thisWeekCount - previousWeekCount) / previousWeekCount * 100)
        .round();
  } else if (thisWeekCount > 0) {
    growth = 100;
  }

  return {
    'selectedRange': selectedRange,
    'totalHours': (completedCount * 0.5).toStringAsFixed(1),
    'growth': growth,
    'weeklyProgress': weeklyProgress,
    'categoryDistribution': categoryDistribution,
    'completedTasks': completedCount,
  };
});

final taskStatsProvider = Provider<Map<String, int>>((ref) {
  final tasks = ref.watch(tasksProvider).tasks;
  final todayTasks = tasks.where((t) => t.isToday).toList();
  final todayCompleted = todayTasks
      .where((t) => t.status == TaskStatus.completed)
      .length;
  return {
    'total': tasks.length,
    'completed': tasks.where((t) => t.status == TaskStatus.completed).length,
    'pending': tasks.where((t) => t.status != TaskStatus.completed).length,
    'today': tasks
        .where((t) => t.isToday && t.status != TaskStatus.completed)
        .length,
    'todayTotal': todayTasks.length,
    'todayCompleted': todayCompleted,
  };
});

// Get current month as a stable key for markers
final calendarVisibleMonthProvider = Provider<DateTime>((ref) {
  final selected = ref.watch(calendarSelectedDateProvider);
  return DateTime(selected.year, selected.month);
});

// Range provider for calendar markers and day-specific tasks
final calendarTasksProvider = StreamProvider.family<List<Task>, DateTimeRange>((
  ref,
  range,
) {
  final firestore = ref.watch(firestoreServiceProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.getTasksForRange(range.start, range.end);
});

// Maps each date to the count of tasks on that date (for calendar density markers)
final taskDateCountsProvider = Provider<Map<DateTime, int>>((ref) {
  final monthDate = ref.watch(calendarVisibleMonthProvider);
  final start = DateTime(monthDate.year, monthDate.month - 1, 1);
  final end = DateTime(monthDate.year, monthDate.month + 2, 0);

  final tasksAsync = ref.watch(
    calendarTasksProvider(DateTimeRange(start: start, end: end)),
  );
  final tasks = tasksAsync.value ?? [];

  final counts = <DateTime, int>{};
  for (final t in tasks) {
    final d = DateTime(t.date.year, t.date.month, t.date.day);
    counts[d] = (counts[d] ?? 0) + 1;
  }
  return counts;
});

final taskDatesProvider = Provider<Set<DateTime>>((ref) {
  // Only re-run when month changes
  final monthDate = ref.watch(calendarVisibleMonthProvider);

  // Fetch markers for current month +/- 1 month for smooth sliding
  final start = DateTime(monthDate.year, monthDate.month - 1, 1);
  final end = DateTime(monthDate.year, monthDate.month + 2, 0);

  final tasksAsync = ref.watch(
    calendarTasksProvider(DateTimeRange(start: start, end: end)),
  );
  final tasks = tasksAsync.value ?? [];

  return tasks
      .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
      .toSet();
});

final tasksForDateProvider = Provider.family<List<Task>, DateTime>((ref, date) {
  // Normalize date to prevent unnecessary family member creation
  final start = DateTime(date.year, date.month, date.day);
  final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

  final tasksAsync = ref.watch(
    calendarTasksProvider(DateTimeRange(start: start, end: end)),
  );
  return tasksAsync.value ?? [];
});

final sortedTasksForDateProvider = Provider.family<List<Task>, DateTime>((
  ref,
  date,
) {
  final tasks = ref.watch(tasksForDateProvider(date));
  final sorted = List<Task>.from(tasks);
  sorted.sort((a, b) {
    final aMin = a.timeInMinutes;
    final bMin = b.timeInMinutes;
    if (aMin == null && bMin == null) return a.title.compareTo(b.title);
    if (aMin == null) return 1;
    if (bMin == null) return -1;
    return aMin.compareTo(bMin);
  });
  return sorted;
});
