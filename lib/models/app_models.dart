enum TaskPriority { low, medium, high }
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
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      time: map['time'],
      priority: TaskPriority.values[map['priority']],
      category: map['category'],
      status: TaskStatus.values[map['status']],
      recurrence: map['recurrence'],
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
    return Habit(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      streak: map['streak'],
      completedDates: (map['completedDates'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => DateTime.parse(s))
          .toList(),
    );
  }
}
