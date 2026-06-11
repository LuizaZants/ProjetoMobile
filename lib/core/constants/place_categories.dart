import 'package:flutter/material.dart';

enum PlaceCategory {
  gastronomia('Gastronomia', Icons.restaurant_rounded, Color(0xFFFF6B35), 'restaurantes e lanchonetes'),
  cultura('Cultura', Icons.museum_rounded, Color(0xFF6C63FF), 'museus e centros culturais'),
  lazer('Lazer', Icons.park_rounded, Color(0xFF2DB77B), 'parques e entretenimento'),
  bares('Bares', Icons.local_bar_rounded, Color(0xFFF7C948), 'bares e pubs'),
  turismo('Turismo', Icons.photo_camera_rounded, Color(0xFF00B4D8), 'pontos turisticos e atracoes'),
  entretenimento('Entretenimento', Icons.theater_comedy_rounded, Color(0xFFE040FB), 'cinema teatro entretenimento');

  final String label;
  final IconData icon;
  final Color color;
  final String searchQuery;

  const PlaceCategory(this.label, this.icon, this.color, this.searchQuery);
}

extension PlaceCategoryExtension on PlaceCategory {
  String get label {
    switch (this) {
      case PlaceCategory.gastronomia:    return 'Gastronomia';
      case PlaceCategory.cultura:        return 'Cultura';
      case PlaceCategory.lazer:          return 'Lazer';
      case PlaceCategory.bares:          return 'Bares';
      case PlaceCategory.turismo:        return 'Turismo';
      case PlaceCategory.entretenimento: return 'Entretenimento';
    }
  }

  IconData get icon {
    switch (this) {
      case PlaceCategory.gastronomia:    return Icons.restaurant_rounded;
      case PlaceCategory.cultura:        return Icons.museum_rounded;
      case PlaceCategory.lazer:          return Icons.park_rounded;
      case PlaceCategory.bares:          return Icons.local_bar_rounded;
      case PlaceCategory.turismo:        return Icons.photo_camera_rounded;
      case PlaceCategory.entretenimento: return Icons.theater_comedy_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PlaceCategory.gastronomia:    return const Color(0xFFFF6B35);
      case PlaceCategory.cultura:        return const Color(0xFF6C63FF);
      case PlaceCategory.lazer:          return const Color(0xFF2DB77B);
      case PlaceCategory.bares:          return const Color(0xFFF7C948);
      case PlaceCategory.turismo:        return const Color(0xFF00B4D8);
      case PlaceCategory.entretenimento: return const Color(0xFFE040FB);
    }
  }

  String get searchQuery {
    switch (this) {
      case PlaceCategory.gastronomia:    return 'restaurantes e lanchonetes';
      case PlaceCategory.cultura:        return 'museus e centros culturais';
      case PlaceCategory.lazer:          return 'parques e entretenimento';
      case PlaceCategory.bares:          return 'bares e pubs';
      case PlaceCategory.turismo:        return 'pontos turisticos e atracoes';
      case PlaceCategory.entretenimento: return 'cinema teatro entretenimento';
    }
  }
}
