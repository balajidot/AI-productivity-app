import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/ai_action_model.dart';
import '../models/message_model.dart';

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

  AIService({this.geminiApiKey, this.nvidiaApiKey, this.groqApiKey});
  String get _systemPrompt => '''
You are Obsidian AI, a highly efficient, decisive, and professional executive assistant.
Your goal is to manage the user's productivity with extreme precision.

CORE PRINCIPLES:
1. DO NOT HESITATE. If a user's intent is clear (e.g., "delete overdue"), emit the tool call IMMEDIATELY.
2. ACTION PERSISTENCE: If you previously suggested an action (visible in history as [ACTION_PROPOSED]) and the user says "confirm" or similar, YOU MUST EMIT THE EXACT SAME TOOL CALL AGAIN.
3. NEVER write "Tool Call: ..." as text. Instead, emit the official function call schema.
4. If you say "I have deleted...", you MUST have included a tool call in that SAME response.
5. Keep responses concise. Use Tamil, English, or Tanglish naturally.
''';

  final List<Tool> _tools = [
     Tool(functionDeclarations: [
       FunctionDeclaration(
         'create_task',
         'Creates a new productivity task for Balaji.',
         Schema.object(properties: {
           'title': Schema.string(description: 'The description of the task'),
           'date': Schema.string(description: 'Date in YYYY-MM-DD format'),
           'time': Schema.string(description: 'Time in HH:mm format (optional)'),
           'priority': Schema.integer(description: '0: Low, 1: Medium, 2: High'),
           'category': Schema.string(description: 'Work, Personal, Health, Study, Finance, or Inbox'),
         }, requiredProperties: ['title', 'date', 'priority', 'category']),
       ),
       FunctionDeclaration(
         'complete_task',
         'Marks a specific task as completed.',
         Schema.object(properties: {
           'id': Schema.string(description: 'The unique ID of the task to complete'),
         }, requiredProperties: ['id']),
       ),
       FunctionDeclaration(
         'delete_task',
         'Deletes a task from Balaji\'s list permanently.',
         Schema.object(properties: {
           'id': Schema.string(description: 'The unique ID of the task to delete'),
         }, requiredProperties: ['id']),
       ),
       FunctionDeclaration(
         'delete_tasks',
         'Deletes multiple tasks at once. Use for bulk cleanup.',
         Schema.object(properties: {
           'ids': Schema.array(items: Schema.string(description: 'A single task ID strings')),
         }, requiredProperties: ['ids']),
       ),
       FunctionDeclaration(
         'suggest_options',
         'Shows interactive buttons/choices to the user to clarify their intent.',
         Schema.object(properties: {
           'prompt': Schema.string(description: 'The question to ask the user'),
           'options': Schema.array(items: Schema.object(properties: {
             'label': Schema.string(description: 'What the user sees (emoji + text)'),
             'value': Schema.string(description: 'The internal value to use check'),
           }, requiredProperties: ['label', 'value'])),
         }, requiredProperties: ['prompt', 'options']),
       ),
       FunctionDeclaration(
         'reschedule_all_overdue',
         'Moves all overdue tasks to a new specific date (usually today or tomorrow).',
         Schema.object(properties: {
           'newDate': Schema.string(description: 'Target date in YYYY-MM-DD format'),
         }, requiredProperties: ['newDate']),
       ),
       FunctionDeclaration(
         'update_task',
         'Updates an existing task in Balaji\'s list.',
         Schema.object(properties: {
           'id': Schema.string(description: 'The unique ID of the task to update'),
           'title': Schema.string(description: 'New title (optional)'),
           'status': Schema.string(description: 'todo, inProgress, completed (optional)'),
           'priority': Schema.integer(description: '0, 1, or 2 (optional)'),
         }, requiredProperties: ['id']),
       ),
     ])
  ];

  GenerativeModel _getGeminiModel(String modelId) => 
      GenerativeModel(
        model: modelId,
        apiKey: geminiApiKey!,
        systemInstruction: Content.text(_systemPrompt),
        tools: _tools,
      );

  Future<ChatResult> getChatResponse(String prompt, {List<AIMessage>? history, List<Task>? tasks, String? extraContext, String? modelId, bool isAutoAI = true}) async {
    if (isAutoAI) {
      // TIER 1: Groq (Maximum speed)
      if (groqApiKey != null && groqApiKey!.isNotEmpty) {
        try {
          return await _getGroqResponse(prompt, 'llama-3.3-70b-versatile', history: history, tasks: tasks, extraContext: extraContext);
        } catch (e) {
          debugPrint('Groq Auto-Failover: $e');
        }
      }

      // TIER 2: Gemini (Robust logic)
      if (geminiApiKey != null && geminiApiKey!.isNotEmpty) {
        try {
          return await _getGeminiResponse(prompt, 'gemini-1.5-flash-latest', history: history, tasks: tasks, extraContext: extraContext);
        } catch (e) {
          debugPrint('Gemini Auto-Failover: $e');
        }
      }

      return ChatResult(text: "All AI providers are currently unavailable.");
    }

    // Manual Mode
    final targetModelId = modelId ?? 'gemini-1.5-flash-latest';
    final friendlyName = _getFriendlyModelName(targetModelId);

    if (targetModelId.contains('gemini')) {
      final res = await _getGeminiResponse(prompt, targetModelId, history: history, tasks: tasks, extraContext: extraContext);
      return ChatResult(text: res.text, actions: res.actions, modelName: friendlyName);
    } else if (targetModelId.contains('llama') && groqApiKey != null) {
      final res = await _getGroqResponse(prompt, targetModelId, history: history, tasks: tasks, extraContext: extraContext);
      return ChatResult(text: res.text, actions: res.actions, modelName: friendlyName);
    }

    return ChatResult(text: "AI Service is not configured correctly.");
  }

  Stream<ChatResult> getChatStream(String prompt, {List<AIMessage>? history, List<Task>? tasks, String? extraContext, String? modelId, bool isAutoAI = true}) async* {
    if (isAutoAI) {
      // THE CONTROL ROOM: Determine the best model for this task
      String assignedModelId = 'llama-3.3-70b-versatile'; // Default
      String brainName = 'Obsidian Reasoning (70B)';
      
      try {
        final intent = await _getOptimalModelId(prompt);
        if (intent == 'ACTION' && geminiApiKey != null) {
          assignedModelId = 'gemini-1.5-flash-latest';
          brainName = 'Obsidian Action (Gemini)';
        } else if (intent == 'CHAT' && groqApiKey != null) {
          assignedModelId = 'llama-3.1-8b-instant';
          brainName = 'Obsidian Speed (8B)';
        } else {
          assignedModelId = 'llama-3.3-70b-versatile';
          brainName = 'Obsidian Reasoning (70B)';
        }
      } catch (e) {
        debugPrint('Dispatcher failed, choosing 70B: $e');
      }

      // Execute on Assigned Model
      try {
        if (assignedModelId.contains('gemini')) {
          final result = await _getGeminiResponse(prompt, assignedModelId, history: history, tasks: tasks, extraContext: extraContext);
          yield ChatResult(text: result.text, actions: result.actions, modelName: brainName);
        } else {
          yield* _getGroqStream(prompt, assignedModelId, history: history, tasks: tasks, extraContext: extraContext).map((r) => 
            ChatResult(text: r.text, actions: r.actions, modelName: brainName)
          );
        }
        return;
      } catch (e) {
        debugPrint('Assigned Model Stream Failed: $e');
      }
    }

    // Explicit Model or Final Fallback
    final targetModelId = modelId ?? 'gemini-1.5-flash-latest';
    final friendlyName = _getFriendlyModelName(targetModelId);
    
    if (targetModelId.contains('gemini')) {
      yield* _getGeminiStream(prompt, targetModelId, history: history, tasks: tasks, extraContext: extraContext)
          .map((r) => ChatResult(text: r.text, actions: r.actions, modelName: friendlyName));
    } else {
      final res = await getChatResponse(prompt, history: history, tasks: tasks, extraContext: extraContext, modelId: targetModelId, isAutoAI: false);
      yield ChatResult(text: res.text, actions: res.actions, modelName: friendlyName);
    }
  }

  String _getFriendlyModelName(String modelId) {
    if (modelId.contains('gemini-1.5-flash')) return 'Gemini 1.5 Flash';
    if (modelId.contains('gemini-1.5-pro')) return 'Gemini 1.5 Pro';
    if (modelId.contains('llama-3.3-70b')) return 'Llama 3.3 (70B)';
    if (modelId.contains('llama-3.1-8b')) return 'Llama 3.1 (8B)';
    if (modelId.contains('mixtral-8x7b')) return 'Mixtral 8x7B';
    return modelId.toUpperCase();
  }

  Stream<ChatResult> _getGeminiStream(String prompt, String modelId, {List<AIMessage>? history, List<Task>? tasks, String? extraContext}) async* {
    debugPrint('AI Service: Starting Gemini Stream ($modelId)...');
    
    try {
      String contextString = '';

      if (extraContext != null && extraContext.isNotEmpty) {
        contextString += 'Productivity Context:\n$extraContext\n\n';
      }

      if (tasks != null && tasks.isNotEmpty) {
        final taskSummary = tasks.take(20).map((t) => 
          '- ID: ${t.id}, Title: ${t.title} (${t.category}, ${t.priority.name}, ${t.status == TaskStatus.completed ? "done" : "pending"})'
        ).join('\n');
        contextString += 'Current Task List:\n$taskSummary\n\n';
      }

      final content = <Content>[];
      
      // Add context as a system-like message if not first turn
      if (contextString.isNotEmpty) {
        content.add(Content.text("IMPORTANT SYSTEM CONTEXT (DO NOT DISCLOSE):\n$contextString"));
      }

      // Add actual conversation history
      if (history != null) {
        content.addAll(_mapHistoryToGemini(history));
      }

      // Add current turn
      content.add(Content.text(prompt));

      final responseStream = _getGeminiModel(modelId).generateContentStream(content);
      
      String accumulatedText = '';
      List<AIAction>? finalActions;

      await for (final response in responseStream) {
        if (response.candidates.isEmpty) {
          final feedback = response.promptFeedback;
          String errorCause = "Blocked by safety filters or empty candidates.";
          if (feedback != null && feedback.blockReason != null) {
            errorCause = "Blocked: ${feedback.blockReason}";
          }
           debugPrint('AI Service Error: $errorCause');
           yield ChatResult(text: "AI Error: $errorCause");
           continue;
        }

        final candidate = response.candidates.first;
        final parts = candidate.content.parts;
        
        final textPart = parts.whereType<TextPart>().map((p) => p.text).join('');
        if (textPart.isNotEmpty) {
          accumulatedText += textPart;
        }

        final functionCalls = parts.whereType<FunctionCall>().toList();
        if (functionCalls.isNotEmpty) {
          debugPrint('AI Service: Received function calls');
          finalActions = functionCalls.map((call) {
            return AIAction(
              id: DateTime.now().millisecondsSinceEpoch.toString() + call.name,
              type: _mapActionToType(call.name),
              parameters: call.args,
            );
          }).toList();
        }

        yield ChatResult(
          text: accumulatedText.isNotEmpty ? accumulatedText : (finalActions != null ? "Processing actions..." : "Obsidian is thinking deeper..."),
          actions: finalActions,
        );
      }
    } catch (e) {
      debugPrint('AI Service: Gemini Stream failed ($e).');
      rethrow;
    }
  }

  Future<ChatResult> _getGeminiResponse(String prompt, String modelId, {List<AIMessage>? history, List<Task>? tasks, String? extraContext}) async {
    try {
      String contextString = '';

      if (extraContext != null && extraContext.isNotEmpty) {
        contextString += 'Productivity Context:\n$extraContext\n\n';
      }

      if (tasks != null && tasks.isNotEmpty) {
        final taskSummary = tasks.take(15).map((t) => 
          '- ID: ${t.id}, Title: ${t.title} (${t.category}, ${t.priority.name}, ${t.status == TaskStatus.completed ? "done" : "pending"})'
        ).join('\n');
        contextString += 'User Tasks (IDs provided for updates):\n$taskSummary\n\n';
      }

      final content = <Content>[];
      
      if (contextString.isNotEmpty) {
        content.add(Content.text("SYSTEM CONTEXT:\n$contextString"));
      }

      if (history != null) {
        content.addAll(_mapHistoryToGemini(history));
      }

      content.add(Content.text(prompt));

      final response = await _getGeminiModel(modelId).generateContent(content);
      
      if (response.candidates.isEmpty) throw Exception("Empty candidates from Gemini");

      final parts = response.candidates.first.content.parts;
      final textParts = parts.whereType<TextPart>().map((p) => p.text).join('\n');
      final functionCalls = parts.whereType<FunctionCall>().toList();

      List<AIAction>? actions;
      if (functionCalls.isNotEmpty) {
        actions = functionCalls.map((call) {
          return AIAction(
            id: DateTime.now().millisecondsSinceEpoch.toString() + call.name,
            type: _mapActionToType(call.name),
            parameters: call.args,
          );
        }).toList();
      }

      return ChatResult(
        text: textParts.isNotEmpty ? textParts : (actions != null ? "I've planned some actions for you." : "I couldn't generate a text response."),
        actions: actions,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ChatResult> _getGroqResponse(String prompt, String modelId, {List<AIMessage>? history, List<Task>? tasks, String? extraContext}) async {
    try {
      final messages = <Map<String, dynamic>>[
        {"role": "system", "content": _systemPrompt}
      ];

      String contextString = '';
      if (extraContext != null && extraContext.isNotEmpty) {
        contextString += 'Productivity Context:\n$extraContext\n\n';
      }
      if (tasks != null && tasks.isNotEmpty) {
        final taskSummary = tasks.take(20).map((t) => 
          '- ID: ${t.id}, Title: ${t.title} (${t.category}, ${t.priority.name}, ${t.status == TaskStatus.completed ? "done" : "pending"})'
        ).join('\n');
        contextString += 'Current Task List:\n$taskSummary\n\n';
      }

      if (contextString.isNotEmpty) {
        messages.add({"role": "system", "content": "Context for current status:\n$contextString"});
      }

      if (history != null) {
        messages.addAll(_mapHistoryToOpenAI(history));
      }

      messages.add({"role": "user", "content": prompt});

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqApiKey',
        },
        body: jsonEncode({
          "model": modelId,
          "messages": messages,
          "temperature": 0.2, // Lower temp for more stable tool calling
          "max_tokens": 1024,
          "tools": _mapToolsToOpenAI(),
          "tool_choice": "auto",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choice = data['choices'][0];
        final message = choice['message'];
        final String? content = message['content'];
        
        List<AIAction>? actions;
        if (message['tool_calls'] != null) {
          final List tools = message['tool_calls'];
          actions = tools.map((t) {
            final func = t['function'];
            final args = func['arguments'] is String 
                ? jsonDecode(func['arguments']) 
                : func['arguments'];
            
            return AIAction(
              id: t['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              type: _mapActionToType(func['name']),
              parameters: args,
            );
          }).toList();
        }

        return ChatResult(
          text: content ?? (actions != null ? "Processing system actions..." : ""),
          actions: actions,
        );
      } else {
        throw Exception("Groq Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Stream<ChatResult> _getGroqStream(String prompt, String modelId, {List<AIMessage>? history, List<Task>? tasks, String? extraContext}) async* {
    final result = await _getGroqResponse(prompt, modelId, history: history, tasks: tasks, extraContext: extraContext);
    yield result;
  }

  // --- Mappers ---

  List<Content> _mapHistoryToGemini(List<AIMessage> history) {
    return history.map((m) {
      String text = m.text;
      if (m.role == MessageRole.assistant && m.actions != null && m.actions!.isNotEmpty) {
        final actionCtx = m.actions!.map((a) => "${a.type.name}(${jsonEncode(a.parameters)})").join(", ");
        text += "\n[ACTION_PROPOSED]: $actionCtx";
      }

      if (m.role == MessageRole.user) {
        return Content.text(text);
      } else {
        return Content.model([TextPart(text)]);
      }
    }).toList();
  }

  List<Map<String, dynamic>> _mapHistoryToOpenAI(List<AIMessage> history) {
    return history.map((m) {
      String text = m.text;
      if (m.role == MessageRole.assistant && m.actions != null && m.actions!.isNotEmpty) {
        final actionCtx = m.actions!.map((a) => "${a.type.name}(${jsonEncode(a.parameters)})").join(", ");
        text += "\n[ACTION_PROPOSED]: $actionCtx";
      }

      return {
        "role": m.role == MessageRole.user ? "user" : "assistant",
        "content": text,
      };
    }).toList();
  }

  // --- THE CONTROL ROOM (Orchestrator) ---

  Future<String> _getOptimalModelId(String prompt) async {
    if (groqApiKey == null) return 'REASONING';
    
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqApiKey',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": [
            {
              "role": "system", 
              "content": "You are the Obsidian Router. Categorize the user input into ONE word: 'ACTION' (task management, creating/deleting/updating tasks), 'CHAT' (simple talk, jokes, greetings), or 'REASONING' (complex questions, advice, planning). Return ONLY the word."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.0,
          "max_tokens": 10,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String content = data['choices'][0]['message']['content'].toString().toUpperCase();
        if (content.contains('ACTION')) return 'ACTION';
        if (content.contains('CHAT')) return 'CHAT';
        return 'REASONING';
      }
    } catch (e) {
      debugPrint('Routing Error: $e');
    }
    return 'REASONING';
  }

  // --- Helpers ---

  AIActionType _mapActionToType(String name) {
    switch (name) {
      case 'create_task': return AIActionType.createTask;
      case 'update_task': return AIActionType.updateTask;
      case 'complete_task': return AIActionType.completeTask;
      case 'delete_task': return AIActionType.deleteTask;
      case 'delete_tasks': return AIActionType.deleteTasks;
      case 'suggest_options': return AIActionType.suggestion;
      case 'reschedule_all_overdue': return AIActionType.rescheduleAll;
      default: return AIActionType.createTask;
    }
  }

  List<Map<String, dynamic>> _mapToolsToOpenAI() {
    return _tools.first.functionDeclarations!.map((fd) {
      return {
        "type": "function",
        "function": {
          "name": fd.name,
          "description": fd.description,
          "parameters": _convertSchemaToOpenAI(fd.parameters!),
        }
      };
    }).toList();
  }

  Map<String, dynamic> _convertSchemaToOpenAI(Schema schema, [String? key]) {
    final typeName = schema.type.name.toLowerCase();
    
    final map = <String, dynamic>{
      "type": typeName == 'integer' ? 'number' : typeName, // More compatible with variety of OpenAI-like endpoints
      "description": (schema.description != null && schema.description!.isNotEmpty) 
          ? schema.description! 
          : (key ?? "No description provided"),
    };

    if (schema.type == SchemaType.object && schema.properties != null) {
      map["properties"] = schema.properties!.map(
        (nk, nv) => MapEntry(nk, _convertSchemaToOpenAI(nv, nk))
      );
      if (schema.requiredProperties != null && schema.requiredProperties!.isNotEmpty) {
        map["required"] = schema.requiredProperties;
      }
    } else if (schema.type == SchemaType.array && schema.items != null) {
      map["items"] = _convertSchemaToOpenAI(schema.items!, "item");
    }

    // OpenAI schema prefers enum at the top level of the field if applicable
    if (schema.enumValues != null && schema.enumValues!.isNotEmpty) {
      map["enum"] = schema.enumValues;
    }

    return map;
  }

  Future<Task?> parseTaskFromNaturalLanguage(String text, {String? modelId}) async {
    final targetModelId = modelId ?? 'gemini-3-flash';
    
    // Try Gemini
    if (targetModelId.startsWith('gemini') && geminiApiKey != null) {
      try {
        final task = await _parseTaskWithGemini(text, targetModelId);
        if (task != null) return task;
      } catch (e) {
        debugPrint('Gemini NLP error: $e');
      }
    }

    // Try NVIDIA
    if (nvidiaApiKey != null) {
      return await _parseTaskWithNvidia(text, targetModelId);
    }
    
    return null;
  }

  Future<Task?> _parseTaskWithGemini(String text, String modelId) async {
    final prompt = '''
Parse the following text into a task JSON object.
Text: "$text"
Today's date is ${DateTime.now().toIso8601String().split('T')[0]}.
Return ONLY a valid JSON object:
{
  "title": "clean task title",
  "date": "YYYY-MM-DD",
  "time": "HH:mm" or null,
  "priority": 0 for low, 1 for medium, 2 for high,
  "category": "Work" or "Personal" or "Health" or "Inbox"
}
''';
    final content = [Content.text(prompt)];
    final response = await _getGeminiModel(modelId).generateContent(content);
    final responseText = response.text;
    if (responseText != null) {
      return _jsonToTask(responseText, text);
    }
    return null;
  }

  String _extractJson(String text) {
    // 1. Try to find content between ```json and ```
    final jsonBlockMatch = RegExp(r'```json\s*([\s\S]*?)\s*```', caseSensitive: false).firstMatch(text);
    if (jsonBlockMatch != null) {
      return jsonBlockMatch.group(1)!.trim();
    }

    // 2. Try to find content between any ``` blocks
    final codeBlockMatch = RegExp(r'```\s*([\s\S]*?)\s*```').firstMatch(text);
    if (codeBlockMatch != null) {
      return codeBlockMatch.group(1)!.trim();
    }

    // 3. Try to find the first '{' and last '}'
    final braceMatch = RegExp(r'(\{[\s\S]*\})').firstMatch(text);
    if (braceMatch != null) {
      return braceMatch.group(1)!.trim();
    }

    // 4. Clean up common AI artifacts
    return text.replaceAll('```json', '').replaceAll('```', '').trim();
  }

  Future<Task?> _parseTaskWithNvidia(String text, String modelId) async {
    try {
      final prompt = 'Parse this text into a JSON task: "$text". Date today: ${DateTime.now().toString().split(' ')[0]}. Return ONLY raw JSON like {"title":"...","date":"YYYY-MM-DD","time":"HH:mm" or null,"priority":0/1/2,"category":"..."}.';
      
      final response = await http.post(
        Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $nvidiaApiKey',
        },
        body: jsonEncode({
          "model": modelId,
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        return _jsonToTask(content, text);
      }
    } catch (e) {
      debugPrint('Nvidia Parsing Error: $e');
    }
    return null;
  }

  Task? _jsonToTask(String responseText, String originalText) {
    try {
      final cleanJson = _extractJson(responseText);
      final Map<String, dynamic> parsed = jsonDecode(cleanJson);
      
      // Mandatory field check
      if (parsed['title'] == null || parsed['title'].toString().isEmpty) {
        return null;
      }

      final title = parsed['title'].toString();
      final dateStr = parsed['date']?.toString();
      
      // Robust Date Parsing
      DateTime date = DateTime.now();
      if (dateStr != null && dateStr.isNotEmpty) {
        date = DateTime.tryParse(dateStr) ?? date;
        // Check for common AI text in date
        if (dateStr.toLowerCase().contains('tomorrow')) {
          date = DateTime.now().add(const Duration(days: 1));
        }
      }
      
      // Flexible Time Parsing (handles "2 PM", "14:00", "2:00 PM")
      String? time = parsed['time']?.toString();
      if (time != null && time.isNotEmpty) {
        time = _normalizeTime(time);
      }
      
      int priorityVal = 1;
      if (parsed['priority'] is int) {
        priorityVal = (parsed['priority'] as int).clamp(0, 2);
      } else if (parsed['priority'] != null) {
        priorityVal = int.tryParse(parsed['priority'].toString())?.clamp(0, 2) ?? 1;
      }

      // Safe category mapping
      final rawCategory = parsed['category']?.toString() ?? 'Inbox';
      final validCategories = ['Work', 'Personal', 'Health', 'Study', 'Finance', 'Inbox'];
      final category = validCategories.firstWhere(
        (c) => c.toLowerCase() == rawCategory.toLowerCase(),
        orElse: () => 'Inbox',
      );

      return Task(
        id: '${DateTime.now().millisecondsSinceEpoch}_${(100 + (DateTime.now().microsecond % 900))}',
        title: title,
        date: date,
        time: time,
        priority: TaskPriority.values[priorityVal],
        category: category,
        recurrence: parsed['recurrence']?.toString(),
      );
    } catch (e) {
      debugPrint('JSON Parsing failed: $e. Response was: $responseText');
      return null;
    }
  }

  String? _normalizeTime(String time) {
    try {
      final t = time.toLowerCase();
      // If it's already HH:mm
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(t)) return t;
      
      // If it contains AM/PM
      if (t.contains('am') || t.contains('pm')) {
        final match = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)').firstMatch(t);
        if (match != null) {
          int hour = int.parse(match.group(1)!);
          final minute = match.group(2) ?? "00";
          final ampm = match.group(3);
          
          if (ampm == 'pm' && hour < 12) hour += 12;
          if (ampm == 'am' && hour == 12) hour = 0;
          
          return '${hour.toString().padLeft(2, '0')}:$minute';
        }
      }
      return time; // Fallback
    } catch (_) {
      return null;
    }
  }
}
