import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/places_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/gemini_repository.dart';
import '../../core/constants/place_categories.dart';
import '../datasources/remote/places_remote_datasource.dart';
import '../datasources/remote/directions_remote_datasource.dart';
import '../datasources/remote/location_datasource.dart';
import '../datasources/remote/gemini_datasource.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  final PlacesRemoteDataSource _ds;
  PlacesRepositoryImpl(this._ds);

  @override
  Future<List<Place>> getNearbyPlaces({required LatLng location, required PlaceCategory category}) =>
      _ds.getNearbyPlaces(location: location, category: category);

  @override
  Future<List<Place>> searchPlaces({required LatLng location, required String query}) =>
      _ds.searchPlaces(location: location, query: query);

  @override
  String getPhotoUrl(String photoRef, {int maxWidth = 600}) =>
      _ds.getPhotoUrl(photoRef, maxWidth: maxWidth);
}

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource _ds;
  LocationRepositoryImpl(this._ds);

  @override Future<LatLng> getCurrentLocation() => _ds.getCurrentLocation();
  @override Future<String> getAddressFromCoordinates(LatLng l) => _ds.getAddressFromCoordinates(l);
  @override Stream<LatLng> getLocationStream() => _ds.getLocationStream();
}

class DirectionsRepositoryImpl implements DirectionsRepository {
  final DirectionsRemoteDataSource _ds;
  DirectionsRepositoryImpl(this._ds);

  @override
  Future<RouteInfo> getDirections({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'walking',
  }) =>
      _ds.getDirections(origin: origin, destination: destination, travelMode: travelMode);
}

class GeminiRepositoryImpl implements GeminiRepository {
  final GeminiDataSource _ds;
  GeminiRepositoryImpl(this._ds);

  @override
  Future<String> sendMessage({
    required List<ChatMessage> history,
    required String message,
    String? locationContext,
    String? placesContext,
  }) =>
      _ds.sendMessage(history: history, message: message,
          locationContext: locationContext, placesContext: placesContext);
}
