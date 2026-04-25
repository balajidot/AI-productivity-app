import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class Habit {
  final String id;
  final String name;
  final String icon;
  final int streak;
  final List<DateTime> completedDates;
  /// Pro feature: Dates where the user applied a Streak Freeze token.
  /// These count as "present" in streak calculation so the streak isn't broken.
  final List<DateTime> frozenDates;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    this.streak = 0,
    this.completedDates = const [],
    this.frozenDates = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'streak': streak,
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
      'frozenDates': frozenDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  Habit copyWith({
    String? id,
    String? name,
    String? icon,
    int? streak,
    List<DateTime>? completedDates,
    List<DateTime>? frozenDates,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      streak: streak ?? this.streak,
      completedDates: completedDates ?? this.completedDates,
      frozenDates: frozenDates ?? this.frozenDates,
    );
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    List<DateTime> parseDates(dynamic raw) {
      if (raw is List) {
        return raw
            .map((s) {
              if (s is DateTime) return s;
              if (s is Timestamp) return s.toDate();
              return DateTime.tryParse(s.toString());
            })
            .whereType<DateTime>()
            .toList();
      } else if (raw is String && raw.isNotEmpty) {
        return raw
            .split(',')
            .map((s) => DateTime.tryParse(s))
            .whereType<DateTime>()
            .toList();
      }
      return [];
    }

    return Habit(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'New Habit',
      icon: map['icon']?.toString() ?? 'star',
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      completedDates: parseDates(map['completedDates']),
      frozenDates: parseDates(map['frozenDates']),
    );
  }

  bool get completedToday {
    if (completedDates.isEmpty) return false;
    final now = DateTime.now();
    return completedDates.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );
  }

  bool get frozenToday {
    if (frozenDates.isEmpty) return false;
    final now = DateTime.now();
    return frozenDates.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );
  }
}
