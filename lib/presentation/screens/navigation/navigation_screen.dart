import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/place.dart';
import '../../providers/app_providers.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  final Place destination;
  final LatLng origin;
  const NavigationScreen({super.key, required this.destination, required this.origin});
  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  final Completer<GoogleMapController> _mapCtrl = Completer();
  String _mode = 'walking';

  final _modes = const {
    'walking':   {'label': 'A pe',       'icon': Icons.directions_walk_rounded},
    'driving':   {'label': 'Carro',      'icon': Icons.directions_car_rounded},
    'bicycling': {'label': 'Bicicleta',  'icon': Icons.directions_bike_rounded},
    'transit':   {'label': 'Transporte', 'icon': Icons.directions_transit_rounded},
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) _openMaps(_mode);
      else _calcRoute(_mode);
    });
  }

  Future<void> _openMaps(String mode) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${widget.origin.latitude},${widget.origin.longitude}'
      '&destination=${widget.destination.location.latitude},${widget.destination.location.longitude}'
      '&travelmode=$mode',
    );
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _calcRoute(String mode) async {
    await ref.read(routeNotifierProvider.notifier).calculate(
        origin: widget.origin, destination: widget.destination.location, mode: mode);
    final r = ref.read(routeNotifierProvider).route;
    if (r != null && _mapCtrl.isCompleted) _fitBounds(r.polylinePoints);
  }

  Future<void> _fitBounds(List<LatLng> pts) async {
    if (pts.isEmpty) return;
    final ctrl = await _mapCtrl.future;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    ctrl.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 72));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _webScreen();

    final rs = ref.watch(routeNotifierProvider);
    final polylines = rs.route?.polylinePoints.isNotEmpty == true
        ? <Polyline>{Polyline(polylineId: const PolylineId('r'),
              points: rs.route!.polylinePoints, color: AppTheme.primary, width: 5)}
        : <Polyline>{};

    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          onMapCreated: (c) => _mapCtrl.complete(c),
          initialCameraPosition: CameraPosition(target: widget.origin, zoom: AppConstants.defaultZoom),
          markers: {
            Marker(markerId: const MarkerId('o'), position: widget.origin,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: const InfoWindow(title: 'Voce esta aqui')),
            Marker(markerId: const MarkerId('d'), position: widget.destination.location,
                infoWindow: InfoWindow(title: widget.destination.name)),
          },
          polylines: polylines,
          zoomControlsEnabled: false, myLocationButtonEnabled: false, mapToolbarEnabled: false,
        ),

        // Back + destination
        SafeArea(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
                    boxShadow: [BoxShadow(color: AppTheme.shadow, blurRadius: 10)]),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
                  boxShadow: [BoxShadow(color: AppTheme.shadow, blurRadius: 10)]),
              child: Row(children: [
                const Icon(Icons.place_rounded, color: AppTheme.error, size: 15),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.destination.name,
                    style: Theme.of(context).textTheme.labelLarge, overflow: TextOverflow.ellipsis)),
              ]),
            )),
          ]),
        )),

        // Bottom panel
        Positioned(bottom: 0, left: 0, right: 0,
          child: SafeArea(child: Container(
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: AppTheme.shadow, blurRadius: 20, offset: const Offset(0, -4))]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Mode selector
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  children: _modes.entries.map((e) {
                    final sel = _mode == e.key;
                    return Expanded(child: GestureDetector(
                      onTap: () { setState(() => _mode = e.key); _calcRoute(e.key); },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.primary : AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Column(children: [
                          Icon(e.value['icon'] as IconData, size: 18,
                              color: sel ? Colors.white : AppTheme.textSecondary),
                          const SizedBox(height: 2),
                          Text(e.value['label'] as String,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : AppTheme.textSecondary)),
                        ]),
                      ),
                    ));
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: rs.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : rs.error != null
                        ? Text(rs.error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.error))
                        : rs.route != null
                            ? Row(children: [
                                Expanded(child: _metric(Icons.route_rounded, 'Distancia',
                                    rs.route!.distance, AppTheme.primary)),
                                const SizedBox(width: 12),
                                Expanded(child: _metric(Icons.access_time_rounded, 'Tempo',
                                    rs.route!.duration, AppTheme.secondary)),
                              ])
                            : const SizedBox.shrink(),
              ),
            ]),
          )),
        ),
      ]),
    );
  }

  Widget _webScreen() => Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(
      title: const Text('Rota'),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context)),
    ),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72,
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.map_rounded, color: AppTheme.primary, size: 40)),
        const SizedBox(height: 22),
        Text(widget.destination.name,
            style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text('No navegador, a rota e aberta no Google Maps.\nNo celular Android, sera desenhada no app.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: _modes.entries.map((e) {
            final sel = _mode == e.key;
            return GestureDetector(
              onTap: () => setState(() => _mode = e.key),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  Icon(e.value['icon'] as IconData, size: 20,
                      color: sel ? Colors.white : AppTheme.textSecondary),
                  const SizedBox(height: 2),
                  Text(e.value['label'] as String,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppTheme.textSecondary)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openMaps(_mode),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Abrir no Google Maps'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
      ]),
    )),
  );

  Widget _metric(IconData icon, String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(13)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}
