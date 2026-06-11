// lib/services/DirectionsService.dart
// Google Directions API — desenha rota nativa no mapa (sem abrir app externo)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'AppConfig.dart';

class RotaInfo {
  final List<LatLng> pontos;
  final String distancia;
  final String duracao;

  const RotaInfo({
    required this.pontos,
    required this.distancia,
    required this.duracao,
  });
}

class DirectionsService {
  static String get _apiKey => AppConfig.googleMapsKey;

  static Future<RotaInfo> calcularRota({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String modo = 'walking', // walking | driving | bicycling | transit
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=$originLat,$originLng'
      '&destination=$destLat,$destLng'
      '&mode=$modo'
      '&language=pt-BR'
      '&key=$_apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Erro ao calcular rota (${response.statusCode})';
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String?;

    if (status == 'ZERO_RESULTS') {
      throw 'Nenhuma rota encontrada para este destino.';
    }
    if (status == 'REQUEST_DENIED') {
      throw 'API Key sem permissão para Directions. Ative a Directions API no Google Cloud.';
    }
    if (status != 'OK') {
      throw 'Erro Directions API: $status';
    }

    final routes = data['routes'] as List;
    if (routes.isEmpty) throw 'Nenhuma rota retornada.';

    final route  = routes.first as Map<String, dynamic>;
    final leg    = (route['legs'] as List).first as Map<String, dynamic>;
    final polylineEncoded =
        (route['overview_polyline'] as Map)['points'] as String;

    final pontos = PolylinePoints()
        .decodePolyline(polylineEncoded)
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return RotaInfo(
      pontos:    pontos,
      distancia: (leg['distance'] as Map)['text'] as String? ?? '',
      duracao:   (leg['duration'] as Map)['text'] as String? ?? '',
    );
  }
}
