import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../models/ai_action_model.dart';
import '../models/message_model.dart';
import '../config/constants.dart';

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
  String get _systemPrompt => AppConstants.executiveAssistantPrompt;

  final List<Tool> _tools = [
     Tool(functionDeclarations: [
       FunctionDeclaration(
         'create_task',
         'Creates a single productivity task.',
         Schema.object(properties: {
           'title': Schema.string(description: 'The description of the task'),
           'date': Schema.string(description: 'Date in YYYY-MM-DD format'),
           'time': Schema.string(description: 'Time in HH:mm format (optional)'),
           'priority': Schema.integer(description: '0: Low, 1: Medium, 2: High'),
           'category': Schema.string(description: 'Work, Personal, Health, Study, Finance, or Inbox'),
         }, requiredProperties: ['title', 'date', 'priority', 'category']),
       ),
       FunctionDeclaration(
         'create_bulk_tasks',
         'Splits a main objective into multiple sub-tasks and adds them in bulk. Use this for complex goals.',
         Schema.object(properties: {
           'tasks': Schema.array(items: Schema.object(properties: {
             'title': Schema.string(description: 'Sub-task title'),
             'date': Schema.string(description: 'Date in YYYY-MM-DD format'),
             'priority': Schema.integer(description: '0, 1, or 2'),
             'category': Schema.string(description: 'The category for this sub-task'),
           }, requiredProperties: ['title', 'date', 'priority', 'category'])),
         }, requiredProperties: ['tasks']),
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

  GenerativeModel _getGeminiModel(String modelId) {
    if (geminiApiKey == null || geminiApiKey!.isEmpty) {
      throw Exception('Missing Gemini API Key. Please add it to your configuration.');
    }
    return GenerativeModel(
      model: modelId,
      apiKey: geminiApiKey!,
      systemInstruction: Content.text(_systemPrompt),
      tools: _tools,
    );
  }

  Stream<ChatResult> getChatStream(String prompt,
      {List<AIMessage>? history,
      List<Task>? tasks,
      String? extraContext,
      String? modelId}) async* {
    
    final effectiveModelId = (modelId == AppConstants.autoModelId || modelId == null)
        ? _determineBestModel(prompt)
        : modelId;


    // INTELLIGENT ROUTING BASED ON SELECTION
    try {
      if (effectiveModelId.contains('gemini')) {
        yield* _getGeminiStream(prompt, effectiveModelId,
            history: history, tasks: tasks, extraContext: extraContext);
      } else if (effectiveModelId.contains('llama') || effectiveModelId.contains('deepseek')) {
      // Check if it's NVIDIA Llama
      if (effectiveModelId.contains('meta/llama')) {
        yield* _getNvidiaStream(prompt, effectiveModelId,
            history: history, tasks: tasks, extraContext: extraContext);
      } else {
        // Groq / DeepSeek
        yield* _getGroqStream(prompt, effectiveModelId,
            history: history, tasks: tasks, extraContext: extraContext);
      }
      } else {
        // Fallback
        yield* _getGeminiStream(prompt, AppConstants.geminiModel,
            history: history, tasks: tasks, extraContext: extraContext);
      }
    } catch (e) {
      yield ChatResult(text: "Routing failed: $e");
    }
  }

  String _determineBestModel(String prompt) {
    final input = prompt.toLowerCase();
    
    // 1. Coding / Critical Bug Fixes -> DeepSeek V3 (State of the art)
    if (input.contains('code') || input.contains('dart') || input.contains('debug') || input.contains('fix')) {
      return AppConstants.deepseekV3;
    }
    
    // 2. Pure Logic / Mathematical -> Phi-4
    if (input.contains('math') || input.contains('calculate') || input.contains('logic')) {
      return AppConstants.groqPhi4;
    }

    // 3. High-Level Strategy / Complex Planning -> Llama 3.1 (405B) or Gemini 1.5 Pro
    if (input.contains('strategy') || input.contains('plan') || input.contains('analyze') || input.length > 250) {
      return AppConstants.nvidiaLlama405b;
    }
    
    // 4. Simple pings -> Groq 8B for speed
    if (input.split(' ').length < 5 && !input.contains('task')) {
      return AppConstants.groqLlama8b;
    }
    
    // Default to Flash for reliability
    return AppConstants.geminiFlashModel;
  }

  Future<ChatResult> getChatResponse(String prompt,
      {List<AIMessage>? history,
      List<Task>? tasks,
      String? extraContext,
      String? modelId}) async {
    final effectiveModelId = (modelId == AppConstants.autoModelId || modelId == null)
        ? _determineBestModel(prompt)
        : modelId;

    final friendlyName = _getFriendlyModelName(effectiveModelId);

    if (effectiveModelId.contains('gemini')) {
      final res = await _getGeminiResponse(prompt, effectiveModelId,
          history: history, tasks: tasks, extraContext: extraContext);
      return ChatResult(
          text: res.text, actions: res.actions, modelName: friendlyName);
    } else if (effectiveModelId.contains('llama') || effectiveModelId.contains('deepseek') || effectiveModelId.contains('qwen') || effectiveModelId.contains('phi')) {
      // Handle NVIDIA/Groq Routing
      if (effectiveModelId.contains('meta/llama')) {
        final res = await _getNvidiaResponse(prompt, effectiveModelId,
            history: history, tasks: tasks, extraContext: extraContext);
        return ChatResult(
            text: res.text, actions: res.actions, modelName: friendlyName);
      }
      final res = await _getGroqResponse(prompt, effectiveModelId,
          history: history, tasks: tasks, extraContext: extraContext);
      return ChatResult(
          text: res.text, actions: res.actions, modelName: friendlyName);
    }

    return ChatResult(text: "AI Service is not configured correctly.");
  }


  String _getFriendlyModelName(String modelId) {
    if (modelId == AppConstants.autoModelId) return 'Auto intelligence';
    if (modelId.contains('gemini-1.5-pro')) return 'Obsidian Pro';
    if (modelId.contains('gemini-1.5-flash')) return 'Obsidian Flash';
    if (modelId.contains('405b')) return 'Obsidian Ultra';
    if (modelId.contains('70b')) return 'Obsidian Fast';
    if (modelId.contains('8b')) return 'Obsidian Surge';
    if (modelId.contains('mixtral')) return 'Obsidian Creative';
    if (modelId.contains('gemma')) return 'Obsidian Vision';
    if (modelId.contains('deepseek')) return 'Obsidian Code';
    if (modelId.contains('qwen')) return 'Obsidian Global';
    if (modelId.contains('phi')) return 'Obsidian Logic';
    return 'Obsidian Safety';
  }

  String _buildContextSummary(List<Task>? tasks, String? extraContext) {
    String context = '';
    if (extraContext != null && extraContext.isNotEmpty) {
      context += 'Productivity Context:\n$extraContext\n\n';
    }

    if (tasks != null && tasks.isNotEmpty) {
      final overdue = tasks.where((t) => t.isOverdue).length;
      final pending = tasks.where((t) => t.status != TaskStatus.completed).length;
      
      context += '--- EXECUTIVE DATA SUMMARY ---\n';
      context += '- Total Pending: $pending | Overdue: $overdue\n';
      
      final taskSummary = tasks.where((t) => t.status != TaskStatus.completed).take(20).map((t) => 
        '[${t.isOverdue ? "OVERDUE" : "PENDING"}][${t.category}] ${t.title} (ID:${t.id})'
      ).join('\n');
      context += 'PRIORITY WORKSTREAM:\n$taskSummary\n';
    }
    return context;
  }

  List<Content> _prepareGeminiContent(String prompt, {List<AIMessage>? history, String? contextString}) {
    final content = <Content>[];
    
    if (contextString != null && contextString.isNotEmpty) {
      content.add(Content.text("CRITICAL_SYSTEM_STATE:\n$contextString"));
    }

    if (history != null) {
      content.addAll(_mapHistoryToGemini(history));
    }

    content.add(Content.text(prompt));
    return content;
  }

  Stream<ChatResult> _getGeminiStream(String prompt, String modelId, {List<AIMessage>? history, List<Task>? tasks, String? extraContext}) async* {
    try {
      final contextString = _buildContextSummary(tasks, extraContext);
      final content = _prepareGeminiContent(prompt, history: history, contextString: contextString);

      final responseStream = _getGeminiModel(modelId).generateContentStream(content);
      
      String accumulatedText = '';
      List<AIAction>? finalActions;

      await for (final response in responseStream) {
        if (response.candidates.isEmpty) continue;

        final candidate = response.candidates.first;
        final parts = candidate.content.parts;
        
        final textPart = parts.whereType<TextPart>().map((p) => p.text).join('');
        if (textPart.isNotEmpty) {
          accumulatedText += textPart;
        }

        final functionCalls = parts.whereType<FunctionCall>().toList();
        if (functionCalls.isNotEmpty) {
          finalActions = functionCalls.map((call) {
            return AIAction(
              id: DateTime.now().millisecondsSinceEpoch.toString() + call.name,
              type: _mapActionToType(call.name),
              parameters: call.args,
            );
          }).toList();
        }

        yield ChatResult(
          text: accumulatedText.isNotEmpty ? accumulatedText : (finalActions != null ? "Processing actions..." : ""),
          actions: finalActions,
        );
      }
    } catch (e) {
      debugPrint('Gemini Stream Fail: $e');
      if (modelId != AppConstants.geminiFlashModel) {
        debugPrint('Retrying with Gemini Flash Fallback...');
        yield* _getGeminiStream(prompt, AppConstants.geminiFlashModel, history: history, tasks: tasks, extraContext: extraContext);
      } else {
        yield ChatResult(text: "Connection lost. Please check your API key or internet connection. ($e)");
      }
    }
  }

  Future<ChatResult> _getGeminiResponse(String prompt, String modelId, {List<AIMessage>? history, List<Task>? tasks, String? extraContext}) async {
    try {
      final contextString = _buildContextSummary(tasks, extraContext);
      final content = _prepareGeminiContent(prompt, history: history, contextString: contextString);

      final response = await _getGeminiModel(modelId).generateContent(content);
      
      if (response.candidates.isEmpty) throw Exception("Empty candidates from AI model.");

      final parts = response.candidates.first.content.parts;
      final textParts = parts.whereType<TextPart>().map((p) => p.text).join('\n');
      final functionCalls = parts.whereType<FunctionCall>().toList();

      List<AIAction>? actions;
      if (functionCalls.isNotEmpty) {
        actions = functionCalls.map((call) => AIAction(
          id: DateTime.now().millisecondsSinceEpoch.toString() + call.name,
          type: _mapActionToType(call.name),
          parameters: call.args,
        )).toList();
      }

      return ChatResult(
        text: textParts.isNotEmpty ? textParts : (actions != null ? "Processing actions..." : ""),
        actions: actions,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ChatResult> _getGroqResponse(String prompt, String modelId, {List<AIMessage>? history, List<Task>? tasks, String? extraContext}) async {
    try {
      final messages = <Map<String, dynamic>>[{"role": "system", "content": _systemPrompt}];

      String contextString = '';
      if (extraContext != null && extraContext.isNotEmpty) contextString += 'Productivity Context:\n$extraContext\n\n';
      if (tasks != null && tasks.isNotEmpty) {
        final taskSummary = tasks.take(20).map((t) => 
          '- ID: ${t.id}, Title: ${t.title} (${t.category}, ${t.priority.name}, ${t.status == TaskStatus.completed ? "done" : "pending"})'
        ).join('\n');
        contextString += 'Current Task List:\n$taskSummary\n\n';
      }

      if (contextString.isNotEmpty) messages.add({"role": "system", "content": "Context:\n$contextString"});
      if (history != null) messages.addAll(_mapHistoryToOpenAI(history));
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
          "temperature": 0.7,
          "max_tokens": 2048,
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
            final args = func['arguments'] is String ? jsonDecode(func['arguments']) : func['arguments'];
            return AIAction(
              id: t['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              type: _mapActionToType(func['name']),
              parameters: args,
            );
          }).toList();
        }

        return ChatResult(text: content ?? "", actions: actions);
      } else {
        throw Exception("Groq Error: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ChatResult> _getNvidiaResponse(String prompt, String modelId, {List<AIMessage>? history, List<Task>? tasks, String? extraContext}) async {
    try {
      final messages = <Map<String, dynamic>>[{"role": "system", "content": _systemPrompt}];
      
      if (history != null) messages.addAll(_mapHistoryToOpenAI(history));
      messages.add({"role": "user", "content": prompt});

      final response = await http.post(
        Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $nvidiaApiKey',
        },
        body: jsonEncode({
          "model": modelId,
          "messages": messages,
          "temperature": 0.4,
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
            final args = func['arguments'] is String ? jsonDecode(func['arguments']) : func['arguments'];
            return AIAction(
              id: t['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              type: _mapActionToType(func['name']),
              parameters: args,
            );
          }).toList();
        }

        return ChatResult(text: content ?? "", actions: actions, modelName: 'Obsidian Ultra (405B)');
      } else {
        throw Exception("NVIDIA Error: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Stream<ChatResult> _getGroqStream(String prompt, String modelId, {List<AIMessage>? history, List<Task>? tasks, String? extraContext}) async* {
    yield* _getOpenAIStream(
      url: 'https://api.groq.com/openai/v1/chat/completions',
      apiKey: groqApiKey ?? '',
      modelId: modelId,
      prompt: prompt,
      history: history,
      tasks: tasks,
      extraContext: extraContext,
    );
  }

  Stream<ChatResult> _getNvidiaStream(String prompt, String modelId, {List<AIMessage>? history, List<Task>? tasks, String? extraContext}) async* {
    yield* _getOpenAIStream(
      url: 'https://integrate.api.nvidia.com/v1/chat/completions',
      apiKey: nvidiaApiKey ?? '',
      modelId: modelId,
      prompt: prompt,
      history: history,
      tasks: tasks,
      extraContext: extraContext,
    );
  }

  Stream<ChatResult> _getOpenAIStream({
    required String url,
    required String apiKey,
    required String modelId,
    required String prompt,
    List<AIMessage>? history,
    List<Task>? tasks,
    String? extraContext,
  }) async* {
    final client = http.Client();
    try {
      final messages = <Map<String, dynamic>>[{"role": "system", "content": _systemPrompt}];
      
      String contextString = '';
      if (extraContext != null && extraContext.isNotEmpty) contextString += 'Productivity Context:\n$extraContext\n\n';
      if (tasks != null && tasks.isNotEmpty) {
        final taskSummary = tasks.take(20).map((t) => 
          '- ID: ${t.id}, Title: ${t.title} (${t.category}, ${t.priority.name}, ${t.status == TaskStatus.completed ? "done" : "pending"})'
        ).join('\n');
        contextString += 'Current Task List:\n$taskSummary\n\n';
      }

      if (contextString.isNotEmpty) messages.add({"role": "system", "content": "Context:\n$contextString"});
      if (history != null) messages.addAll(_mapHistoryToOpenAI(history));
      messages.add({"role": "user", "content": prompt});

      final request = http.Request('POST', Uri.parse(url));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      });
      request.body = jsonEncode({
        "model": modelId,
        "messages": messages,
        "temperature": 0.5,
        "stream": true,
        "tools": _mapToolsToOpenAI(),
        "tool_choice": "auto",
      });

      final response = await client.send(request);
      
      if (response.statusCode != 200) {
        final err = await response.stream.bytesToString();
        yield ChatResult(text: "Streaming Error (${response.statusCode}): $err");
        return;
      }

      String fullText = '';
      String? toolCallId;
      String? functionName;
      String argumentsBuffer = '';
      
      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        if (!line.startsWith('data: ')) continue;
        
        final data = line.substring(6).trim();
        if (data == '[DONE]') break;
        
        try {
          final json = jsonDecode(data);
          final choice = json['choices'][0];
          final delta = choice['delta'];
          
          // 1. Text Content
          if (delta['content'] != null) {
            fullText += delta['content'];
            yield ChatResult(text: fullText);
          }
          
          // 2. Tool Calls
          if (delta['tool_calls'] != null) {
            final toolCall = delta['tool_calls'][0];
            if (toolCall['id'] != null) toolCallId = toolCall['id'];
            
            final func = toolCall['function'];
            if (func != null) {
              if (func['name'] != null) functionName = func['name'];
              if (func['arguments'] != null) {
                argumentsBuffer += func['arguments'];
              }
            }
          }
        } catch (e) {
          // Skip malformed chunks
          continue;
        }
      }

      // Final check for actions
      List<AIAction>? finalActions;
      if (functionName != null) {
        try {
          final args = jsonDecode(argumentsBuffer);
          finalActions = [
            AIAction(
              id: toolCallId ?? DateTime.now().millisecondsSinceEpoch.toString(),
              type: _mapActionToType(functionName),
              parameters: args,
            )
          ];
        } catch (_) {}
      }

      // Phase 3: Robust Fallback Parser
      if (finalActions == null || finalActions.isEmpty) {
        finalActions = _tryManualExtraction(fullText);
      }

      yield ChatResult(
        text: fullText.isEmpty ? (finalActions != null ? "Processing executive command..." : "") : fullText,
        actions: finalActions,
      );
    } catch (e) {
      yield ChatResult(text: "Network error during stream: $e");
    } finally {
      client.close();
    }
  }

  /// Extracts tool calls from raw text if structured output fails
  List<AIAction>? _tryManualExtraction(String text) {
     try {
       // Look for JSON-like blocks or specific command patterns
       final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
       if (jsonMatch != null) {
         final possibleJson = jsonMatch.group(0)!;
         final data = jsonDecode(possibleJson);
         
         String? actionName;
         if (data['action'] != null) actionName = data['action'];
         if (data['tool'] != null) actionName = data['tool'];
         if (data['command'] != null) actionName = data['command'];

         if (actionName != null) {
           return [
             AIAction(
               id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
               type: _mapActionToType(actionName),
               parameters: Map<String, dynamic>.from(data['parameters'] ?? data['args'] ?? data),
             )
           ];
         }
       }
     } catch (_) {}
     return null;
  }

  // --- Mappers & Logic ---

  List<Content> _mapHistoryToGemini(List<AIMessage> history) {
    return history.map((m) {
      if (m.role == MessageRole.user) {
        return Content.text(m.text);
      } else {
        String text = m.text;
        if (m.actions != null && m.actions!.isNotEmpty) {
          final actionDesc = m.actions!.map((a) => "[PROPOSED_ACTION: ${a.type.name}]").join(" ");
          text = "$text\n$actionDesc";
        }
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
      return {"role": m.role == MessageRole.user ? "user" : "assistant", "content": text};
    }).toList();
  }



  AIActionType _mapActionToType(String name) {
    switch (name) {
      case 'create_task': return AIActionType.createTask;
      case 'create_bulk_tasks': return AIActionType.createBulkTasks;
      case 'update_task': return AIActionType.updateTask;
      case 'complete_task': return AIActionType.completeTask;
      case 'delete_task': return AIActionType.deleteTask;
      case 'delete_tasks': return AIActionType.deleteTasks;
      case 'suggest_options': return AIActionType.suggestion;
      case 'reschedule_all_overdue': return AIActionType.rescheduleAll;
      case 'generate_visual': return AIActionType.generateVisual;
      default: return AIActionType.createTask;
    }
  }

  List<Map<String, dynamic>> _mapToolsToOpenAI() {
    return _tools.first.functionDeclarations!.map((fd) => {
      "type": "function",
      "function": {
        "name": fd.name,
        "description": fd.description,
        "parameters": _convertSchemaToOpenAI(fd.parameters!),
      }
    }).toList();
  }

  Map<String, dynamic> _convertSchemaToOpenAI(Schema schema, [String? key]) {
    final typeName = schema.type.name.toLowerCase();
    final map = <String, dynamic>{
      "type": typeName == 'integer' ? 'number' : typeName,
      "description": (schema.description != null && schema.description!.isNotEmpty) ? schema.description! : (key ?? ""),
    };
    if (schema.type == SchemaType.object && schema.properties != null) {
      map["properties"] = schema.properties!.map((nk, nv) => MapEntry(nk, _convertSchemaToOpenAI(nv, nk)));
      if (schema.requiredProperties != null) map["required"] = schema.requiredProperties;
    } else if (schema.type == SchemaType.array && schema.items != null) {
      map["items"] = _convertSchemaToOpenAI(schema.items!, "item");
    }
    if (schema.enumValues != null) map["enum"] = schema.enumValues;
    return map;
  }

  Future<Task?> parseTaskFromNaturalLanguage(String text, {String? modelId}) async {
    if (geminiApiKey != null) {
      try {
        return await _parseTaskWithGemini(text, AppConstants.geminiModel);
      } catch (_) {}
    }
    if (nvidiaApiKey != null) return await _parseTaskWithNvidia(text, AppConstants.nvidiaLlama405b);
    return null;
  }

  Future<Task?> _parseTaskWithGemini(String text, String modelId) async {
    final prompt = 'Parse text to JSON. Text: "$text". Date: ${DateTime.now().toString().split(' ')[0]}. Return JSON ONLY: {"title":"...","date":"YYYY-MM-DD","time":"HH:mm","priority":0/1/2,"category":"..."}.';
    final response = await _getGeminiModel(modelId).generateContent([Content.text(prompt)]);
    if (response.text != null) return _jsonToTask(response.text!, text);
    return null;
  }

  Future<Task?> _parseTaskWithNvidia(String text, String modelId) async {
    try {
      final res = await _getNvidiaResponse('Return ONLY JSON for task: "$text"', modelId);
      return _jsonToTask(res.text, text);
    } catch (_) { return null; }
  }

  Task? _jsonToTask(String responseText, String originalText) {
    try {
      final cleanJson = _extractJson(responseText);
      final Map<String, dynamic> parsed = jsonDecode(cleanJson);
      final title = parsed['title']?.toString();
      if (title == null) return null;
      DateTime date = DateTime.tryParse(parsed['date']?.toString() ?? "") ?? DateTime.now();
      int priorityVal = (parsed['priority'] is int) ? (parsed['priority'] as int).clamp(0, 2) : 1;
      final category = AppConstants.taskCategories.firstWhere((c) => c.toLowerCase() == (parsed['category']?.toString().toLowerCase() ?? ""), orElse: () => 'Inbox');

      return Task(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        date: date,
        time: parsed['time']?.toString(),
        priority: TaskPriority.values[priorityVal],
        category: category,
      );
    } catch (_) { return null; }
  }

  String _extractJson(String text) {
    final braceMatch = RegExp(r'(\{[\s\S]*\})').firstMatch(text);
    return braceMatch != null ? braceMatch.group(1)!.trim() : text;
  }
}
