import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/place_categories.dart';

class Place {
  final String id;
  final String name;
  final String? address;
  final LatLng location;
  final double? rating;
  final int? userRatingsTotal;
  final String? phoneNumber;
  final bool? isOpen;
  final List<String>? weekdayText;
  final List<String>? photoReferences;
  final double? priceLevel;
  final String? website;
  final PlaceCategory? category;
  double? distanceInMeters;

  Place({
    required this.id,
    required this.name,
    this.address,
    required this.location,
    this.rating,
    this.userRatingsTotal,
    this.phoneNumber,
    this.isOpen,
    this.weekdayText,
    this.photoReferences,
    this.priceLevel,
    this.website,
    this.category,
    this.distanceInMeters,
  });

  String get formattedDistance {
    if (distanceInMeters == null) return '';
    if (distanceInMeters! < 1000) return '${distanceInMeters!.toInt()}m';
    return '${(distanceInMeters! / 1000).toStringAsFixed(1)}km';
  }

  String get formattedRating => rating?.toStringAsFixed(1) ?? 'N/A';

  String? get firstPhoto =>
      (photoReferences != null && photoReferences!.isNotEmpty)
          ? photoReferences!.first
          : null;
}
