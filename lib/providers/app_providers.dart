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

// Today's Tasks
final todayTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(filteredTasksProvider);
  return tasks.where((t) => t.isToday).toList();
});

// Tomorrow's Tasks
final tomorrowTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(filteredTasksProvider);
  return tasks.where((t) => t.isTomorrow).toList();
});

// Overdue Tasks
final overdueTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(filteredTasksProvider);
  return tasks.where((t) => t.isOverdue).toList();
});

// Upcoming Tasks
final upcomingTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(filteredTasksProvider);
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

  Future<void> addTask(Task task) async {
    await _storage.insertTask(task);
    await loadTasks();
    
    if (task.time != null) {
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
      
      await NotificationService().scheduleTaskReminder(
        id: task.id.hashCode,
        title: task.title,
        scheduledDate: scheduledDate,
      );
    }
  }

  Future<void> updateTask(Task task) async {
    await _storage.updateTask(task);
    await loadTasks();
  }

  Future<bool> toggleTask(String id) async {
    final task = state.firstWhere((t) => t.id == id);
    final isCompleting = task.status != TaskStatus.completed;
    
    final updatedTask = task.copyWith(
      status: isCompleting ? TaskStatus.completed : TaskStatus.todo,
    );
    await _storage.insertTask(updatedTask);
    await loadTasks();
    
    if (isCompleting) {
      await NotificationService().cancelReminder(task.id.hashCode);
    } else if (updatedTask.time != null) {
      // Reschedule if un-completing and it has a time
      final timeParts = updatedTask.time!.split(':');
      final scheduledDate = DateTime(
        updatedTask.date.year,
        updatedTask.date.month,
        updatedTask.date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      if (scheduledDate.isAfter(DateTime.now())) {
        await NotificationService().scheduleTaskReminder(
          id: updatedTask.id.hashCode,
          title: updatedTask.title,
          scheduledDate: scheduledDate,
        );
      }
    }
    
    return isCompleting; // true if task was just completed
  }

  Future<void> deleteTask(String id) async {
    await _storage.deleteTask(id);
    await loadTasks();
    await NotificationService().cancelReminder(id.hashCode);
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
