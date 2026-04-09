import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.high: return 'High';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.low: return 'Low';
    }
  }

  static Color getColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return const Color(0xFFFF5252);
      case TaskPriority.medium: return const Color(0xFFFFB74D);
      case TaskPriority.low: return const Color(0xFF64B5F6);
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
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'No Title',
      description: map['description']?.toString(),
      date: map['date'] != null ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now() : DateTime.now(),
      time: map['time']?.toString(),
      priority: TaskPriority.values[((map['priority'] as num?)?.toInt() ?? 1).clamp(0, 2)],
      category: map['category']?.toString() ?? 'Inbox',
      status: TaskStatus.values[((map['status'] as num?)?.toInt() ?? 0).clamp(0, 2)],
      recurrence: map['recurrence']?.toString(),
    );
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? date,
    String? time,
    TaskPriority? priority,
    String? category,
    TaskStatus? status,
    String? recurrence,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      status: status ?? this.status,
      recurrence: recurrence ?? this.recurrence,
    );
  }

  String get priorityLabel => priority.label;
  Color get priorityColor => TaskPriorityExtension.getColor(priority);

  String get formattedTime {
    if (time == null) return '';
    final parts = time!.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
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
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today) && status != TaskStatus.completed;
  }

  bool get isUpcoming {
    final dayAfterTomorrow = DateTime.now().add(const Duration(days: 2));
    final start = DateTime(dayAfterTomorrow.year, dayAfterTomorrow.month, dayAfterTomorrow.day);
    return !date.isBefore(start) && status != TaskStatus.completed;
  }
}

class Habit {
  final String id;
  final String name;
  final String icon;
  final int streak;
  final List<DateTime> completedDates;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    this.streak = 0,
    this.completedDates = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'streak': streak,
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList().join(','),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    List<DateTime> dates = [];
    final rawDates = map['completedDates'];
    if (rawDates is String && rawDates.isNotEmpty) {
      dates = rawDates.split(',').map((s) => DateTime.tryParse(s)).whereType<DateTime>().toList();
    } else if (rawDates is List) {
      dates = rawDates.map((s) => DateTime.tryParse(s.toString())).whereType<DateTime>().toList();
    }

    return Habit(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'New Habit',
      icon: map['icon']?.toString() ?? 'star',
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      completedDates: dates,
    );
  }
}

class AppSettings {
  final bool smartAnalysis;
  final bool notificationsEnabled;
  final String aiTone;
  final String themeMode; // 'Light', 'Dark', 'System'

  const AppSettings({
    this.smartAnalysis = true,
    this.notificationsEnabled = true,
    this.aiTone = 'Professional',
    this.themeMode = 'System',
  });

  AppSettings copyWith({
    bool? smartAnalysis,
    bool? notificationsEnabled,
    String? aiTone,
    String? themeMode,
  }) {
    return AppSettings(
      smartAnalysis: smartAnalysis ?? this.smartAnalysis,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      aiTone: aiTone ?? this.aiTone,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
