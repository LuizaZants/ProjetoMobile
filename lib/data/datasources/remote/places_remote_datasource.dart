import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/place_categories.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/place_model.dart';

abstract class PlacesRemoteDataSource {
  Future<List<PlaceModel>> getNearbyPlaces({required LatLng location, required PlaceCategory category});
  Future<List<PlaceModel>> searchPlaces({required LatLng location, required String query});
  String getPhotoUrl(String photoRef, {int maxWidth = 600});
}

class PlacesRemoteDataSourceImpl implements PlacesRemoteDataSource {
  final Dio _dio = DioClient.instance;

  static const String _url = 'https://places.googleapis.com/v1/places:searchText';
  static const String _fields =
      'places.id,places.displayName,places.formattedAddress,'
      'places.location,places.rating,places.photos,'
      'places.userRatingCount,places.regularOpeningHours,'
      'places.internationalPhoneNumber,places.websiteUri,places.priceLevel';

  Future<List<PlaceModel>> _search(
      String query, LatLng location, PlaceCategory? category) async {
    try {
      final res = await _dio.post(
        _url,
        options: Options(headers: {
          'X-Goog-Api-Key': AppConstants.googlePlacesApiKey,
          'X-Goog-FieldMask': _fields,
          'Content-Type': 'application/json',
        }),
        data: {
          'textQuery': query,
          'languageCode': 'pt-BR',
          'locationBias': {
            'circle': {
              'center': {'latitude': location.latitude, 'longitude': location.longitude},
              'radius': AppConstants.defaultRadius,
            },
          },
          'maxResultCount': 20,
        },
      );

      final list = (res.data['places'] as List? ?? []);
      return list.map((j) {
        final m = PlaceModel.fromPlacesNewJson(j as Map<String, dynamic>, category);
        m.distanceInMeters = PlaceModel.calcDistance(
          location.latitude, location.longitude,
          m.location.latitude, m.location.longitude,
        );
        return m;
      }).toList()
        ..sort((a, b) => (a.distanceInMeters ?? 0).compareTo(b.distanceInMeters ?? 0));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 400 || code == 403) {
        throw const PlacesException(message: 'Chave Google Places invalida ou sem permissao.');
      }
      throw PlacesException(message: e.message ?? 'Erro ao buscar locais');
    }
  }

  @override
  Future<List<PlaceModel>> getNearbyPlaces({
    required LatLng location,
    required PlaceCategory category,
  }) =>
      _search(category.searchQuery, location, category);

  @override
  Future<List<PlaceModel>> searchPlaces({
    required LatLng location,
    required String query,
  }) =>
      _search(query, location, null);

  @override
  String getPhotoUrl(String photoRef, {int maxWidth = 600}) =>
      'https://places.googleapis.com/v1/$photoRef/media'
      '?maxHeightPx=$maxWidth&maxWidthPx=$maxWidth'
      '&key=${AppConstants.googlePlacesApiKey}';
}
