import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Tour';

  static String get googleMapsApiKey       => dotenv.env['GOOGLE_PLACES_KEY'] ?? '';
  static String get googlePlacesApiKey     => dotenv.env['GOOGLE_PLACES_KEY'] ?? '';
  static String get googleDirectionsApiKey => dotenv.env['GOOGLE_PLACES_KEY'] ?? '';
  static String get geminiApiKey           => dotenv.env['GEMINI_API_KEY'] ?? '';

  static const String googleDirectionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiModel = 'gemini-2.5-flash';

  static const double defaultZoom   = 14.0;
  static const double defaultRadius = 5000.0;

  static const int connectionTimeout = 30000;
  static const int receiveTimeout    = 30000;
}
