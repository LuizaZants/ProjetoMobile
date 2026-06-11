import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../domain/entities/route_info.dart';

class RouteModel extends RouteInfo {
  RouteModel({
    required super.polylinePoints,
    required super.distance,
    required super.duration,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final routes = json['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) throw Exception('Nenhuma rota encontrada');

    final route  = routes.first as Map<String, dynamic>;
    final leg    = ((route['legs'] as List?)?.first) as Map<String, dynamic>?;
    final poly   = (route['overview_polyline'] as Map?)?['points'] as String? ?? '';

    final points = PolylinePoints()
        .decodePolyline(poly)
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return RouteModel(
      polylinePoints: points,
      distance: (leg?['distance'] as Map?)?['text'] as String? ?? '',
      duration: (leg?['duration'] as Map?)?['text'] as String? ?? '',
    );
  }
}
