// Usa APENAS geolocator — sem import de exceptions proprias para evitar conflito
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class LocationDataSource {
  Future<LatLng> getCurrentLocation();
  Future<String> getAddressFromCoordinates(LatLng location);
  Stream<LatLng> getLocationStream();
}

class LocationDataSourceImpl implements LocationDataSource {
  // Franca - SP (fallback no Chrome)
  static const double _defLat = -20.5386;
  static const double _defLng = -47.4008;

  @override
  Future<LatLng> getCurrentLocation() async {
    if (kIsWeb) {
      try {
        final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 8),
        );
        return LatLng(p.latitude, p.longitude);
      } catch (_) {
        return const LatLng(_defLat, _defLng);
      }
    }

    // Android
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('GPS desativado. Ative nas configuracoes do celular.');
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception('Permissao de localizacao negada.');
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception('Permissao negada permanentemente. Ative em Configuracoes > Tour.');
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
    return LatLng(pos.latitude, pos.longitude);
  }

  @override
  Future<String> getAddressFromCoordinates(LatLng location) async {
    return '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
  }

  @override
  Stream<LatLng> getLocationStream() {
    if (kIsWeb) return Stream.fromFuture(getCurrentLocation());
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map((p) => LatLng(p.latitude, p.longitude));
  }
}
