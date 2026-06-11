import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    String? id,
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.isLoading = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  bool get isUser      => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;

  Map<String, dynamic> toGeminiFormat() => {
    'role': role == MessageRole.user ? 'user' : 'model',
    'parts': [{'text': content}],
  };

  ChatMessage copyWith({String? content, bool? isLoading}) => ChatMessage(
    id: id, content: content ?? this.content,
    role: role, timestamp: timestamp,
    isLoading: isLoading ?? this.isLoading,
  );
}
