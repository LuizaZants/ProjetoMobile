// lib/services/PlaceService.dart
// Usa Places API (New) — mesmo endpoint do projeto base original

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'AppConfig.dart';

class GooglePlacesService {
  static String get _apiKey => AppConfig.googlePlacesKey;

  // Mapa de categorias → query para Places API (New)
  static const Map<String, String> _categoriaParaQuery = {
    'Gastronomia':       'restaurantes e lanchonetes',
    'Cultura':           'museus e centros culturais',
    'Lazer':             'parques e entretenimento',
    'Natureza':          'parques naturais e áreas verdes',
    'Pontos Turísticos': 'pontos turísticos e atrações',
    'Bares':             'bares e pubs',
    'Entretenimento':    'cinema teatro entretenimento',
  };

  // ── Buscar locais próximos (Places API New — searchText) ──────────────────
  static Future<List<Map<String, dynamic>>> buscarLugaresProximos(
    double lat,
    double lng,
    String categoria,
  ) async {
    final query = _categoriaParaQuery[categoria] ?? categoria;
    final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,'
              'places.location,places.rating,places.photos,'
              'places.userRatingCount,places.regularOpeningHours,'
              'places.internationalPhoneNumber,places.websiteUri',
        },
        body: jsonEncode({
          'textQuery': query,
          'languageCode': 'pt-BR',
          'locationBias': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': 5000.0,
            },
          },
          'maxResultCount': 10,
        }),
      );

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        final List lugares = dados['places'] ?? [];

        return lugares.map<Map<String, dynamic>>((lugar) {
          final double lugarLat =
              (lugar['location']?['latitude'] ?? lat).toDouble();
          final double lugarLng =
              (lugar['location']?['longitude'] ?? lng).toDouble();
          final double distancia =
              _calcularDistancia(lat, lng, lugarLat, lugarLng);

          // Foto — Places API (New) usa campo 'name' dentro de photos
          String? photoName;
          final fotos = lugar['photos'] as List?;
          if (fotos != null && fotos.isNotEmpty) {
            photoName = fotos[0]['name'] as String?;
          }

          // Aberto agora
          final openingHours =
              lugar['regularOpeningHours'] as Map<String, dynamic>?;
          final isOpen = openingHours?['openNow'] as bool?;
          final weekdayDescriptions =
              (openingHours?['weekdayDescriptions'] as List?)
                  ?.map((e) => e.toString())
                  .toList();

          return {
            'placeId':      lugar['id'] ?? '',
            'nome':         lugar['displayName']?['text'] ?? '',
            'endereco':     lugar['formattedAddress'] ?? '',
            'latitude':     lugarLat,
            'longitude':    lugarLng,
            'rating':       (lugar['rating'] ?? 0.0).toDouble(),
            'totalAvaliacoes': lugar['userRatingCount'] ?? 0,
            'distanciaMetros': distancia,
            'photoName':    photoName,
            'telefone':     lugar['internationalPhoneNumber'],
            'website':      lugar['websiteUri'],
            'aberto':       isOpen,
            'horarios':     weekdayDescriptions,
          };
        }).toList()
          ..sort((a, b) =>
              (a['distanciaMetros'] as double)
                  .compareTo(b['distanciaMetros'] as double));
      } else {
        throw 'Erro Google Places (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      throw 'Falha ao conectar no Google Places: $e';
    }
  }

  // ── URL da foto (Places API New) ─────────────────────────────────────────
  static String fotoUrl(String photoName) {
    return 'https://places.googleapis.com/v1/$photoName/media'
        '?maxHeightPx=600&maxWidthPx=600&key=$_apiKey';
  }

  // ── Haversine ────────────────────────────────────────────────────────────
  static double _calcularDistancia(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;
}
