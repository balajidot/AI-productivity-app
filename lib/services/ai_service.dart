import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/ai_action_model.dart';

class ChatResult {
  final String text;
  final List<AIAction>? actions;

  ChatResult({required this.text, this.actions});
}

class AIService {
  final String? geminiApiKey;
  final String? nvidiaApiKey;

  AIService({this.geminiApiKey, this.nvidiaApiKey});

  static const String _systemPrompt = '''
You are "Obsidian AI," a world-class Elite Productivity Coach and Personal Assistant for Balaji. 
Your goal is to help Balaji achieve peak performance through smart planning, habit building, and time management.

AGENT CAPABILITIES (IMPORTANT):
- You have the power to MANAGE Balaji's tasks. 
- You can create new tasks using the 'create_task' tool.
- You can update existing tasks using the 'update_task' tool.
- Every action you propose will be shown to Balaji for APPROVAL before it is added to the system. 
- Be proactive! If Balaji looks overwhelmed, suggest a better plan and offer to reorganize his tasks.

CORE CAPABILITIES:
1. MULTI-LINGUAL FLUENCY: You are fluent in English, Tamil, and Tanglish. If the user talks in Tamil, respond in clear, professional yet friendly Tamil. If they use Tanglish, you can respond in a mix of both.
2. CONTEXT AWARENESS: You will be provided with Balaji's current tasks and productivity metrics. Analyze them proactively.
3. PROACTIVE ADVICE: Don't just answer questions. Suggest improvements. For example, if you see many overdue tasks, suggest a "Reset Day" or help prioritize the most critical ones.
4. PERSONALITY: You are encouraging, sharp, sophisticated, and slightly witty. You believe in Balaji's potential.

RESPONSE GUIDELINES:
- Be concise but extremely insightful. Quality over quantity.
- Use emojis naturally to feel modern and premium.
- When suggesting task changes, explain WHY (e.g., "Doing the hardest task first will give you a dopamine boost").
- If the user is stressed, offer focus techniques like Pomodoro or simple breathing.
- ALWAYS support Tamil/Tanglish queries with high-quality responses.
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
         'update_task',
         'Updates an existing task in Balaji\'s list.',
         Schema.object(properties: {
           'id': Schema.string(description: 'The ID of the task to update'),
           'title': Schema.string(description: 'New title (optional)'),
           'status': Schema.string(description: 'todo, inProgress, completed (optional)'),
           'priority': Schema.integer(description: '0, 1, or 2 (optional)'),
         }, requiredProperties: ['id']),
       ),
     ])
  ];

  GenerativeModel? get _geminiModel => 
      geminiApiKey != null 
          ? GenerativeModel(
              model: 'gemini-2.0-flash',
              apiKey: geminiApiKey!,
              systemInstruction: Content.text(_systemPrompt),
              tools: _tools,
            ) 
          : null;

  Future<ChatResult> getChatResponse(String prompt, {List<Task>? tasks, String? extraContext}) async {
    // Try Gemini First
    if (_geminiModel != null) {
      try {
        final response = await _getGeminiResponse(prompt, tasks: tasks, extraContext: extraContext);
        // If Gemini returns a quota error msg (from our catch block), don't return it yet, try Nvidia
        if (!response.text.contains("exceeded your current quota") && 
            !response.text.contains("API settings")) {
          return response;
        }
      } catch (e) {
        debugPrint('Gemini internal error, falling back to NVIDIA: $e');
      }
    }

    // Fallback to NVIDIA NIM
    if (nvidiaApiKey != null) {
      final text = await _getNvidiaChatResponse(prompt, tasks: tasks, extraContext: extraContext);
      return ChatResult(text: text);
    }

    return ChatResult(text: "AI Service is not configured. Please add API keys.");
  }

  Stream<ChatResult> getChatStream(String prompt, {List<Task>? tasks, String? extraContext}) async* {
    if (_geminiModel != null) {
      yield* _getGeminiStream(prompt, tasks: tasks, extraContext: extraContext);
      return;
    }
    
    // Fallback if no streaming support (like Nvidia currently)
    final result = await getChatResponse(prompt, tasks: tasks, extraContext: extraContext);
    yield result;
  }

  Stream<ChatResult> _getGeminiStream(String prompt, {List<Task>? tasks, String? extraContext}) async* {
    debugPrint('AI Service: Starting Gemini Stream...');
    bool hasYieldedRealContent = false;
    
    try {
      String contextPrompt = prompt;
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

      if (contextString.isNotEmpty) {
        contextPrompt = '$contextString User Message: $prompt';
      }

      final content = [Content.text(contextPrompt)];
      debugPrint('AI Service: Calling generateContentStream...');
      final responseStream = _geminiModel!.generateContentStream(content);
      
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
          hasYieldedRealContent = true;
        }

        final functionCalls = parts.whereType<FunctionCall>().toList();
        if (functionCalls.isNotEmpty) {
          debugPrint('AI Service: Received function calls');
          finalActions = functionCalls.map((call) {
             AIActionType type;
            if (call.name == 'create_task') {
              type = AIActionType.createTask;
            } else if (call.name == 'update_task') {
              type = AIActionType.updateTask;
            } else {
               type = AIActionType.createTask;
            }
            return AIAction(
              id: DateTime.now().millisecondsSinceEpoch.toString() + call.name,
              type: type,
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
      debugPrint('AI Service: Gemini Stream failed ($e). Falling back to non-streaming response...');
    }

    // FINAL FALLBACK: If Gemini failed or gave no content, try direct response (Nvidia backup)
    if (!hasYieldedRealContent) {
      try {
        debugPrint('AI Service: Triggering Emergency Fallback Response...');
        final fallbackResult = await getChatResponse(prompt, tasks: tasks, extraContext: extraContext);
        yield fallbackResult;
      } catch (fallbackError) {
        debugPrint('AI Service: CRITICAL - Both AI systems failed.');
        yield ChatResult(text: "Connectivity critical error. Please check your internet connection.");
      }
    }
  }

  Future<ChatResult> _getGeminiResponse(String prompt, {List<Task>? tasks, String? extraContext}) async {
    try {
      String contextPrompt = prompt;
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

      if (contextString.isNotEmpty) {
        contextPrompt = '$contextString User Message: $prompt';
      }
      final content = [Content.text(contextPrompt)];
      final response = await _geminiModel!.generateContent(content);
      
      final parts = response.candidates.first.content.parts;
      final textParts = parts.whereType<TextPart>().map((p) => p.text).join('\n');
      final functionCalls = parts.whereType<FunctionCall>().toList();

      List<AIAction>? actions;
      if (functionCalls.isNotEmpty) {
        actions = functionCalls.map((call) {
          AIActionType type;
          if (call.name == 'create_task') {
            type = AIActionType.createTask;
          } else if (call.name == 'update_task') {
            type = AIActionType.updateTask;
          } else {
            type = AIActionType.createTask; // Fallback
          }
          return AIAction(
            id: DateTime.now().millisecondsSinceEpoch.toString() + call.name,
            type: type,
            parameters: call.args,
          );
        }).toList();
      }

      return ChatResult(
        text: textParts.isNotEmpty ? textParts : (actions != null ? "I have a plan for you:" : "I couldn't generate a response."),
        actions: actions,
      );
    } catch (e) {
      return ChatResult(text: "Error: $e");
    }
  }

  Future<String> _getNvidiaChatResponse(String prompt, {List<Task>? tasks, String? extraContext}) async {
    try {
      String contextPrompt = prompt;
      String contextString = '';

      if (extraContext != null && extraContext.isNotEmpty) {
        contextString += 'Productivity Context:\n$extraContext\n\n';
      }

      if (tasks != null && tasks.isNotEmpty) {
        final taskSummary = tasks.take(15).map((t) => 
          '- ${t.title} (${t.category}, ${t.priority.name})'
        ).join('\n');
        contextString += 'User Tasks:\n$taskSummary\n\n';
      }

      if (contextString.isNotEmpty) {
        contextPrompt = 'System Context: $_systemPrompt\n\n$contextString User Message: $prompt';
      } else {
        contextPrompt = 'System Context: $_systemPrompt\n\nUser Message: $prompt';
      }

      final response = await http.post(
        Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $nvidiaApiKey',
        },
        body: jsonEncode({
          "model": "meta/llama-3.1-70b-instruct",
          "messages": [
            {"role": "user", "content": contextPrompt}
          ],
          "temperature": 0.6,
          "max_tokens": 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      }
      return "Nvidia Error: ${response.statusCode} - ${response.body}";
    } catch (e) {
      return "Critical AI Error: $e";
    }
  }

  Future<Task?> parseTaskFromNaturalLanguage(String text) async {
    // Try Gemini
    if (_geminiModel != null) {
      try {
        final task = await _parseTaskWithGemini(text);
        if (task != null) return task;
      } catch (e) {
        debugPrint('Gemini NLP error, falling back to NVIDIA: $e');
      }
    }

    // Try NVIDIA
    if (nvidiaApiKey != null) {
      return await _parseTaskWithNvidia(text);
    }
    
    return null;
  }

  Future<Task?> _parseTaskWithGemini(String text) async {
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
    final response = await _geminiModel!.generateContent(content);
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

  Future<Task?> _parseTaskWithNvidia(String text) async {
    try {
      final prompt = 'Parse this text into a JSON task: "$text". Date today: ${DateTime.now().toString().split(' ')[0]}. Return ONLY raw JSON like {"title":"...","date":"YYYY-MM-DD","time":"HH:mm" or null,"priority":0/1/2,"category":"..."}.';
      
      final response = await http.post(
        Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $nvidiaApiKey',
        },
        body: jsonEncode({
          "model": "meta/llama-3.1-8b-instruct",
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
