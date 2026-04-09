import 'ai_action_model.dart';

enum MessageRole { user, assistant }

class AIMessage {
  final String id;
  final String text;
  final MessageRole role;
  final DateTime timestamp;

  final List<AIAction>? actions;
  final String? modelName;

  AIMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
    this.actions,
    this.modelName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'role': role.index,
      'timestamp': timestamp.toIso8601String(),
      'actions': actions?.map((x) => x.toMap()).toList(),
      'modelName': modelName,
    };
  }

  factory AIMessage.fromMap(Map<String, dynamic> map) {
    return AIMessage(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      role: MessageRole.values[(map['role'] as int? ?? 1).clamp(0, 1)],
      timestamp: map['timestamp'] != null 
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      actions: (map['actions'] as List?)?.map((x) => AIAction.fromMap(x)).toList(),
      modelName: map['modelName']?.toString(),
    );
  }
}
