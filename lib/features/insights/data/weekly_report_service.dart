import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../features/tasks/domain/task.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/constants/constants.dart';

class WeeklyReport {
  final int score;
  final List<String> whatWentWell;
  final List<String> areasToImprove;
  final List<Task> nextWeekTasks;

  WeeklyReport({
    required this.score,
    required this.whatWentWell,
    required this.areasToImprove,
    required this.nextWeekTasks,
  });
}

class WeeklyReportService {
  static Future<WeeklyReport> generate({
    required int tasksCompleted,
    required int habitsCompleted,
    required int focusMinutes,
    required int totalTasks,
    required int totalHabits,
    required List<String> topCategories,
    required String geminiApiKey,
  }) async {
    final prompt = """
You are a personal productivity coach analyzing a user's week.

Data:
- Tasks completed: $tasksCompleted / $totalTasks
- Habits maintained: $habitsCompleted / $totalHabits  
- Focus time: ${focusMinutes ~/ 60}h ${focusMinutes % 60}m
- Top categories: ${topCategories.join(', ')}

Generate a JSON response exactly like this:
{
  "score": 73,
  "whatWentWell": ["point 1", "point 2", "point 3"],
  "areasToImprove": ["point 1", "point 2"],
  "nextWeekTasks": [
    {"title": "task title", "category": "Work", "priority": 1},
    {"title": "task title", "category": "Health", "priority": 2},
    {"title": "task title", "category": "Personal", "priority": 1}
  ]
}
Score calculation: base 50 + (totalTasks>0 ? tasksCompleted/totalTasks * 25 : 0) + (totalHabits>0 ? habitsCompleted/totalHabits * 25 : 0). Max 100.
Keep all text concise, actionable, encouraging. English only.
Return ONLY the JSON, no other text.
""";

    final model = GenerativeModel(
      model: AppConstants.geminiFlashModel,
      apiKey: geminiApiKey,
    );
    
    final response = await model.generateContent([Content.text(prompt)]);
    final jsonParsed = jsonDecode(AppUtils.extractJson(response.text ?? ''));
    
    return WeeklyReport(
      score: jsonParsed['score'] as int,
      whatWentWell: List<String>.from(jsonParsed['whatWentWell']),
      areasToImprove: List<String>.from(jsonParsed['areasToImprove']),
      nextWeekTasks: (jsonParsed['nextWeekTasks'] as List).map((t) => Task(
        id: AppUtils.generateId(prefix: 'task'),
        title: t['title'],
        date: DateTime.now().add(const Duration(days: 1)),
        priority: TaskPriority.values[(t['priority'] as int).clamp(0, 2)],
        category: t['category'] ?? 'Inbox',
      )).toList(),
    );
  }
}
