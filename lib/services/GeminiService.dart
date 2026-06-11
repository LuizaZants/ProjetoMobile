// lib/services/GeminiService.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'AppConfig.dart';

class GeminiService {
  static String get _apiKey => AppConfig.geminiApiKey;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // ── Enriquecer lugar com dados da IA ─────────────────────────────────────
  static Future<Map<String, dynamic>> enriquecerLugar(
    String nomeLugar,
    String endereco,
    String categoriaApp,
  ) async {
    final prompt = '''
Você é um guia turístico especialista. Baseado no local "$nomeLugar" em "$endereco",
retorne APENAS um objeto JSON puro sem markdown (sem ```json) com exatamente:
{
  "categoria": "$categoriaApp",
  "tempoMinutos": (número inteiro estimado de visita),
  "descricao": "resumo amigável em até 2 frases sobre o local",
  "endereco": "endereço simplificado e corrigido"
}
Responda SOMENTE o JSON.
''';

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 300},
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String texto =
            data['candidates'][0]['content']['parts'][0]['text'] ?? '';
        texto = texto
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        return jsonDecode(texto);
      }
    } catch (e) {
      // fallback abaixo
    }

    return {
      'categoria':    categoriaApp,
      'tempoMinutos': 60,
      'descricao':    'Local em $endereco. Visita recomendada.',
      'endereco':     endereco,
    };
  }

  // ── Chat com contexto de geolocalização ──────────────────────────────────
  static Future<String> perguntarSobreLugar({
    required double userLat,
    required double userLng,
    required String categoriaEscolhida,
    required String nomeLugar,
    required String distancia,
    required double rating,
    required String pergunta,
    List<Map<String, String>> historicoChat = const [],
    int tentativa = 0,
  }) async {
    final systemPrompt =
        'Você é um assistente virtual de exploração local.\n'
        'O usuário está na coordenada [$userLat, $userLng] buscando por $categoriaEscolhida.\n'
        'Ele selecionou "$nomeLugar", que fica a $distancia e tem nota ${rating.toStringAsFixed(1)}.\n'
        'Responda de forma amigável, útil e concisa em português brasileiro.\n'
        'Mencione fatos relevantes sobre o local quando pertinente.\n'
        'Se não tiver certeza de um dado, diga claramente que não tem essa informação.';

    final List<Map<String, dynamic>> contents = [];
    contents.add({
      'role': 'user',
      'parts': [
        {'text': systemPrompt}
      ]
    });
    contents.add({
      'role': 'model',
      'parts': [
        {'text': 'Entendido! Estou pronto para ajudar com informações sobre "$nomeLugar".'}
      ]
    });

    for (final msg in historicoChat) {
      contents.add({
        'role': msg['role'] == 'user' ? 'user' : 'model',
        'parts': [
          {'text': msg['text'] ?? ''}
        ]
      });
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': pergunta}
      ]
    });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 600,
          },
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ??
            'Sem resposta.';
      } else if (res.statusCode == 429 && tentativa < 3) {
        await Future.delayed(Duration(seconds: (tentativa + 1) * 3));
        return await perguntarSobreLugar(
          userLat: userLat,
          userLng: userLng,
          categoriaEscolhida: categoriaEscolhida,
          nomeLugar: nomeLugar,
          distancia: distancia,
          rating: rating,
          pergunta: pergunta,
          historicoChat: historicoChat,
          tentativa: tentativa + 1,
        );
      } else if (res.statusCode == 429) {
        return 'A IA está sobrecarregada no momento. Aguarde alguns segundos e tente novamente.';
      } else {
        return 'Erro ao consultar a IA (${res.statusCode}). Tente novamente.';
      }
    } catch (e) {
      return 'Não foi possível conectar à IA: $e';
    }
  }
}
