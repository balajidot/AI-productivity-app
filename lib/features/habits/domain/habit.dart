import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

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
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  Habit copyWith({
    String? id,
    String? name,
    String? icon,
    int? streak,
    List<DateTime>? completedDates,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      streak: streak ?? this.streak,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    List<DateTime> dates = [];
    final rawDates = map['completedDates'];

    if (rawDates is List) {
      dates = rawDates
          .map((s) {
            if (s is DateTime) return s;
            if (s is Timestamp) return s.toDate();
            return DateTime.tryParse(s.toString());
          })
          .whereType<DateTime>()
          .toList();
    } else if (rawDates is String && rawDates.isNotEmpty) {
      dates = rawDates
          .split(',')
          .map((s) => DateTime.tryParse(s))
          .whereType<DateTime>()
          .toList();
    }

    return Habit(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'New Habit',
      icon: map['icon']?.toString() ?? 'star',
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      completedDates: dates,
    );
  }

  bool get completedToday {
    if (completedDates.isEmpty) return false;
    final last = completedDates.last;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }
}
