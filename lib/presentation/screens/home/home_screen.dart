import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/place_categories.dart';
import '../../../domain/entities/place.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/category_chip.dart';
import '../../widgets/place/place_bottom_sheet.dart';
import '../results/results_screen.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Completer<GoogleMapController> _mapCtrl = Completer();
  PlaceCategory _selectedCat = PlaceCategory.gastronomia;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        ref.read(locationNotifierProvider.notifier).load());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _animateTo(LatLng loc) async {
    if (_mapCtrl.isCompleted) {
      (await _mapCtrl.future).animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: loc, zoom: AppConstants.defaultZoom)));
    }
  }

  void _onCategory(PlaceCategory cat) {
    setState(() => _selectedCat = cat);
    final loc = ref.read(locationNotifierProvider).currentLocation;
    if (loc != null) ref.read(placesNotifierProvider.notifier).loadNearby(location: loc, category: cat);
  }

  void _onSearch(String q) {
    if (q.trim().isEmpty) return;
    final loc = ref.read(locationNotifierProvider).currentLocation;
    if (loc != null) {
      ref.read(placesNotifierProvider.notifier).search(location: loc, query: q);
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => ResultsScreen(category: _selectedCat, searchQuery: q)));
    }
  }

  Set<Marker> _markers(List<Place> places, LatLng? user) {
    final m = <Marker>{};
    if (user != null) {
      m.add(Marker(
        markerId: const MarkerId('user'),
        position: user,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Voce esta aqui'),
      ));
    }
    for (final p in places.take(20)) {
      m.add(Marker(
        markerId: MarkerId(p.id),
        position: p.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(_hue(p.category)),
        infoWindow: InfoWindow(title: p.name, snippet: p.formattedDistance),
        onTap: () => _showSheet(p),
      ));
    }
    return m;
  }

  double _hue(PlaceCategory? cat) {
    switch (cat) {
      case PlaceCategory.gastronomia:    return BitmapDescriptor.hueOrange;
      case PlaceCategory.cultura:        return BitmapDescriptor.hueViolet;
      case PlaceCategory.lazer:          return BitmapDescriptor.hueGreen;
      case PlaceCategory.bares:          return BitmapDescriptor.hueYellow;
      case PlaceCategory.turismo:        return BitmapDescriptor.hueCyan;
      case PlaceCategory.entretenimento: return BitmapDescriptor.hueRose;
      default:                           return BitmapDescriptor.hueRed;
    }
  }

  void _showSheet(Place p) {
    ref.read(selectedPlaceProvider.notifier).state = p;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceBottomSheet(place: p),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locState    = ref.watch(locationNotifierProvider);
    final placesState = ref.watch(placesNotifierProvider);

    ref.listen(locationNotifierProvider, (prev, next) {
      if (next.currentLocation != null && prev?.currentLocation == null) {
        _animateTo(next.currentLocation!);
        ref.read(placesNotifierProvider.notifier)
            .loadNearby(location: next.currentLocation!, category: _selectedCat);
      }
    });

    return Scaffold(
      body: Stack(children: [
        // Mapa
        GoogleMap(
          onMapCreated: (c) => _mapCtrl.complete(c),
          initialCameraPosition: CameraPosition(
            target: locState.currentLocation ?? const LatLng(-20.5386, -47.4008),
            zoom: AppConstants.defaultZoom,
          ),
          markers: _markers(placesState.places, locState.currentLocation),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
        ),

        // UI overlay
        SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(children: [
              Expanded(child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showSearch ? _searchField() : _headerCard(locState),
              )),
              const SizedBox(width: 10),
              _circleBtn(Icons.smart_toy_rounded, AppTheme.primary, () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
            ]),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: PlaceCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = PlaceCategory.values[i];
                return CategoryChip(
                  category: cat,
                  isSelected: _selectedCat == cat,
                  onTap: () => _onCategory(cat),
                );
              },
            ),
          ),
        ])),

        // Loading
        if (locState.isLoading)
          Positioned(top: 140, left: 0, right: 0,
              child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppTheme.shadow, blurRadius: 12)]),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                  SizedBox(width: 10),
                  Text('Obtendo localizacao...'),
                ]),
              ))),

        // Error
        if (locState.error != null)
          Positioned(top: 140, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                ),
                child: Text(locState.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.error)),
              )),

        // Bottom controls
        Positioned(bottom: 0, left: 0, right: 0,
            child: SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _circleBtn(Icons.my_location_rounded, AppTheme.primary, () {
                  if (locState.currentLocation != null) _animateTo(locState.currentLocation!);
                  else ref.read(locationNotifierProvider.notifier).load();
                }),
                _listBtn(placesState),
              ]),
            ))),
      ]),
    );
  }

  Widget _headerCard(LocationState s) => GestureDetector(
        key: const ValueKey('header'),
        onTap: () => setState(() => _showSearch = true),
        child: Container(
          height: 50,
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppTheme.shadow, blurRadius: 16, offset: const Offset(0, 4))]),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            const Icon(Icons.search, color: AppTheme.textHint, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(
              s.currentAddress ?? 'Buscando localizacao...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: s.currentAddress != null ? AppTheme.textPrimary : AppTheme.textHint),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
      );

  Widget _searchField() => Container(
        key: const ValueKey('search'),
        height: 50,
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppTheme.shadow, blurRadius: 16, offset: const Offset(0, 4))]),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back, size: 18),
              onPressed: () { setState(() => _showSearch = false); _searchCtrl.clear(); }),
          Expanded(child: TextField(
            controller: _searchCtrl, autofocus: true,
            decoration: const InputDecoration(hintText: 'Buscar locais...',
                border: InputBorder.none, enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none, fillColor: Colors.transparent,
                filled: true, contentPadding: EdgeInsets.zero),
            onSubmitted: _onSearch,
          )),
          IconButton(icon: const Icon(Icons.search, color: AppTheme.primary),
              onPressed: () => _onSearch(_searchCtrl.text)),
        ]),
      );

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppTheme.shadow, blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      );

  Widget _listBtn(PlacesState s) => GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ResultsScreen(category: _selectedCat))),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppTheme.primary, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            const Icon(Icons.list_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(s.places.isEmpty ? 'Ver Lista' : '${s.places.length} locais',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      );
}
