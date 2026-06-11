import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../entities/place.dart';
import '../../core/constants/place_categories.dart';

abstract class PlacesRepository {
  Future<List<Place>> getNearbyPlaces({required LatLng location, required PlaceCategory category});
  Future<List<Place>> searchPlaces({required LatLng location, required String query});
  String getPhotoUrl(String photoRef, {int maxWidth = 600});
}
