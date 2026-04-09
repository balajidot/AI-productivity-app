enum MessageRole { user, assistant }

class AIMessage {
  final String id;
  final String text;
  final MessageRole role;
  final DateTime timestamp;

  AIMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'role': role.index,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AIMessage.fromMap(Map<String, dynamic> map) {
    return AIMessage(
      id: map['id'],
      text: map['text'],
      role: MessageRole.values[map['role']],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
