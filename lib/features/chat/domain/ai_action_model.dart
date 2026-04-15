import 'dart:convert';

enum AIActionType { createTask, createBulkTasks, updateTask, deleteTask, deleteTasks, completeTask, updateHabit, rescheduleAll, deleteRecord, setHabit, multiAction, suggestion, generateVisual }

class AIAction {
  final String id;
  final AIActionType type;
  final Map<String, dynamic> parameters;
  bool isExecuted;
  bool isRejected;

  AIAction({
    required this.id,
    required this.type,
    required this.parameters,
    this.isExecuted = false,
    this.isRejected = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'parameters': parameters,
      'isExecuted': isExecuted,
      'isRejected': isRejected,
    };
  }

  factory AIAction.fromMap(Map<String, dynamic> map) {
    return AIAction(
      id: map['id']?.toString() ?? '',
      type: AIActionType.values[(map['type'] as int? ?? 0).clamp(0, AIActionType.values.length - 1)],
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
      isExecuted: map['isExecuted'] as bool? ?? false,
      isRejected: map['isRejected'] as bool? ?? false,
    );
  }

  AIAction copyWith({
    String? id,
    AIActionType? type,
    Map<String, dynamic>? parameters,
    bool? isExecuted,
    bool? isRejected,
  }) {
    return AIAction(
      id: id ?? this.id,
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
      isExecuted: isExecuted ?? this.isExecuted,
      isRejected: isRejected ?? this.isRejected,
    );
  }

  String toJson() => json.encode(toMap());
}
