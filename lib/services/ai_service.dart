import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AIService {
  final String? geminiApiKey;
  final String? nvidiaApiKey;

  AIService({this.geminiApiKey, this.nvidiaApiKey});

  GenerativeModel? get _geminiModel => 
      geminiApiKey != null 
          ? GenerativeModel(
              model: 'gemini-2.0-flash',
              apiKey: geminiApiKey!,
              systemInstruction: Content.text(_systemPrompt),
            ) 
          : null;

  static const String _systemPrompt = '''
You are an AI productivity assistant named "Obsidian AI" for a user named Balaji. 
You help with:
- Task management and planning
- Daily schedule optimization
- Focus and productivity tips
- Time management advice

Be concise, helpful, and encouraging. Use simple language.
When the user asks about tasks, provide actionable advice.
Keep responses under 150 words unless detailed explanation is needed.
''';

  Future<String> getChatResponse(String prompt, {List<Task>? tasks}) async {
    // Try Gemini First
    if (_geminiModel != null) {
      try {
        final response = await _getGeminiResponse(prompt, tasks: tasks);
        // If Gemini returns a quota error msg (from our catch block), don't return it yet, try Nvidia
        if (!response.contains("exceeded your current quota") && 
            !response.contains("API settings")) {
          return response;
        }
      } catch (e) {
        debugPrint('Gemini internal error, falling back to NVIDIA: $e');
      }
    }

    // Fallback to NVIDIA NIM
    if (nvidiaApiKey != null) {
      return await _getNvidiaChatResponse(prompt, tasks: tasks);
    }

    return "AI Service is not configured. Please add API keys.";
  }

  Future<String> _getGeminiResponse(String prompt, {List<Task>? tasks}) async {
    try {
      String contextPrompt = prompt;
      if (tasks != null && tasks.isNotEmpty) {
        final taskSummary = tasks.take(10).map((t) => 
          '- ${t.title} (${t.category}, ${t.priority.name}, ${t.status == TaskStatus.completed ? "done" : "pending"})'
        ).join('\n');
        contextPrompt = 'User Tasks:\n$taskSummary\n\nUser Message: $prompt';
      }
      final content = [Content.text(contextPrompt)];
      final response = await _geminiModel!.generateContent(content);
      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> _getNvidiaChatResponse(String prompt, {List<Task>? tasks}) async {
    try {
      String contextPrompt = prompt;
      if (tasks != null && tasks.isNotEmpty) {
        final taskSummary = tasks.take(10).map((t) => 
          '- ${t.title} (${t.category}, ${t.priority.name})'
        ).join('\n');
        contextPrompt = 'System Context: $_systemPrompt\n\nUser Tasks:\n$taskSummary\n\nUser Message: $prompt';
      }

      final response = await http.post(
        Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $nvidiaApiKey',
        },
        body: jsonEncode({
          "model": "meta/llama-3.1-8b-instruct",
          "messages": [
            {"role": "user", "content": contextPrompt}
          ],
          "temperature": 0.5,
          "max_tokens": 512,
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
