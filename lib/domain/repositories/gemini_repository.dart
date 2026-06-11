import '../entities/chat_message.dart';

abstract class GeminiRepository {
  Future<String> sendMessage({
    required List<ChatMessage> history,
    required String message,
    String? locationContext,
    String? placesContext,
  });
}
