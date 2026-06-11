import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../entities/route_info.dart';

abstract class LocationRepository {
  Future<LatLng> getCurrentLocation();
  Future<String> getAddressFromCoordinates(LatLng location);
  Stream<LatLng> getLocationStream();
}

abstract class DirectionsRepository {
  Future<RouteInfo> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode,
  });
}
