import 'package:flutter/material.dart';
import '../domain/task.dart';


class ParsedTaskData {
  final String cleanTitle;
  final DateTime? date;
  final TimeOfDay? time;
  final TaskPriority? priority;
  final String? category;
  final String? recurrence;

  ParsedTaskData({
    required this.cleanTitle,
    this.date,
    this.time,
    this.priority,
    this.category,
    this.recurrence,
  });
}

class NaturalLanguageParser {
  static ParsedTaskData parse(String input) {
    String text = input.trim();
    DateTime? parsedDate;
    TimeOfDay? parsedTime;
    TaskPriority? parsedPriority;
    String? parsedCategory;
    String? parsedRecurrence;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // "today" shortcuts
    if (_containsWord(text, 'today')) {
      parsedDate = today;
      text = _removeWord(text, 'today');
    }
    // "tomorrow" shortcuts
    else if (_containsWord(text, 'tomorrow') ||
        _containsWord(text, 'tmrw')) {
      parsedDate = today.add(const Duration(days: 1));
      text = _removeWord(text, 'tomorrow');
      text = _removeWord(text, 'tmrw');
    } else {
      // "in X days"
      final inDaysMatch = RegExp(
        r'(?:in\s+)?(\d+)\s+(?:days|day)',
        caseSensitive: false,
      ).firstMatch(text);
      if (inDaysMatch != null) {
        final days = int.parse(inDaysMatch.group(1)!);
        parsedDate = today.add(Duration(days: days));
        text = text.replaceAll(inDaysMatch.group(0)!, '');
      }

      // "next week" shortcut
      if (parsedDate == null &&
          (_containsWord(text, 'next week'))) {
        parsedDate = today.add(const Duration(days: 7));
        text = _removeWord(text, 'next week');
      }

      // "day after tomorrow"
      if (parsedDate == null &&
          text.toLowerCase().contains('day after tomorrow')) {
        parsedDate = today.add(const Duration(days: 2));
        text = text.replaceAll(
          RegExp(r'day\s+after\s+tomorrow', caseSensitive: false),
          '',
        );
      }

      // "next monday", "next tuesday", etc.
      if (parsedDate == null) {
        final nextDayMatch = RegExp(
          r'next\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
          caseSensitive: false,
        ).firstMatch(text);
        if (nextDayMatch != null) {
          final dayName = nextDayMatch.group(1)!.toLowerCase();
          parsedDate = _getNextWeekday(dayName, today);
          text = text.replaceAll(nextDayMatch.group(0)!, '');
        }
      }
    }

    // "this monday", "this friday"
    if (parsedDate == null) {
      final thisDayMatch = RegExp(
        r'this\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
        caseSensitive: false,
      ).firstMatch(text);
      if (thisDayMatch != null) {
        final dayName = thisDayMatch.group(1)!.toLowerCase();
        parsedDate = _getThisWeekday(dayName, today);
        text = text.replaceAll(thisDayMatch.group(0)!, '');
      }
    }

    // --- Time Detection ---
    final timeMatch = RegExp(
      r'(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm|AM|PM)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      final int minute =
          timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
      final period = timeMatch.group(3)!.toLowerCase();

      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      parsedTime = TimeOfDay(hour: hour, minute: minute);
      text = text.replaceAll(timeMatch.group(0)!, '');
    }

    // 24h format: "at 14:00", "at 9:30"
    if (parsedTime == null) {
      final time24Match = RegExp(r'at\s+(\d{1,2}):(\d{2})\b').firstMatch(text);
      if (time24Match != null) {
        final hour = int.parse(time24Match.group(1)!);
        final minute = int.parse(time24Match.group(2)!);
        if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          parsedTime = TimeOfDay(hour: hour, minute: minute);
          text = text.replaceAll(time24Match.group(0)!, '');
        }
      }
    }

    // Simple format: "at 5", "at 10"
    if (parsedTime == null) {
      final simpleTimeMatch = RegExp(r'\bat\s+(\d{1,2})\b', caseSensitive: false).firstMatch(text);
      if (simpleTimeMatch != null) {
        int hour = int.parse(simpleTimeMatch.group(1)!);
        if (hour > 0 && hour <= 12) {
          // Rule: if 1-7, assume PM. if 8-12, assume current time context or default to morning if early.
          // For simplicity in a task app: 1-7 -> PM (13-19), 8-11 -> AM. 12 -> PM.
          if (hour >= 1 && hour <= 7) hour += 12;
          if (hour == 12) hour = 12; // Noon

          parsedTime = TimeOfDay(hour: hour, minute: 0);
          text = text.replaceAll(simpleTimeMatch.group(0)!, '');
        }
      }
    }
    if (parsedTime == null) {
      if (_containsWord(text, 'morning')) {
        parsedTime = const TimeOfDay(hour: 9, minute: 0);
        text = _removeWord(text, 'morning');
      } else if (_containsWord(text, 'afternoon')) {
        parsedTime = const TimeOfDay(hour: 14, minute: 0);
        text = _removeWord(text, 'afternoon');
      } else if (_containsWord(text, 'evening')) {
        parsedTime = const TimeOfDay(hour: 18, minute: 0);
        text = _removeWord(text, 'evening');
      } else if (_containsWord(text, 'night')) {
        parsedTime = const TimeOfDay(hour: 21, minute: 0);
        text = _removeWord(text, 'night');
      }
    }

    // --- Priority Detection ---
    if (text.contains('!!!') ||
        _containsWord(text, 'urgent')) {
      parsedPriority = TaskPriority.high;
      text = text.replaceAll('!!!', '');
      text = _removeWord(text, 'urgent');
    } else if (text.contains('!!') ||
        _containsWord(text, 'important')) {
      parsedPriority = TaskPriority.high;
      text = text.replaceAll('!!', '');
      text = _removeWord(text, 'important');
    }

    // --- Category Detection ---
    final categoryMatch = RegExp(
      r'[@#](work|personal|health|study|finance|shopping)',
      caseSensitive: false,
    ).firstMatch(text);
    if (categoryMatch != null) {
      parsedCategory = categoryMatch.group(1)!.substring(0, 1).toUpperCase() +
          categoryMatch.group(1)!.substring(1).toLowerCase();
      text = text.replaceAll(categoryMatch.group(0)!, '');
    }

    // --- Recurrence Detection ---
    if (_containsWord(text, 'everyday') || _containsWord(text, 'daily')) {
      parsedRecurrence = 'daily';
      text = _removeWord(text, 'everyday');
      text = _removeWord(text, 'daily');
    } else if (_containsWord(text, 'weekly')) {
      parsedRecurrence = 'weekly';
      text = _removeWord(text, 'weekly');
    } else if (_containsWord(text, 'monthly')) {
      parsedRecurrence = 'monthly';
      text = _removeWord(text, 'monthly');
    } else {
      final everyMatch = RegExp(
        r'every\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
        caseSensitive: false,
      ).firstMatch(text);
      if (everyMatch != null) {
        parsedRecurrence = 'every ${everyMatch.group(1)!.toLowerCase()}';
        text = text.replaceAll(everyMatch.group(0)!, '');
      }
    }

    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Remove trailing 'at' or 'on' which sometimes remain after date/time extraction
    text = text.replaceAll(RegExp(r'\s+(?:at|on|for|in|by)$', caseSensitive: false), '').trim();
    text = text.replaceAll(RegExp(r'^(?:at|on|for|in|by)\s+', caseSensitive: false), '').trim();

    return ParsedTaskData(
      cleanTitle: text.isEmpty ? (input.length > 50 ? '${input.substring(0, 47)}...' : input.trim()) : text,
      date: parsedDate,
      time: parsedTime,
      priority: parsedPriority,
      category: parsedCategory,
      recurrence: parsedRecurrence,
    );
  }

  static List<String> getSuggestions(String input) {
    final suggestions = <String>[];
    final lower = input.toLowerCase();

    if (lower.isNotEmpty &&
        !lower.contains('today') &&
        !lower.contains('tomorrow')) {
      suggestions.add('$input today');
      suggestions.add('$input tomorrow');
    }
    if (lower.isNotEmpty &&
        !RegExp(r'\d{1,2}\s*(am|pm)', caseSensitive: false).hasMatch(lower)) {
      suggestions.add('$input at 9am');
      suggestions.add('$input at 2pm');
    }
    if (lower.isNotEmpty &&
        !lower.contains('daily') &&
        !lower.contains('everyday')) {
      suggestions.add('$input daily');
    }

    return suggestions.take(3).toList();
  }

  static bool _containsWord(String text, String word) {
    return RegExp(
      '\\b${RegExp.escape(word)}\\b',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static String _removeWord(String text, String word) {
    return text.replaceAll(
      RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false),
      '',
    );
  }

  static DateTime _getNextWeekday(String dayName, DateTime from) {
    final targetDay = _dayNameToInt(dayName);
    int daysAhead = targetDay - from.weekday;
    if (daysAhead <= 0) daysAhead += 7;
    return from.add(Duration(days: daysAhead));
  }

  static DateTime _getThisWeekday(String dayName, DateTime from) {
    final targetDay = _dayNameToInt(dayName);
    int daysAhead = targetDay - from.weekday;
    if (daysAhead < 0) daysAhead += 7;
    return from.add(Duration(days: daysAhead));
  }

  static int _dayNameToInt(String day) {
    switch (day) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }
}
