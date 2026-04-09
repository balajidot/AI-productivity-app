import 'dart:convert';

enum AIActionType { createTask, updateTask, deleteRecord, setHabit, multiAction }

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

  String toJson() => json.encode(toMap());
}
