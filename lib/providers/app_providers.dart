import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../models/message_model.dart';
import '../models/ai_action_model.dart';
import '../services/ai_service.dart';
import '../services/notification_service.dart';
import '../config/secrets.dart';
import 'auth_provider.dart';
import '../services/firestore_service.dart';

// Services
final firestoreServiceProvider = Provider<FirestoreService?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return FirestoreService(uid: user.uid);
});

final aiServiceProvider = Provider((ref) {
  return AIService(
    geminiApiKey: Secrets.geminiApiKey,
    nvidiaApiKey: Secrets.nvidiaApiKey,
    groqApiKey: Secrets.groqApiKey,
  );
});

// User Profile Providers
final userNameProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.displayName ?? 'User';
});

final userPhotoProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.photoURL;
});

final userEmailProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email ?? 'No email available';
});

// App Settings Provider
final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const String _settingsKey = 'app_settings_v1';

  @override
  AppSettings build() {
    // Initial build is synchronous, so we load from Prefs in background or use defaults
    _loadSettings();
    return const AppSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        state = AppSettings.fromMap(jsonDecode(settingsJson));
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(state.toMap()));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  void updateSmartAnalysis(bool value) {
    state = state.copyWith(smartAnalysis: value);
    _saveSettings();
  }

  void updateNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
    _saveSettings();
  }

  void updateAITone(String value) {
    state = state.copyWith(aiTone: value);
    _saveSettings();
  }

  void updateTheme(String value) {
    state = state.copyWith(themeMode: value);
    _saveSettings();
  }

  void updateAIModel(String value) {
    state = state.copyWith(aiModelId: value);
    _saveSettings();
  }

  void updateAutoAI(bool value) {
    state = state.copyWith(isAutoAI: value);
    _saveSettings();
  }
}

final performanceModeProvider = Provider<bool>((ref) {
  // WhatsApp-style automatic optimization: 
  // Detect if the device is lower-end (4 or fewer cores)
  // Devices with <= 4 cores will use a simplified "Optimized UI" for speed and battery.
  try {
    return Platform.numberOfProcessors <= 4;
  } catch (_) {
    return false; // Safely default to high performance if detection fails
  }
});

// Real-time Cloud Streams
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.getTasks();
});

final habitsStreamProvider = StreamProvider<List<Habit>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.getHabits();
});

final messagesStreamProvider = StreamProvider<List<AIMessage>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.getMessages();
});

// Category Filter
final selectedCategoryProvider = NotifierProvider<CategoryFilterNotifier, String>(CategoryFilterNotifier.new);

class CategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void set(String category) => state = category;
}

// Search Query Provider
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

// Navigation Provider (Riverpod 3.x style)
final navigationProvider = NotifierProvider<NavigationNotifier, int>(NavigationNotifier.new);

class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

// Tasks Provider
final tasksProvider = NotifierProvider<TaskNotifier, List<Task>>(TaskNotifier.new);

// Filtered Tasks Provider
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final category = ref.watch(selectedCategoryProvider);
  final search = ref.watch(searchQueryProvider).toLowerCase();

  var filtered = tasks;

  if (category != 'All') {
    filtered = filtered.where((t) => t.category == category).toList();
  }

  if (search.isNotEmpty) {
    filtered = filtered.where((t) => 
      t.title.toLowerCase().contains(search) || 
      t.category.toLowerCase().contains(search)
    ).toList();
  }

  return filtered;
});

// Active Tasks (non-completed)
final activeTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(filteredTasksProvider);
  return tasks.where((t) => t.status != TaskStatus.completed).toList();
});

// Completed Tasks
final completedTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(filteredTasksProvider);
  return tasks.where((t) => t.status == TaskStatus.completed).toList();
});

// Today's Active Tasks
final todayTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(activeTasksProvider);
  return tasks.where((t) => t.isToday).toList();
});

// Tomorrow's Active Tasks
final tomorrowTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(activeTasksProvider);
  return tasks.where((t) => t.isTomorrow).toList();
});

// Overdue Active Tasks
final overdueTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(activeTasksProvider);
  return tasks.where((t) => t.isOverdue).toList();
});

// Upcoming Active Tasks
final upcomingTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(activeTasksProvider);
  return tasks.where((t) => t.isUpcoming).toList();
});

// Tasks for a specific date
final tasksForDateProvider = Provider.family<List<Task>, DateTime>((ref, date) {
  final tasks = ref.watch(tasksProvider);
  return tasks.where((t) => 
    t.date.year == date.year && 
    t.date.month == date.month && 
    t.date.day == date.day
  ).toList();
});

// Dates that have tasks (for calendar markers)
final taskDatesProvider = Provider<Set<DateTime>>((ref) {
  final tasks = ref.watch(tasksProvider);
  return tasks.map((t) => DateTime(t.date.year, t.date.month, t.date.day)).toSet();
});

// Task stats
final taskStatsProvider = Provider<Map<String, int>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  final todayTasks = tasks.where((t) => 
    t.date.year == today.year && t.date.month == today.month && t.date.day == today.day
  ).toList();
  
  return {
    'total': tasks.length,
    'completed': tasks.where((t) => t.status == TaskStatus.completed).length,
    'todayTotal': todayTasks.length,
    'todayCompleted': todayTasks.where((t) => t.status == TaskStatus.completed).length,
    'todayPending': todayTasks.where((t) => t.status != TaskStatus.completed).length,
    'overdue': tasks.where((t) => t.isOverdue).length,
  };
});

// Advanced Productivity Metrics
final productivityMetricsProvider = Provider<Map<String, dynamic>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final now = DateTime.now();
  
  // 1. Completion rate last 7 days
  final last7Days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: i))).reversed.toList();
  final dailyCompletionData = last7Days.map((date) {
    return tasks.where((t) => 
      t.date.year == date.year && t.date.month == date.month && t.date.day == date.day && t.status == TaskStatus.completed
    ).length.toDouble();
  }).toList();

  // 2. Category Split
  final categories = ['Work', 'Personal', 'Health', 'Study', 'Finance', 'Inbox'];
  final categoryDistribution = <String, double>{};
  final totalTasks = tasks.length;
  if (totalTasks > 0) {
    for (final cat in categories) {
      final count = tasks.where((t) => t.category == cat).length;
      categoryDistribution[cat] = count / totalTasks;
    }
  }

  // 3. Estimated Focus Hours (Each task ~ 45 mins)
  final completedTotal = tasks.where((t) => t.status == TaskStatus.completed).length;
  final estimatedHours = (completedTotal * 0.75).toStringAsFixed(1);
  
  // 4. Comparison (mocked for now but based on recent completions)
  final completedLast24h = tasks.where((t) => 
    t.status == TaskStatus.completed && t.date.isAfter(now.subtract(const Duration(days: 1)))
  ).length;
  final completedPrev24h = tasks.where((t) => 
    t.status == TaskStatus.completed && 
    t.date.isBefore(now.subtract(const Duration(days: 1))) &&
    t.date.isAfter(now.subtract(const Duration(days: 2)))
  ).length;
  
  double growth = 0;
  if (completedPrev24h > 0) {
    growth = ((completedLast24h - completedPrev24h) / completedPrev24h) * 100;
  }

  return {
    'weeklyProgress': dailyCompletionData, // [count1, count2, ...]
    'categoryDistribution': categoryDistribution,
    'totalHours': estimatedHours,
    'growth': growth.toStringAsFixed(0),
  };
});

class TaskNotifier extends Notifier<List<Task>> {
  final Set<String> _deletingIds = {};

  @override
  List<Task> build() {
    final tasks = ref.watch(tasksStreamProvider).value ?? [];
    if (_deletingIds.isEmpty) return tasks;
    return tasks.where((t) => !_deletingIds.contains(t.id)).toList();
  }

  FirestoreService? get _firestore => ref.read(firestoreServiceProvider);

  int _getNotificationId(String taskId) {
    // Convert taskId string to a stable 32-bit integer for notifications
    try {
      // If it's pure numeric timestamp (most of our IDs)
      if (taskId.length >= 9) {
        return int.parse(taskId.substring(taskId.length - 9));
      }
      return int.parse(taskId);
    } catch (_) {
      // Fallback to absolute hash if parsing fails
      return taskId.hashCode.abs() % 1000000;
    }
  }

  Future<void> _scheduleReminderForTask(Task task) async {
    if (task.time != null && task.status != TaskStatus.completed) {
      final timeParts = task.time!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final scheduledDate = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        hour,
        minute,
      );
      
      if (scheduledDate.isAfter(DateTime.now())) {
        await NotificationService().scheduleTaskReminder(
          id: _getNotificationId(task.id),
          title: task.title,
          scheduledDate: scheduledDate,
        );
      }
    }
  }

  Future<void> _cancelReminderForTask(String taskId) async {
    await NotificationService().cancelReminder(_getNotificationId(taskId));
  }

  Future<void> addTask(Task task) async {
    // Optimistic Update: Add to UI immediately
    state = [...state, task];
    
    // Save to Cloud
    _firestore?.saveTask(task).ignore();
    
    // Schedule reminder
    _scheduleReminderForTask(task).ignore();
  }

  Future<void> updateTask(Task task) async {
    // Optimistic Update: Replace in UI
    state = [
      for (final t in state)
        if (t.id == task.id) task else t
    ];
    
    // Commmit to Cloud and handle notifications in background
    _cancelReminderForTask(task.id).then((_) {
      _firestore?.saveTask(task).ignore();
      _scheduleReminderForTask(task).ignore();
    });
  }

  Future<bool> toggleTask(String id) async {
    final taskIndex = state.indexWhere((t) => t.id == id);
    if (taskIndex == -1) return false;
    
    final task = state[taskIndex];
    final isCompleting = task.status != TaskStatus.completed;
    
    final updatedTask = task.copyWith(
      status: isCompleting ? TaskStatus.completed : TaskStatus.todo,
    );
    
    // Optimistic Update
    state = [
      for (final t in state)
        if (t.id == id) updatedTask else t
    ];
    
    // Cloud sync
    _firestore?.saveTask(updatedTask).ignore();
    
    if (isCompleting) {
      _cancelReminderForTask(id).ignore();
    } else {
      _scheduleReminderForTask(updatedTask).ignore();
    }
    
    return isCompleting;
  }

  Future<void> deleteTask(String id) async {
    // Prevent flicker with local tracking
    _deletingIds.add(id);
    
    // Optimistic Update
    state = state.where((t) => t.id != id).toList();
    
    // Background cleanup
    _cancelReminderForTask(id).ignore();
    try {
      await _firestore?.deleteTask(id);
    } finally {
      _deletingIds.remove(id);
    }
  }

  Future<void> deleteTasks(List<String> ids) async {
    if (ids.isEmpty) return;
    
    // Local tracking
    _deletingIds.addAll(ids);
    
    // UI Update
    state = state.where((t) => !ids.contains(t.id)).toList();
    
    try {
      // Cancel notifications
      for (final id in ids) {
        _cancelReminderForTask(id).ignore();
      }
      
      // Batch Delete
      await _firestore?.deleteTasksBatch(ids);
    } finally {
      _deletingIds.removeAll(ids);
    }
  }
}

// Habits Provider
final habitsProvider = NotifierProvider<HabitNotifier, List<Habit>>(HabitNotifier.new);

class HabitNotifier extends Notifier<List<Habit>> {
  @override
  List<Habit> build() {
    return ref.watch(habitsStreamProvider).value ?? [];
  }

  FirestoreService? get _firestore => ref.read(firestoreServiceProvider);

  Future<void> addHabit(Habit habit) async {
    state = [...state, habit];
    _firestore?.saveHabit(habit).ignore();
  }

  Future<void> toggleHabitDay(String id, DateTime date) async {
    final habitIndex = state.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;
    
    final habit = state[habitIndex];
    final isCompleted = habit.completedDates.any((d) => 
      d.year == date.year && d.month == date.month && d.day == date.day);
    
    final updatedDates = isCompleted
        ? habit.completedDates.where((d) => 
            !(d.year == date.year && d.month == date.month && d.day == date.day)).toList()
        : [...habit.completedDates, date];
    
    final updatedHabit = Habit(
      id: habit.id,
      name: habit.name,
      icon: habit.icon,
      streak: habit.streak,
      completedDates: updatedDates,
    );

    state = [for (final h in state) if (h.id == id) updatedHabit else h];
    _firestore?.saveHabit(updatedHabit).ignore();
  }

  Future<void> deleteHabit(String id) async {
    state = state.where((h) => h.id != id).toList();
    _firestore?.deleteHabit(id).ignore();
  }
}

// AI Chat Provider
final chatProvider = NotifierProvider<ChatNotifier, List<AIMessage>>(ChatNotifier.new);

// AI loading state
final aiLoadingProvider = NotifierProvider<AILoadingNotifier, bool>(AILoadingNotifier.new);

class AILoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

class ChatNotifier extends Notifier<List<AIMessage>> {
  bool _isGenerating = false;

  @override
  List<AIMessage> build() {
    // Listen to real-time updates from Firestore but only merge when not active
    // this prevents the "flicker/disappear" issue during AI generation.
    ref.listen(messagesStreamProvider, (prev, next) {
      if (!_isGenerating) {
        final newMessages = next.value ?? [];
        if (newMessages.isNotEmpty) {
           state = newMessages;
        }
      }
    });

    return ref.read(messagesStreamProvider).value ?? [];
  }

  FirestoreService? get _firestore => ref.read(firestoreServiceProvider);
  AIService get _ai => ref.read(aiServiceProvider);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isGenerating) return;
    
    _isGenerating = true;
    final userMsg = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final historyCount = state.length;
    final history = historyCount > 12 
        ? state.sublist(historyCount - 12) 
        : List<AIMessage>.from(state);

    // Update local state immediately
    state = [...state, userMsg];
    _firestore?.saveMessage(userMsg).ignore();

    // Set loading state and immediately add placeholder
    ref.read(aiLoadingProvider.notifier).set(true);
    final aiMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    const String placeholder = 'Obsidian is thinking deeper...';
    
    final initialAiMsg = AIMessage(
      id: aiMsgId,
      text: placeholder,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );
    state = [...state, initialAiMsg];

    try {
      // ... same context building as before ...
      final tasks = ref.read(tasksProvider);
      final stats = ref.read(taskStatsProvider);
      final habits = ref.read(habitsProvider);
      
      final extraContext = '''
User Stats:
- Total Tasks: ${stats['total']}
- Completed Today: ${stats['todayCompleted']}/${stats['todayTotal']}
- Pending Today: ${stats['todayPending']}
- Overdue: ${stats['overdue']}

Habits Streaks:
${habits.isEmpty ? "No habits tracking yet." : habits.map((h) => "- ${h.name}: ${h.streak} day streak").join('\n')}
''';

      final settings = ref.read(appSettingsProvider);
      final stream = _ai.getChatStream(
        text, 
        history: history,
        tasks: tasks, 
        extraContext: extraContext, 
        modelId: settings.aiModelId,
        isAutoAI: settings.isAutoAI,
      );
      
      bool hasData = false;
      await for (final result in stream) {
        hasData = true;
        state = [
          for (final m in state)
            if (m.id == aiMsgId) 
              AIMessage(
                id: m.id,
                text: result.text.isEmpty ? "Processing request..." : result.text,
                role: m.role,
                timestamp: m.timestamp,
                actions: result.actions,
                modelName: result.modelName,
              )
            else m
        ];
      }

      if (!hasData) {
         throw Exception("No response received from any AI model.");
      }

      // Save finally
      final finalMsg = state.firstWhere((m) => m.id == aiMsgId);
      _firestore?.saveMessage(finalMsg).ignore();
    } catch (e) {
      debugPrint('AI Chat Error: $e');
      
      // Update the placeholder message with error
      state = [
        for (final m in state)
          if (m.id == aiMsgId && (m.text == placeholder || m.text.contains("Processing"))) 
            AIMessage(
              id: m.id,
              text: "Could not get a response. Please check your internet connection or try a different question. ($e)",
              role: MessageRole.assistant,
              timestamp: DateTime.now(),
            )
          else m
      ];
    } finally {
      _isGenerating = false;
      ref.read(aiLoadingProvider.notifier).set(false);
    }
  }

  Future<void> executeAction(String messageId, String actionId, {Map<String, dynamic>? parametersOverride}) async {
    final msgIndex = state.indexWhere((m) => m.id == messageId);
    if (msgIndex == -1) return;

    final msg = state[msgIndex];
    if (msg.actions == null) return;

    final actionIndex = msg.actions!.indexWhere((a) => a.id == actionId);
    if (actionIndex == -1) return;

    final action = msg.actions![actionIndex];
    if (action.isExecuted) return;

    final actualParams = parametersOverride ?? action.parameters;

    // Execute based on type
    try {
      switch (action.type) {
        case AIActionType.createTask:
          final p = actualParams;
          final newTask = Task(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: p['title']?.toString() ?? 'New Task',
            date: DateTime.tryParse(p['date']?.toString() ?? '') ?? DateTime.now(),
            time: p['time']?.toString(),
            priority: TaskPriority.values[(p['priority'] as int? ?? 1).clamp(0, 2)],
            category: p['category']?.toString() ?? 'Inbox',
          );
          await ref.read(tasksProvider.notifier).addTask(newTask);
          break;
        case AIActionType.updateTask:
          final p = actualParams;
          final taskId = p['id']?.toString();
          if (taskId != null) {
            final tasks = ref.read(tasksProvider);
            final taskIndex = tasks.indexWhere((t) => t.id == taskId);
            if (taskIndex != -1) {
              final task = tasks[taskIndex];
              final updatedTask = task.copyWith(
                title: p['title']?.toString(),
                status: p['status'] == 'completed' ? TaskStatus.completed : 
                        (p['status'] == 'inProgress' ? TaskStatus.inProgress : TaskStatus.todo),
                priority: p['priority'] != null ? TaskPriority.values[(p['priority'] as int).clamp(0, 2)] : null,
                category: p['category']?.toString(),
              );
              await ref.read(tasksProvider.notifier).updateTask(updatedTask);
            }
          }
          break;
        case AIActionType.completeTask:
          final taskId = actualParams['id']?.toString();
          if (taskId != null) {
            await ref.read(tasksProvider.notifier).toggleTask(taskId);
          }
          break;
        case AIActionType.deleteTasks:
          final ids = (actualParams['ids'] as List?)?.map((e) => e.toString()).toList();
          if (ids != null) {
            await ref.read(tasksProvider.notifier).deleteTasks(ids);
          }
          break;
        case AIActionType.suggestion:
          // For suggestions, "executing" means picking the option.
          // We'll send a message back to the AI with the picked value.
          final label = actualParams['label']?.toString() ?? 'Selected';
          final value = actualParams['value']?.toString() ?? label;
          // Send a message "from the user" in response to this choice
          sendMessage("[Chosen: $label] $value").ignore();
          break;
        case AIActionType.rescheduleAll:
          final newDateStr = actualParams['newDate']?.toString();
          if (newDateStr != null) {
            final newDate = DateTime.tryParse(newDateStr) ?? DateTime.now();
            final overdue = ref.read(overdueTasksProvider);
            // Use batch update logic if available, or looped update
            for (final t in overdue) {
              final updated = t.copyWith(date: newDate);
              await ref.read(tasksProvider.notifier).updateTask(updated);
            }
          }
          break;
        default:
          break;
      }

      // Mark as executed in UI state
      final updatedAction = AIAction(
        id: action.id,
        type: action.type,
        parameters: action.parameters,
        isExecuted: true,
      );

      final updatedActions = List<AIAction>.from(msg.actions!);
      updatedActions[actionIndex] = updatedAction;

      final updatedMsg = AIMessage(
        id: msg.id,
        text: msg.text,
        role: msg.role,
        timestamp: msg.timestamp,
        actions: updatedActions,
      );

      state = [
        for (final m in state)
          if (m.id == messageId) updatedMsg else m
      ];
      _firestore?.saveMessage(updatedMsg).ignore();
    } catch (e) {
      debugPrint('Action Execution Failed: $e');
    }
  }

  Future<void> rejectAction(String messageId, String actionId) async {
    final msgIndex = state.indexWhere((m) => m.id == messageId);
    if (msgIndex == -1) return;

    final msg = state[msgIndex];
    if (msg.actions == null) return;

    final actionIndex = msg.actions!.indexWhere((a) => a.id == actionId);
    if (actionIndex == -1) return;

    final action = msg.actions![actionIndex];
    
    final updatedAction = AIAction(
      id: action.id,
      type: action.type,
      parameters: action.parameters,
      isRejected: true,
    );

    final updatedActions = List<AIAction>.from(msg.actions!);
    updatedActions[actionIndex] = updatedAction;

    final updatedMsg = AIMessage(
      id: msg.id,
      text: msg.text,
      role: msg.role,
      timestamp: msg.timestamp,
      actions: updatedActions,
    );

    state = [
      for (final m in state)
        if (m.id == messageId) updatedMsg else m
    ];
    _firestore?.saveMessage(updatedMsg).ignore();
  }

  Future<void> clearChat() async {
    _firestore?.clearChatHistory().ignore();
    state = [];
  }
}
