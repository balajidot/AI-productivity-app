import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tasks/domain/task.dart';
import '../domain/message_model.dart';
import '../domain/ai_action_model.dart';
import '../data/ai_service.dart';
import '../../../core/constants/constants.dart';
import '../../../core/constants/secrets.dart';
import '../../tasks/presentation/task_provider.dart';
import '../../habits/presentation/habit_provider.dart';
import '../../habits/domain/habit.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../../core/utils/app_utils.dart';
import './feedback_provider.dart';
import '../../auth/presentation/auth_provider.dart';



final aiServiceProvider = Provider((ref) {
  return AIService(
    geminiApiKey: Secrets.geminiApiKey,
    nvidiaApiKey: Secrets.nvidiaApiKey,
    groqApiKey: Secrets.groqApiKey,
  );
});

final messagesStreamProvider = StreamProvider<List<AIMessage>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  if (firestore == null) return Stream.value([]);
  return firestore.getMessages();
});

class AILoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final aiLoadingProvider = NotifierProvider<AILoadingNotifier, bool>(
  AILoadingNotifier.new,
);

final chatProvider = NotifierProvider<ChatNotifier, List<AIMessage>>(
  ChatNotifier.new,
);

class ChatNotifier extends Notifier<List<AIMessage>> {
  bool _isGenerating = false;

  @override
  List<AIMessage> build() {
    final streamMessagesAsync = ref.watch(messagesStreamProvider);
    final streamMessages = streamMessagesAsync.when<List<AIMessage>>(
      data: (messages) => messages,
      loading: () => const <AIMessage>[],
      error: (_, stackTrace) => const <AIMessage>[],
    );
    return _isGenerating ? state : streamMessages;
  }

  AIService get _ai => ref.read(aiServiceProvider);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isGenerating) return;

    _isGenerating = true;
    final userMsg = AIMessage(
      id: AppUtils.generateId(prefix: 'msg'),
      text: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final history = state.length > 30
        ? state.sublist(state.length - 30)
        : List<AIMessage>.from(state);
    state = [...state, userMsg];
    ref.read(firestoreServiceProvider)?.saveMessage(userMsg).ignore();

    ref.read(aiLoadingProvider.notifier).set(true);
    final aiMsgId = AppUtils.generateId(prefix: 'ai');
    const String placeholder = 'Zeno is thinking...';

    state = [
      ...state,
      AIMessage(
        id: aiMsgId,
        text: placeholder,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    ];

    try {
      final tasks = ref.read(tasksProvider);
      final habits = ref.read(habitsProvider);
      final settings = ref.read(appSettingsProvider);

      final overdue = ref.read(overdueTasksProvider);
      final extraContext =
          'Tasks: ${tasks.tasks.length} total, ${overdue.length} overdue. '
          'Habits: ${habits.length} tracking, '
          '${habits.where((h) => h.completedToday).length} completed today.';

      final userName = ref.read(userNameProvider);
      final personalizedPrompt = AppConstants.executiveAssistantPrompt
          .replaceAll('{USER_NAME}', userName);

      final stream = _ai.getChatStream(
        text,
        history: history,
        tasks: tasks.tasks,
        extraContext: extraContext,
        modelId: settings.aiModelId,
        systemPrompt: '$personalizedPrompt\nTone: ${settings.aiTone}',
      );

      String accumulatedText = '';
      List<AIAction>? accumulatedActions;
      final stopwatch = Stopwatch()..start();

      await for (final result in stream) {
        if (result.actions != null) accumulatedActions = result.actions;
        accumulatedText = result.text;

        if (stopwatch.elapsedMilliseconds > 100 ||
            accumulatedText.length % 30 == 0) {
          _updateAiMessage(
            aiMsgId,
            accumulatedText,
            accumulatedActions,
            result.modelName,
          );
          stopwatch.reset();
        }
      }
      _updateAiMessage(aiMsgId, accumulatedText, accumulatedActions);
      final aiMessage = state.where((m) => m.id == aiMsgId).isNotEmpty
          ? state.firstWhere((m) => m.id == aiMsgId)
          : null;
      if (aiMessage != null) {
        ref.read(firestoreServiceProvider)?.saveMessage(aiMessage).ignore();
      }
    } catch (e) {
      final friendly = e.toString().contains('SocketException') || e.toString().contains('network')
          ? "No internet connection. Please check your network and try again."
          : "Something went wrong. Please try again in a moment.";
      _updateAiMessage(aiMsgId, friendly, null);
    } finally {
      _isGenerating = false;
      ref.read(aiLoadingProvider.notifier).set(false);
    }
  }

  void _updateAiMessage(
    String id,
    String text,
    List<AIAction>? actions, [
    String? model,
  ]) {
    state = [
      for (final m in state)
        if (m.id == id)
          m.copyWith(
            text: text.isEmpty ? "Generating..." : text,
            actions: actions,
            modelName: model,
          )
        else
          m,
    ];
  }

  Future<void> executeSyntheticAction(AIAction action) async {
    try {
      await _runActionLogic(action, action.parameters);
    } catch (e) {
      ref.read(feedbackProvider.notifier).showError('Action failed. Please try again.');
    }
  }

  Future<void> executeAction(
    String messageId,
    String actionId, {
    Map<String, dynamic>? parametersOverride,
  }) async {
    final msgIndex = state.indexWhere((m) => m.id == messageId);
    if (msgIndex == -1) return;

    final msg = state[msgIndex];
    final actions = msg.actions;
    if (actions == null || actions.isEmpty) return;

    final actionIndex = actions.indexWhere((a) => a.id == actionId);
    if (actionIndex == -1) return;

    final action = actions[actionIndex];
    if (action.isExecuted) return;

    try {
      final p = {...action.parameters, ...?parametersOverride};
      await _runActionLogic(action, p, messageId: messageId);
      _markActionExecuted(messageId, actionId);
    } catch (e) {
      ref.read(feedbackProvider.notifier).showError('Action failed. Please try again.');
    }
  }

  Future<void> _runActionLogic(AIAction action, Map<String, dynamic> p, {String? messageId}) async {
    switch (action.type) {
      case AIActionType.createTask:
        await ref
            .read(tasksProvider.notifier)
            .addTask(_buildTaskFromParams(p));
        break;
      case AIActionType.createBulkTasks:
        final rawTasks = p['tasks'];
        if (rawTasks is List) {
          for (final rawTask in rawTasks) {
            if (rawTask is Map) {
              final normalized = Map<String, dynamic>.from(rawTask);
              await ref
                  .read(tasksProvider.notifier)
                  .addTask(_buildTaskFromParams(normalized));
            }
          }
        }
        break;
      case AIActionType.completeTask:
        await ref.read(tasksProvider.notifier).toggleTask(p['id']);
        break;
      case AIActionType.deleteTasks:
        final ids = (p['ids'] as List?)?.map((e) => e.toString()).toList();
        if (ids != null) {
          await ref.read(tasksProvider.notifier).deleteTasks(ids);
        }
        break;
      case AIActionType.updateTask:
        final taskId = p['id']?.toString();
        if (taskId != null) {
          final tasks2 = ref.read(tasksProvider);
          final taskIndex = tasks2.tasks.indexWhere((t) => t.id == taskId);
          if (taskIndex != -1) {
            final existing = tasks2.tasks[taskIndex];
            final rawPriority = p['priority'];
            final priorityIndex = rawPriority is int
                ? rawPriority
                : int.tryParse(rawPriority?.toString() ?? '');
            await ref.read(tasksProvider.notifier).updateTask(
              existing.copyWith(
                title: p['title']?.toString() ?? existing.title,
                category: p['category']?.toString() ?? existing.category,
                priority: priorityIndex != null
                    ? TaskPriority.values[priorityIndex.clamp(0, 2)]
                    : existing.priority,
                date: p['date'] != null
                    ? DateTime.tryParse(p['date'].toString()) ?? existing.date
                    : existing.date,
                time: p['time']?.toString() ?? existing.time,
              ),
            );
          }
        }
        break;
      case AIActionType.deleteTask:
        final id = p['id']?.toString();
        if (id != null) {
          await ref.read(tasksProvider.notifier).deleteTask(id);
        }
        break;
      case AIActionType.setHabit:
        await ref.read(habitsProvider.notifier).addHabit(
          Habit(
            id: AppUtils.generateId(prefix: 'habit'),
            name: p['name']?.toString() ?? 'New Habit',
            icon: p['icon']?.toString() ?? 'star',
          ),
        );
        break;
      case AIActionType.updateHabit:
        final habitId = p['id']?.toString();
        if (habitId != null) {
          final toggle = p['toggle'] as bool? ?? false;
          if (toggle) {
            await ref
                .read(habitsProvider.notifier)
                .toggleHabitDay(habitId, DateTime.now());
          } else {
            await ref.read(habitsProvider.notifier).updateHabit(
              habitId,
              name: p['name']?.toString(),
              icon: p['icon']?.toString(),
            );
          }
        }
        break;
      case AIActionType.rescheduleAll:
        final overdueTasks = ref.read(overdueTasksProvider);
        final now = DateTime.now();
        for (final t in overdueTasks) {
          await ref
              .read(tasksProvider.notifier)
              .updateTask(t.copyWith(date: now));
        }
        break;
      case AIActionType.multiAction:
        final subActions = p['actions'];
        if (subActions is List) {
          for (final sub in subActions) {
            if (sub is Map) {
              final subMap = Map<String, dynamic>.from(sub);
              final subTypeIndex = subMap['type'] as int? ?? -1;
              if (subTypeIndex >= 0 &&
                  subTypeIndex < AIActionType.values.length) {
                final subAction = AIAction(
                  id: AppUtils.generateId(prefix: 'sub'),
                  type: AIActionType.values[subTypeIndex],
                  parameters: Map<String, dynamic>.from(
                    subMap['parameters'] ?? {},
                  ),
                );
                // Temporarily inject into state and execute
                if (messageId != null) {
                  final tempMsgId = messageId;
                  final tempActionId = subAction.id;
                  final tempMsg = state.firstWhere(
                    (m) => m.id == tempMsgId,
                    orElse: () => state.first,
                  );
                  final updatedActions = [
                    ...?tempMsg.actions,
                    subAction,
                  ];
                  state = [
                    for (final m in state)
                      if (m.id == tempMsgId)
                        m.copyWith(actions: updatedActions)
                      else
                        m,
                  ];
                  await executeAction(tempMsgId, tempActionId);
                } else {
                  await executeSyntheticAction(subAction);
                }
              }
            }
          }
        }
        break;
      case AIActionType.suggestion:
        // FIX H2: await sendMessage to avoid race with _markActionExecuted
        await sendMessage("[Chosen: ${p['label']}] ${p['value']}");
        break;
      case AIActionType.deleteRecord:
      case AIActionType.generateVisual:
        // Not implemented — silently mark as executed
        break;
    }

  }

  Future<void> rejectAction(String messageId, String actionId) async {
    final msgIndex = state.indexWhere((m) => m.id == messageId);
    if (msgIndex == -1) return;
    final actions = state[msgIndex].actions;
    if (actions == null || actions.isEmpty) return;
    _markActionStatus(messageId, actionId, isRejected: true);
  }

  void _markActionExecuted(String msgId, String actionId) {
    _markActionStatus(msgId, actionId, isExecuted: true);
  }

  void _markActionStatus(
    String msgId,
    String actionId, {
    bool isExecuted = false,
    bool isRejected = false,
  }) {
    state = [
      for (final m in state)
        if (m.id == msgId && m.actions != null && m.actions!.isNotEmpty)
          m.copyWith(
            actions: [
              for (final a in m.actions!)
                if (a.id == actionId)
                  a.copyWith(isExecuted: isExecuted, isRejected: isRejected)
                else
                  a,
            ],
          )
        else
          m,
    ];
    final updatedMsg = state.where((m) => m.id == msgId).isNotEmpty
        ? state.firstWhere((m) => m.id == msgId)
        : null;
    if (updatedMsg != null) {
      ref.read(firestoreServiceProvider)?.saveMessage(updatedMsg).ignore();
    }
  }

  Task _buildTaskFromParams(Map<String, dynamic> params) {
    final rawPriority = params['priority'];
    final priorityIndex = rawPriority is int
        ? rawPriority
        : int.tryParse(rawPriority?.toString() ?? '') ?? 1;

    return Task(
      id: AppUtils.generateId(prefix: 'task'),
      title: params['title']?.toString() ?? 'New Task',
      date:
          DateTime.tryParse(params['date']?.toString() ?? '') ?? DateTime.now(),
      time: params['time']?.toString(),
      priority: TaskPriority.values[priorityIndex.clamp(0, 2)],
      category: params['category']?.toString() ?? 'Inbox',
    );
  }

  Future<void> clearChat() async {
    // FIX C4: Optimistically clear UI first, then sync to Firestore
    state = [];
    await ref.read(firestoreServiceProvider)?.clearChatHistory();
  }
}
