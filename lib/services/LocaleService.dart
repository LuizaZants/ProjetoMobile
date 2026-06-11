// lib/services/LocaleService.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

class GeolocalizacaoService {
  // Localização padrão usada no Chrome/Web quando GPS não está disponível
  // Troque para a cidade que quiser testar
  static const double _defaultLat = -23.5505;  // São Paulo
  static const double _defaultLng = -46.6333;

  static Future<Position> pegarPosicaoAtual() async {
    // No Chrome/Web, tenta usar geolocation do navegador
    // Se falhar, usa localização padrão para demo
    if (kIsWeb) {
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        // Retorna São Paulo como fallback para demo no Chrome
        return _posicaoPadrao();
      }
    }

    // Mobile (Android/iOS) — fluxo normal com permissão
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      throw 'O GPS do seu aparelho está desativado. Ative-o nas configurações.';
    }

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        throw 'Permissão de GPS negada. Por favor, permita o acesso à localização.';
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      throw 'Permissão de GPS negada permanentemente. Ative nas Configurações > Tour.';
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  static Position _posicaoPadrao() {
    return Position(
      latitude: _defaultLat,
      longitude: _defaultLng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  static double calcularDistancia(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
