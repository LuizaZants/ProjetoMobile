import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
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
  final Dio _dio = DioClient.instance;

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
        message: 'Configure a chave Gemini no arquivo .env.\n'
            'Gere gratuitamente em: aistudio.google.com/app/apikey',
      );
    }

    final parts = <String>[];
    if (locationContext != null) parts.add('Localizacao do usuario: $locationContext');
    if (placesContext   != null) parts.add('Locais proximos:\n$placesContext');
    final userMsg = parts.isNotEmpty ? '${parts.join("\n")}\n\nPergunta: $message' : message;

    final contents = <Map<String, dynamic>>[];
    for (final m in (history.length > 10 ? history.sublist(history.length - 10) : history)) {
      if (!m.isLoading && m.content.isNotEmpty) contents.add(m.toGeminiFormat());
    }
    contents.add({'role': 'user', 'parts': [{'text': userMsg}]});

    try {
      final res = await _dio.post(
        '${AppConstants.geminiBaseUrl}/models/${AppConstants.geminiModel}:generateContent',
        queryParameters: {'key': key},
        data: {
          'system_instruction': {'parts': [{'text': _system}]},
          'contents': contents,
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024},
        },
      );

      final candidates = res.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw const GeminiException(message: 'Sem resposta da IA. Tente novamente.');
      }
      final text = candidates.first['content']?['parts']?[0]?['text'] as String?;
      return text ?? 'Nao foi possivel gerar uma resposta.';
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 400 || code == 401 || code == 403) {
        throw const GeminiException(
          message: 'Chave Gemini invalida (401/403).\n'
              'Gere uma nova em: aistudio.google.com/app/apikey\n'
              'A chave deve comecar com "AIza..."',
        );
      }
      if (code == 429) {
        throw const GeminiException(message: 'Limite atingido. Aguarde alguns segundos.');
      }
      throw GeminiException(message: e.message ?? 'Erro ao conectar com a IA.');
    }
  }
}
