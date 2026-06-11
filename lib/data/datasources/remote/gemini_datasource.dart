import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/chat_message.dart';

abstract class GeminiDataSource {
  Future<String> sendMessage({
    required List<ChatMessage> history,
    required String message,
    String? locationContext,
    String? placesContext,
  });
}

class GeminiDataSourceImpl implements GeminiDataSource {
  static const String _system =
      'Voce e o assistente de turismo do aplicativo Tour. '
      'Responda SEMPRE em portugues brasileiro. '
      'Ajude o usuario a descobrir lugares interessantes proximos a ele. '
      'Seja amigavel, objetivo e util. '
      'Se nao souber algo especifico, diga claramente. '
      'Nao invente horarios, precos ou enderecos.';

  @override
  Future<String> sendMessage({
    required List<ChatMessage> history,
    required String message,
    String? locationContext,
    String? placesContext,
  }) async {
    final key = AppConstants.geminiApiKey;
    if (key.isEmpty || key == 'COLE_SUA_CHAVE_AQUI') {
      throw const GeminiException(
        message: 'Configure a chave Gemini no arquivo .env.',
      );
    }

    try {
      // Pacote oficial — aceita AQ. e AIza... automaticamente
      final model = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: key,
        systemInstruction: Content.system(_system),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1024,
        ),
      );

      // Monta contexto de localização e locais
      final parts = <String>[];
      if (locationContext != null) {
        parts.add('Localizacao do usuario: $locationContext');
      }
      if (placesContext != null) {
        parts.add('Locais proximos:\n$placesContext');
      }
      final userMsg = parts.isNotEmpty
          ? '${parts.join("\n")}\n\nPergunta: $message'
          : message;

      // Monta histórico no formato do pacote
      final chatHistory = <Content>[];
      for (final m in (history.length > 10
          ? history.sublist(history.length - 10)
          : history)) {
        if (!m.isLoading && m.content.isNotEmpty) {
          chatHistory.add(
            m.isUser
              ? Content('user', [TextPart(m.content)])
              : Content('model', [TextPart(m.content)]),
          );
        }
      }

      // Inicia chat com histórico e envia mensagem
      final chat = model.startChat(history: chatHistory);
      final response = await chat.sendMessage(Content('user', [TextPart(userMsg)]));

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw const GeminiException(
            message: 'Sem resposta da IA. Tente novamente.');
      }
      return text;
    } on GeminiException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('403') || msg.contains('permission') || msg.contains('PERMISSION_DENIED')) {
        throw const GeminiException(
          message: 'Sem permissao para usar o Gemini.\n'
              'Verifique se a Generative Language API esta ativada\n'
              'no projeto Google Cloud.',
        );
      }
      if (msg.contains('429') || msg.contains('quota') || msg.contains('RESOURCE_EXHAUSTED')) {
        throw const GeminiException(
            message: 'Limite de requisicoes atingido. Aguarde alguns segundos.');
      }
      if (msg.contains('401') || msg.contains('API_KEY') || msg.contains('invalid')) {
        throw const GeminiException(
          message: 'Chave Gemini invalida.\n'
              'Verifique o valor no arquivo .env.',
        );
      }
      throw GeminiException(message: 'Erro ao conectar com a IA: $msg');
    }
  }
}