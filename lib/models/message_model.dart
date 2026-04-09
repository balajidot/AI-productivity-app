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
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      role: MessageRole.values[(map['role'] as int? ?? 1).clamp(0, 1)],
      timestamp: map['timestamp'] != null 
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}
