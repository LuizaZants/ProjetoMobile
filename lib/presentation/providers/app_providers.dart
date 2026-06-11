import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/datasources/remote/places_remote_datasource.dart';
import '../../data/datasources/remote/directions_remote_datasource.dart';
import '../../data/datasources/remote/location_datasource.dart';
import '../../data/datasources/remote/gemini_datasource.dart';
import '../../data/repositories/repositories_impl.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/route_info.dart';
import '../../core/constants/place_categories.dart';

// IMPORT DO SEU NOVO SERVIÇO DE PLACES (API NEW)
import '../../services/PlaceService.dart';

// ── DataSources ───────────────────────────────────────────────────────────────
final _placesDS     = Provider((_) => PlacesRemoteDataSourceImpl());
final _directionsDS = Provider((_) => DirectionsRemoteDataSourceImpl());
final _locationDS   = Provider((_) => LocationDataSourceImpl());
final _geminiDS     = Provider((_) => GeminiDataSourceImpl());

// ── Repositories ──────────────────────────────────────────────────────────────
final _placesRepo     = Provider((ref) => PlacesRepositoryImpl(ref.read(_placesDS)));
final _directionsRepo = Provider((ref) => DirectionsRepositoryImpl(ref.read(_directionsDS)));
final _locationRepo   = Provider((ref) => LocationRepositoryImpl(ref.read(_locationDS)));
final _geminiRepo     = Provider((ref) => GeminiRepositoryImpl(ref.read(_geminiDS)));

// ── Selected place ────────────────────────────────────────────────────────────
final selectedPlaceProvider = StateProvider<Place?>((_) => null);

// ── Photo URL helper ──────────────────────────────────────────────────────────
// Ajustado para apontar para o novo GooglePlacesService (Places API New)
final photoUrlProvider = Provider((ref) {
  return (String photoName) => GooglePlacesService.fotoUrl(photoName);
});

// ═════════════════════════════════════════════════════════════════════════════
// LOCATION STATE
// ═════════════════════════════════════════════════════════════════════════════
class LocationState {
  final LatLng? currentLocation;
  final String? currentAddress;
  final bool isLoading;
  final String? error;

  const LocationState({
    this.currentLocation, this.currentAddress,
    this.isLoading = false, this.error,
  });

  LocationState copyWith({LatLng? currentLocation, String? currentAddress,
      bool? isLoading, String? error}) =>
      LocationState(
        currentLocation: currentLocation ?? this.currentLocation,
        currentAddress:  currentAddress  ?? this.currentAddress,
        isLoading:       isLoading       ?? this.isLoading,
        error: error,
      );
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationRepositoryImpl _repo;
  LocationNotifier(this._repo) : super(const LocationState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final loc  = await _repo.getCurrentLocation();
      final addr = await _repo.getAddressFromCoordinates(loc);
      state = state.copyWith(currentLocation: loc, currentAddress: addr, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final locationNotifierProvider =
    StateNotifierProvider<LocationNotifier, LocationState>(
        (ref) => LocationNotifier(ref.read(_locationRepo)));

// ═════════════════════════════════════════════════════════════════════════════
// PLACES STATE
// ═════════════════════════════════════════════════════════════════════════════
class PlacesState {
  final List<Place> places;
  final bool isLoading;
  final String? error;
  final PlaceCategory? activeCategory;

  const PlacesState({
    this.places = const [], this.isLoading = false,
    this.error, this.activeCategory,
  });

  PlacesState copyWith({List<Place>? places, bool? isLoading,
      String? error, PlaceCategory? activeCategory}) =>
      PlacesState(
        places:         places         ?? this.places,
        isLoading:      isLoading      ?? this.isLoading,
        error:          error,
        activeCategory: activeCategory ?? this.activeCategory,
      );
}

class PlacesNotifier extends StateNotifier<PlacesState> {
  final PlacesRepositoryImpl _repo;
  PlacesNotifier(this._repo) : super(const PlacesState());

  Future<void> loadNearby({required LatLng location, required PlaceCategory category}) async {
    state = state.copyWith(isLoading: true, error: null, activeCategory: category);
    try {
      final places = await _repo.getNearbyPlaces(location: location, category: category);
      state = state.copyWith(places: places, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search({required LatLng location, required String query}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final places = await _repo.searchPlaces(location: location, query: query);
      state = state.copyWith(places: places, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() => state = const PlacesState();
}

final placesNotifierProvider =
    StateNotifierProvider<PlacesNotifier, PlacesState>(
        (ref) => PlacesNotifier(ref.read(_placesRepo)));

// ═════════════════════════════════════════════════════════════════════════════
// ROUTE STATE
// ═════════════════════════════════════════════════════════════════════════════
class RouteState {
  final RouteInfo? route;
  final bool isLoading;
  final String? error;
  final String travelMode;

  const RouteState({this.route, this.isLoading = false, this.error, this.travelMode = 'walking'});

  RouteState copyWith({RouteInfo? route, bool? isLoading, String? error, String? travelMode}) =>
      RouteState(
        route:       route       ?? this.route,
        isLoading:   isLoading   ?? this.isLoading,
        error:       error,
        travelMode:  travelMode  ?? this.travelMode,
      );
}

class RouteNotifier extends StateNotifier<RouteState> {
  final DirectionsRepositoryImpl _repo;
  RouteNotifier(this._repo) : super(const RouteState());

  Future<void> calculate({
    required LatLng origin,
    required LatLng destination,
    String mode = 'walking',
  }) async {
    state = state.copyWith(isLoading: true, error: null, travelMode: mode);
    try {
      final route = await _repo.getDirections(
          origin: origin, destination: destination, travelMode: mode);
      state = state.copyWith(route: route, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() => state = const RouteState();
}

final routeNotifierProvider =
    StateNotifierProvider<RouteNotifier, RouteState>(
        (ref) => RouteNotifier(ref.read(_directionsRepo)));

// ═════════════════════════════════════════════════════════════════════════════
// CHAT STATE
// ═════════════════════════════════════════════════════════════════════════════
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({this.messages = const [], this.isLoading = false, this.error});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading, String? error}) =>
      ChatState(
        messages:  messages  ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error:     error,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final GeminiRepositoryImpl _repo;
  ChatNotifier(this._repo) : super(const ChatState());

  Future<void> send(String text, {String? locationContext, String? placesContext}) async {
    final userMsg    = ChatMessage(content: text,  role: MessageRole.user);
    final loadingMsg = ChatMessage(content: '',    role: MessageRole.assistant, isLoading: true);

    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isLoading: true, error: null,
    );

    try {
      final history = state.messages
          .where((m) => !m.isLoading && m.content.isNotEmpty)
          .toList();

      final reply = await _repo.sendMessage(
        history: history,
        message: text,
        locationContext: locationContext,
        placesContext: placesContext,
      );

      final aiMsg = ChatMessage(content: reply, role: MessageRole.assistant);
      final msgs   = state.messages.where((m) => !m.isLoading).toList()..add(aiMsg);
      state = state.copyWith(messages: msgs, isLoading: false);
    } catch (e) {
      final errMsg = ChatMessage(content: e.toString(), role: MessageRole.assistant);
      final msgs   = state.messages.where((m) => !m.isLoading).toList()..add(errMsg);
      state = state.copyWith(messages: msgs, isLoading: false, error: e.toString());
    }
  }

  void clearChat() => state = const ChatState();
}

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>(
        (ref) => ChatNotifier(ref.read(_geminiRepo)));