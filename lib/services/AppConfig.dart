// lib/services/AppConfig.dart

import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  static Map<String, dynamic> _config = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final jsonStr = await rootBundle.loadString('config.json');
    _config = jsonDecode(jsonStr);
    _loaded = true;
  }

  // Chave Google: usada para Places (New), Directions e Maps SDK
  static String get googlePlacesKey => _config['GOOGLE_PLACES_KEY'] ?? '';
  static String get googleMapsKey   => _config['GOOGLE_PLACES_KEY'] ?? '';

  static String get geminiApiKey => _config['GEMINI_API_KEY'] ?? '';
}
