import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteInfo {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;

  const RouteInfo({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
  });
}
