import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../models/message_model.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/notification_service.dart';
import '../services/user_preferences.dart';
import '../config/secrets.dart';

// Services
final storageServiceProvider = Provider((ref) => StorageService());
final aiServiceProvider = Provider((ref) => AIService(
  geminiApiKey: Secrets.geminiApiKey,
  nvidiaApiKey: Secrets.nvidiaApiKey,
));

// User Name Provider
final userNameProvider = FutureProvider<String>((ref) async {
  return await UserPreferences.getUserName();
});

// Category Filter
final selectedCategoryProvider = NotifierProvider<CategoryFilterNotifier, String>(CategoryFilterNotifier.new);

class CategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void set(String category) => state = category;
}

// Tasks Provider
final tasksProvider = NotifierProvider<TaskNotifier, List<Task>>(TaskNotifier.new);

// Filtered Tasks Provider
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final category = ref.watch(selectedCategoryProvider);

  if (category == 'All') return tasks;
  return tasks.where((t) => t.category == category).toList();
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
  late final StorageService _storage;

  @override
  List<Task> build() {
    _storage = ref.watch(storageServiceProvider);
    loadTasks();
    return [];
  }

  Future<void> loadTasks() async {
    state = await _storage.getTasks();
  }

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
    
    // Save to DB in background
    _storage.insertTask(task).ignore();
    
    // Schedule reminder
    _scheduleReminderForTask(task).ignore();
  }

  Future<void> updateTask(Task task) async {
    // Optimistic Update: Replace in UI
    state = [
      for (final t in state)
        if (t.id == task.id) task else t
    ];
    
    // Commmit to DB and handle notifications in background
    _cancelReminderForTask(task.id).then((_) {
      _storage.updateTask(task).ignore();
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
    
    // Background sync
    _storage.updateTask(updatedTask).ignore();
    
    if (isCompleting) {
      _cancelReminderForTask(id).ignore();
    } else {
      _scheduleReminderForTask(updatedTask).ignore();
    }
    
    return isCompleting;
  }

  Future<void> deleteTask(String id) async {
    // Optimistic Update
    state = state.where((t) => t.id != id).toList();
    
    // Background cleanup
    _cancelReminderForTask(id).ignore();
    _storage.deleteTask(id).ignore();
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
  late final AIService _ai;
  late final StorageService _storage;

  @override
  List<AIMessage> build() {
    _ai = ref.watch(aiServiceProvider);
    _storage = ref.watch(storageServiceProvider);
    loadMessages();
    return [];
  }

  Future<void> loadMessages() async {
    state = await _storage.getMessages();
  }

  Future<void> sendMessage(String text) async {
    final userMsg = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    
    state = [...state, userMsg];
    await _storage.insertMessage(userMsg);

    // Set loading state
    ref.read(aiLoadingProvider.notifier).set(true);

    try {
      // Get tasks for context
      final tasks = ref.read(tasksProvider);
      final response = await _ai.getChatResponse(text, tasks: tasks);
      
      final aiMsg = AIMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: response,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      state = [...state, aiMsg];
      await _storage.insertMessage(aiMsg);
    } catch (e) {
      final errorMsg = AIMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: "Sorry, couldn't connect to AI. Please try again.",
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      state = [...state, errorMsg];
      await _storage.insertMessage(errorMsg);
    } finally {
      ref.read(aiLoadingProvider.notifier).set(false);
    }
  }

  Future<void> clearChat() async {
    state = [];
  }
}
