import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/constants/secrets.dart';
import '../../../core/services/notification_service.dart';
import '../../habits/presentation/habit_provider.dart';
import '../../tasks/presentation/task_provider.dart';
import '../../settings/presentation/settings_provider.dart';

/// Generates a personalized AI morning briefing and schedules it as a daily
/// push notification at 8:00 AM. Pro-only feature.
class MorningBriefingService {
  static const int _notificationId = 9001;
  static const String _channelId = 'morning_briefing';

  /// Schedule the daily briefing notification.
  /// Safe to call on every app launch — cancels + reschedules.
  static Future<void> scheduleDailyBriefing({
    required Ref ref,
    TimeOfDay time = const TimeOfDay(hour: 8, minute: 0),
  }) async {
    final ns = NotificationService();
    await ns.cancelNotification(_notificationId);

    if (!ref.read(isPremiumProvider)) return;
    if (!ref.read(appSettingsProvider).notificationsEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, time.hour, time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.zonedSchedule(
        id: _notificationId,
        title: '☀️ Good morning!',
        body: "Your Zeno AI briefing is ready. Tap to see today's plan.",
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Morning Briefing',
            channelDescription: 'Daily AI-powered morning productivity summary',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('MorningBriefing: schedule failed — $e');
    }
  }

  /// Generate the personalized briefing text using Gemini Flash.
  /// Returns a fallback string on any error — never throws.
  static Future<String> generateBriefingText({required Ref ref}) async {
    try {
      final tasks = ref.read(tasksProvider).tasks;
      final habits = ref.read(habitsProvider);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final todayTasks = tasks.where((t) {
        final d = t.date;
        return DateTime(d.year, d.month, d.day) == todayDate;
      }).toList();

      final overdueTasks = tasks.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        return d.isBefore(todayDate) && t.status.name != 'completed';
      }).toList();

      final topStreak = habits.isEmpty
          ? 0
          : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);

      final prompt = '''
You are a warm, motivating personal productivity assistant.
Generate a concise morning briefing (2-3 sentences, max 120 words) for the user.
Make it feel personal and encouraging, not robotic.

Data:
- Today's tasks: ${todayTasks.length}
- Overdue tasks: ${overdueTasks.length}
- Top habit streak: $topStreak days
- Day: ${_dayName(today.weekday)}

Rules:
- Start with a warm greeting that includes the day name
- Mention their task load and any overdue items naturally
- End with a short motivational nudge tied to their streak
- Use emoji sparingly (1-2 max)
- Do NOT use bullet points or headers
''';

      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: Secrets.geminiApiKey,
      );
      final result = await model.generateContent([Content.text(prompt)]);
      return result.text?.trim() ??
          "Good morning! You've got tasks lined up — let's make today count. 🎯";
    } catch (_) {
      return "Good morning! Check your tasks and keep your streak going today. 💪";
    }
  }

  static String _dayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[(weekday - 1).clamp(0, 6)];
  }
}

/// On-demand FutureProvider for the AI-generated briefing text.
/// autoDispose — no caching between navigations.
final morningBriefingProvider = FutureProvider.autoDispose<String>((ref) {
  return MorningBriefingService.generateBriefingText(ref: ref);
});
