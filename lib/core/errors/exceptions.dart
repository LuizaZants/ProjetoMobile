// Nomes proprios para evitar conflito com geolocator_platform_interface
abstract class AppException implements Exception {
  final String message;
  const AppException({required this.message});
  @override
  String toString() => message;
}

class NetworkException   extends AppException { const NetworkException({required super.message}); }
class PlacesException    extends AppException { const PlacesException({required super.message}); }
class DirectionsException extends AppException { const DirectionsException({required super.message}); }
class GeminiException    extends AppException { const GeminiException({required super.message}); }
