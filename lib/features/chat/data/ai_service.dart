import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import '../../../features/tasks/domain/task.dart';
import '../domain/ai_action_model.dart';
import '../domain/message_model.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';

class ChatResult {
  final String text;
  final List<AIAction>? actions;
  final String? modelName;

  ChatResult({required this.text, this.actions, this.modelName});
}

class AIService {
  final String? geminiApiKey;
  final String? nvidiaApiKey;
  final String? groqApiKey;

  // Cache for static results (prompt -> Task or ChatResult)
  final Map<String, dynamic> _cache = {};
  // Track active futures to deduplicate parallel identical requests
  final Map<String, Future<dynamic>> _activeRequests = {};

  void _addToCache(String key, dynamic value) {
    if (_cache.length >= 50) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  AIService({this.geminiApiKey, this.nvidiaApiKey, this.groqApiKey});

  String get _systemPrompt => AppConstants.executiveAssistantPrompt;

  // --- Resilience Helper ---
  Future<T> _withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation().timeout(const Duration(seconds: 30));
      } catch (e) {
        if (attempts >= maxAttempts) rethrow;
        // Exponential backoff: 2s, 4s, 8s
        await Future.delayed(Duration(seconds: (1 << attempts)));
      }
    }
  }

  final List<Tool> _tools = [
    Tool(
      functionDeclarations: [
        FunctionDeclaration(
          'create_task',
          'Creates a single productivity task.',
          Schema.object(
            properties: {
              'title': Schema.string(
                description: 'The description of the task',
              ),
              'date': Schema.string(description: 'Date in YYYY-MM-DD format'),
              'time': Schema.string(
                description: 'Time in HH:mm format (optional)',
              ),
              'priority': Schema.integer(
                description: '0: Low, 1: Medium, 2: High',
              ),
              'category': Schema.string(
                description: 'Work, Personal, Health, Study, Finance, or Inbox',
              ),
            },
            requiredProperties: ['title', 'date', 'priority', 'category'],
          ),
        ),
        FunctionDeclaration(
          'create_bulk_tasks',
          'Splits a main objective into multiple sub-tasks and adds them in bulk.',
          Schema.object(
            properties: {
              'tasks': Schema.array(
                items: Schema.object(
                  properties: {
                    'title': Schema.string(description: 'Sub-task title'),
                    'date': Schema.string(
                      description: 'Date in YYYY-MM-DD format',
                    ),
                    'priority': Schema.integer(description: '0, 1, or 2'),
                    'category': Schema.string(
                      description: 'The category for this sub-task',
                    ),
                  },
                  requiredProperties: ['title', 'date', 'priority', 'category'],
                ),
              ),
            },
            requiredProperties: ['tasks'],
          ),
        ),
        FunctionDeclaration(
          'complete_task',
          'Marks a specific task as completed.',
          Schema.object(
            properties: {
              'id': Schema.string(
                description: 'The unique ID of the task to complete',
              ),
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'delete_tasks',
          'Deletes multiple tasks at once.',
          Schema.object(
            properties: {
              'ids': Schema.array(
                items: Schema.string(description: 'A list of task IDs'),
              ),
            },
            requiredProperties: ['ids'],
          ),
        ),
        FunctionDeclaration(
          'suggest_options',
          'Shows interactive buttons/choices to the user.',
          Schema.object(
            properties: {
              'prompt': Schema.string(
                description: 'The question to ask the user',
              ),
              'options': Schema.array(
                items: Schema.object(
                  properties: {
                    'label': Schema.string(description: 'Button text'),
                    'value': Schema.string(description: 'The internal command'),
                  },
                  requiredProperties: ['label', 'value'],
                ),
              ),
            },
            requiredProperties: ['prompt', 'options'],
          ),
        ),
      ],
    ),
  ];

  GenerativeModel _getGeminiModel(String modelId, {String? systemPrompt}) {
    if (geminiApiKey == null || geminiApiKey!.isEmpty) {
      throw Exception('Missing Gemini API Key.');
    }
    return GenerativeModel(
      model: modelId,
      apiKey: geminiApiKey!,
      systemInstruction: Content.text(systemPrompt ?? _systemPrompt),
      tools: _tools,
    );
  }

  Future<String> _detectComplexity(String prompt) async {
    try {
      final model = _getGeminiModel(
        AppConstants.geminiFlashModel,
        systemPrompt: AppConstants.routerPrompt,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.toUpperCase().trim() ?? 'CHAT';
      if (text.contains('REASONING')) return 'REASONING';
      if (text.contains('ACTION')) return 'ACTION';
      return 'CHAT';
    } catch (_) {
      return 'CHAT';
    }
  }

  Stream<ChatResult> getChatStream(
    String prompt, {
    List<AIMessage>? history,
    List<Task>? tasks,
    String? extraContext,
    String? modelId,
    String? systemPrompt,
  }) async* {
    String effectiveModelId = modelId ?? AppConstants.geminiFlashModel;
    String? assignedModelName;

    if (effectiveModelId == AppConstants.autoModelId) {
      final complexity = await _detectComplexity(prompt);
      if (complexity == 'REASONING') {
        effectiveModelId = AppConstants.geminiModel;
        assignedModelName = 'Zeno Pro (Strategic)';
      } else {
        effectiveModelId = AppConstants.geminiFlashModel;
        assignedModelName = (complexity == 'ACTION')
            ? 'Zeno Flash (Action Mode)'
            : 'Zeno Flash (Chat Mode)';
      }
    }

    final historyString = history == null
        ? ''
        : history.map((m) => '${m.role}:${m.text}').join('|');
    final cacheKey =
        'chat_${prompt}_${effectiveModelId}_${historyString.hashCode}';

    // Check Cache first
    if (_cache.containsKey(cacheKey)) {
      yield _cache[cacheKey] as ChatResult;
      return;
    }

    try {
      final contextString = _buildContextSummary(tasks, extraContext);
      final content = _prepareContent(
        prompt,
        history: history,
        contextString: contextString,
      );
      final model = _getGeminiModel(
        effectiveModelId,
        systemPrompt: systemPrompt,
      );

      String accumulatedText = '';
      List<AIAction>? finalActions;

      final responseStream = model.generateContentStream(content);

      await for (final response in responseStream) {
        if (response.candidates.isEmpty) continue;

        final candidate = response.candidates.first;
        final parts = candidate.content.parts;

        final textPart = parts
            .whereType<TextPart>()
            .map((p) => p.text)
            .join('');
        if (textPart.isNotEmpty) accumulatedText += textPart;

        final functionCalls = parts.whereType<FunctionCall>().toList();
        if (functionCalls.isNotEmpty) {
          finalActions = functionCalls
              .map(
                (call) => AIAction(
                  id: AppUtils.generateId(prefix: 'action'),
                  type: _mapActionToType(call.name),
                  parameters: call.args,
                ),
              )
              .toList();
        }

        final result = ChatResult(
          text: accumulatedText,
          actions: finalActions,
          modelName: assignedModelName ?? _getFriendlyName(effectiveModelId),
        );

        // Cache final result if complete
        if (candidate.finishReason == FinishReason.stop) {
          _addToCache(cacheKey, result);
        }

        yield result;
      }
    } catch (e) {
      debugPrint('Chat Stream Error: $e');
      final errorMsg = e.toString().contains('SocketException') || 
                       e.toString().contains('network') ||
                       e.toString().contains('HttpException')
          ? "No internet connection. Please check your network."
          : "Something went wrong. Please try again.";
      yield ChatResult(text: errorMsg);
    }
  }

  String _buildContextSummary(List<Task>? tasks, String? extraContext) {
    if ((tasks == null || tasks.isEmpty) &&
        (extraContext == null || extraContext.isEmpty)) {
      return '';
    }

    String context = '### CONTEXT SUMMARY ###\n';
    if (extraContext != null) {
      context += '$extraContext\n';
    }

    if (tasks != null && tasks.isNotEmpty) {
      final pending = tasks
          .where((t) => t.status != TaskStatus.completed)
          .toList();
      context += 'Pending Tasks (${pending.length}):\n';
      context += pending
          .take(15)
          .map((t) => '- [${t.priority.name}] ${t.title} (ID: ${t.id})')
          .join('\n');
    }
    return context;
  }

  List<Content> _prepareContent(
    String prompt, {
    List<AIMessage>? history,
    String? contextString,
  }) {
    final contents = <Content>[];
    if (contextString != null && contextString.isNotEmpty) {
      contents.add(Content.text("SYSTEM_CONTEXT:\n$contextString"));
    }
    if (history != null) {
      contents.addAll(
        history.map((m) {
          if (m.role == MessageRole.user) return Content.text(m.text);
          return Content.model([TextPart(m.text)]);
        }),
      );
    }
    contents.add(Content.text(prompt));
    return contents;
  }

  AIActionType _mapActionToType(String name) {
    switch (name) {
      case 'create_task':
        return AIActionType.createTask;
      case 'create_bulk_tasks':
        return AIActionType.createBulkTasks;
      case 'complete_task':
        return AIActionType.completeTask;
      case 'delete_tasks':
        return AIActionType.deleteTasks;
      case 'suggest_options':
        return AIActionType.suggestion;
      default:
        return AIActionType.createTask;
    }
  }

  String _getFriendlyName(String modelId) {
    if (modelId.contains('pro')) return 'Zeno Pro';
    return 'Zeno Flash';
  }

  Future<Task?> parseTaskFromNaturalLanguage(String text) async {
    final cacheKey = 'parse_${text.toLowerCase().trim()}';

    // 1. Check Cache
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as Task?;
    }

    // 2. Deduplicate: Return existing future if same request is in progress
    if (_activeRequests.containsKey(cacheKey)) {
      return await _activeRequests[cacheKey] as Task?;
    }

    final future = _withRetry(() async {
      try {
        final now = DateTime.now();
        final currentDateStr = now.toString().split(' ')[0];
        final prompt =
            '${AppConstants.taskParsingPrompt.replaceAll('{CURRENT_DATE}', currentDateStr)}\nINPUT: "$text"';

        final model = _getGeminiModel(AppConstants.geminiFlashModel);
        final response = await model.generateContent([Content.text(prompt)]);

        final jsonStr = AppUtils.extractJson(response.text ?? '');
        final data = jsonDecode(jsonStr);

        final task = Task(
          id: AppUtils.generateId(prefix: 'task'),
          title: data['title'] ?? text,
          date: DateTime.tryParse(data['date'] ?? '') ?? now,
          time: data['time']?.toString(),
          priority:
              TaskPriority.values[(data['priority'] as int? ?? 1).clamp(0, 2)],
          category: data['category'] ?? 'Inbox',
        );

        _addToCache(cacheKey, task);
        return task;
      } catch (e) {
        debugPrint('AI Task Parsing Error: $e');
        return Task(
          id: AppUtils.generateId(prefix: 'task'),
          title: text,
          date: DateTime.now(),
          priority: TaskPriority.medium,
          category: 'Inbox',
        );
      }
    });

    _activeRequests[cacheKey] = future;
    try {
      return await future;
    } finally {
      _activeRequests.remove(cacheKey);
    }
  }

  Future<String> generateProductivitySummary(Map<String, dynamic> metrics) async {
    final cacheKey = 'summary_${metrics.hashCode}';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as String;
    }

    if (_activeRequests.containsKey(cacheKey)) {
      return await _activeRequests[cacheKey] as String;
    }

    final future = _withRetry(() async {
      try {
        final prompt = '''
You are Zeno Alpha, an elite productivity companion. Provide a concise, highly motivating 2-sentence summary based on this week's metrics.
Metrics:
- Total Focus Hours: ${metrics['totalHours'] ?? 0}
- Efficiency Growth (compared to last week): ${metrics['growth'] ?? 0}%
- Category Distribution: ${jsonEncode(metrics['categoryDistribution'] ?? {})}

Rules:
1. Two sentences maximum.
2. If total hours is 0, softly push them to start engaging.
3. Call out their dominant category playfully or point out high efficiency growth.
4. Keep the tone sharp, professional, and slightly futuristic. No emojis.
''';
        final model = _getGeminiModel(AppConstants.geminiFlashModel);
        final response = await model.generateContent([Content.text(prompt)]);
        
        final result = response.text?.trim() ?? "Productivity patterns look stable. Keep executing.";
        _addToCache(cacheKey, result);
        return result;
      } catch (e) {
        debugPrint('AI Summary Error: $e');
        return "Deep focus analysis requires more data. Start completing tasks to generate intelligence.";
      }
    });

    _activeRequests[cacheKey] = future;
    try {
      return await future;
    } finally {
      _activeRequests.remove(cacheKey);
    }
  }

  Future<Map<String, dynamic>> decomposeGoal(String goal, String timeframe) async {
    final prompt = """
Decompose this goal into a structured project plan:
Goal: $goal
Timeframe: $timeframe

Generate a JSON response exactly like this:
{
  "milestones": ["Milestone 1", "Milestone 2"],
  "tasks": [
    {"title": "Subtask 1", "category": "Work", "priority": 2},
    {"title": "Subtask 2", "category": "Work", "priority": 1}
  ]
}
Rules:
1. Max 3 milestones and 6 tasks.
2. Priority: 0:Low, 1:Medium, 2:High.
3. Keep it professional and high-performance.
Return ONLY JSON.
""";

    return await _withRetry(() async {
      try {
        final model = _getGeminiModel(AppConstants.geminiFlashModel);
        final response = await model.generateContent([Content.text(prompt)]);
        return jsonDecode(AppUtils.extractJson(response.text ?? '{}'));
      } catch (e) {
        debugPrint('Decompose Goal Error: $e');
        return {"milestones": [], "tasks": []};
      }
    });
  }
}

