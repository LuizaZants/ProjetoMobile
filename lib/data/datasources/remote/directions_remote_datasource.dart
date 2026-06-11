import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/route_model.dart';

abstract class DirectionsRemoteDataSource {
  Future<RouteModel> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode,
  });
}

class DirectionsRemoteDataSourceImpl implements DirectionsRemoteDataSource {
  final Dio _dio = DioClient.instance;

  @override
  Future<RouteModel> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'walking',
  }) async {
    // Chrome: CORS bloqueia a API — abre no Google Maps e retorna modelo vazio
    if (kIsWeb) {
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&travelmode=$travelMode',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return RouteModel(
        polylinePoints: [origin, destination],
        distance: 'Ver no Google Maps',
        duration: 'Ver no Google Maps',
      );
    }

    // Android: polyline nativa
    try {
      final res = await _dio.get(
        '${AppConstants.googleDirectionsBaseUrl}/json',
        queryParameters: {
          'origin':      '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode':        travelMode,
          'key':         AppConstants.googleDirectionsApiKey,
          'language':    'pt-BR',
        },
      );

      final data   = res.data as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status == 'ZERO_RESULTS' || status == 'NOT_FOUND') {
        throw const DirectionsException(message: 'Nenhuma rota encontrada para este destino.');
      }
      if (status == 'REQUEST_DENIED') {
        throw const DirectionsException(message: 'Directions API nao habilitada na chave Google.');
      }

      return RouteModel.fromJson(data);
    } on DioException catch (e) {
      throw DirectionsException(message: e.message ?? 'Erro ao calcular rota');
    }
  }
}
