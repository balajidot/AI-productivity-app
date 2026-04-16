import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  static Color getColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFFF5252);
      case TaskPriority.medium:
        return const Color(0xFFFFB74D);
      case TaskPriority.low:
        return const Color(0xFF64B5F6);
    }
  }
}

enum TaskStatus { todo, inProgress, completed }

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final String? time;
  final TaskPriority priority;
  final String category;
  final TaskStatus status;
  final String? recurrence; // 'daily', 'weekly', 'monthly', 'every monday', etc.
  final int? focusSessions;
  final int? timeSpentMinutes;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    this.priority = TaskPriority.medium,
    this.category = 'Inbox',
    this.status = TaskStatus.todo,
    this.recurrence,
    this.focusSessions,
    this.timeSpentMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'priority': priority.index,
      'category': category,
      'status': status.index,
      'recurrence': recurrence,
      'focusSessions': focusSessions,
      'timeSpentMinutes': timeSpentMinutes,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    final dynamic dateValue = map['date'];
    DateTime date;

    if (dateValue is DateTime) {
      date = dateValue;
    } else if (dateValue is Timestamp) {
      date = dateValue.toDate();
    } else if (dateValue is String) {
      date = DateTime.tryParse(dateValue) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return Task(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'No Title',
      description: map['description']?.toString(),
      date: date,
      time: map['time']?.toString(),
      priority: TaskPriority
          .values[((map['priority'] as num?)?.toInt() ?? 1).clamp(0, 2)],
      category: map['category']?.toString() ?? 'Inbox',
      status: TaskStatus
          .values[((map['status'] as num?)?.toInt() ?? 0).clamp(0, 2)],
      recurrence: map['recurrence']?.toString(),
      focusSessions: map['focusSessions'] != null ? (map['focusSessions'] as num).toInt() : null,
      timeSpentMinutes: map['timeSpentMinutes'] != null ? (map['timeSpentMinutes'] as num).toInt() : null,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? time,
    TaskPriority? priority,
    String? category,
    TaskStatus? status,
    String? recurrence,
    int? focusSessions,
    int? timeSpentMinutes,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      status: status ?? this.status,
      recurrence: recurrence ?? this.recurrence,
      focusSessions: focusSessions ?? this.focusSessions,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
    );
  }

  String get priorityLabel => priority.label;
  Color get priorityColor => TaskPriorityExtension.getColor(priority);

  String get formattedTime {
    if (time == null) return '';
    final totalMinutes = timeInMinutes;
    if (totalMinutes == null) return time!;
    final hour = totalMinutes ~/ 60;
    final minute = (totalMinutes % 60).toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  int? get timeInMinutes {
    if (time == null || !time!.contains(':')) return null;
    final parts = time!.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour * 60) + minute;
  }

  String get displayDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) return 'Today';
    if (taskDate == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (taskDate == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.day}/${date.month}';
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  bool get isOverdue {
    if (status == TaskStatus.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (date.isBefore(today)) return true;

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      final taskMins = timeInMinutes;
      if (taskMins != null) {
        final currentMins = (now.hour * 60) + now.minute;
        return taskMins < currentMins;
      }
    }
    return false;
  }

  bool get isUpcoming {
    final dayAfterTomorrow = DateTime.now().add(const Duration(days: 2));
    final start = DateTime(
      dayAfterTomorrow.year,
      dayAfterTomorrow.month,
      dayAfterTomorrow.day,
    );
    return !date.isBefore(start) && status != TaskStatus.completed;
  }
}
