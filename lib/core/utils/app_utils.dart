import 'dart:math';

class AppUtils {
  /// Generates a unique ID for tasks, habits, or messages
  static String generateId({String prefix = ''}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000).toString().padLeft(4, '0');
    return prefix.isNotEmpty ? '${prefix}_${timestamp}_$random' : '${timestamp}_$random';
  }

  /// Extracts JSON from a string that might contain other text
  static String extractJson(String text) {
    try {
      final braceMatch = RegExp(r'(\{[\s\S]*\})').firstMatch(text);
      if (braceMatch != null) {
        return braceMatch.group(1)!.trim();
      }
      
      final bracketMatch = RegExp(r'(\[[\s\S]*\])').firstMatch(text);
      if (bracketMatch != null) {
        return bracketMatch.group(1)!.trim();
      }
    } catch (_) {}
    return text.trim();
  }

  /// Formats date to YYYY-MM-DD
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Converts a lowercase weekday name to DateTime weekday int (Monday=1 … Sunday=7)
  static int dayNameToInt(String day) {
    switch (day) {
      case 'monday':    return DateTime.monday;
      case 'tuesday':   return DateTime.tuesday;
      case 'wednesday': return DateTime.wednesday;
      case 'thursday':  return DateTime.thursday;
      case 'friday':    return DateTime.friday;
      case 'saturday':  return DateTime.saturday;
      case 'sunday':    return DateTime.sunday;
      default:          return 0; // Invalid weekday — caller must guard against this
    }
  }
}
