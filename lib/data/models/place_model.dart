import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/place.dart';
import '../../core/constants/place_categories.dart';

class PlaceModel extends Place {
  PlaceModel({
    required super.id,
    required super.name,
    super.address,
    required super.location,
    super.rating,
    super.userRatingsTotal,
    super.phoneNumber,
    super.isOpen,
    super.weekdayText,
    super.photoReferences,
    super.priceLevel,
    super.website,
    super.category,
    super.distanceInMeters,
  });

  factory PlaceModel.fromPlacesNewJson(
      Map<String, dynamic> json, PlaceCategory? category) {
    final loc         = json['location'] as Map<String, dynamic>?;
    final displayName = json['displayName'] as Map<String, dynamic>?;
    final photos      = json['photos'] as List<dynamic>?;
    final opening     = json['regularOpeningHours'] as Map<String, dynamic>?;

    final photoRefs = photos
        ?.map((p) => (p['name'] as String?) ?? '')
        .where((r) => r.isNotEmpty)
        .toList();

    final weekdays = (opening?['weekdayDescriptions'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();

    // Função interna auxiliar para tratar o priceLevel dinamicamente
    double? parsePriceLevel(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      
      // Caso venha como a nova String da API do Google Places New
      switch (value.toString()) {
        case 'PRICE_LEVEL_INEXPENSIVE': return 1.0;
        case 'PRICE_LEVEL_MODERATE':    return 2.0;
        case 'PRICE_LEVEL_EXPENSIVE':   return 3.0;
        case 'PRICE_LEVEL_VERY_EXPENSIVE': return 4.0;
        default: return null;
      }
    }

    return PlaceModel(
      id:               json['id'] as String? ?? '',
      name:             displayName?['text'] as String? ?? 'Local desconhecido',
      address:          json['formattedAddress'] as String?,
      location: LatLng(
        (loc?['latitude']  as num?)?.toDouble() ?? 0,
        (loc?['longitude'] as num?)?.toDouble() ?? 0,
      ),
      rating:           (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['userRatingCount'] as int?,
      phoneNumber:      json['internationalPhoneNumber'] as String?,
      isOpen:           opening?['openNow'] as bool?,
      weekdayText:      weekdays,
      photoReferences:  photoRefs,
      priceLevel:       parsePriceLevel(json['priceLevel']), // 👈 Substituído pela nossa função inteligente
      website:          json['websiteUri'] as String?,
      category:         category,
    );
  }

  static double calcDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;
}