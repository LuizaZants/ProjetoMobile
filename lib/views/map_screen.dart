// lib/views/map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/places.dart';
import '../services/LocaleService.dart';
import '../services/PlaceService.dart';
import '../services/GeminiService.dart';
import '../services/DirectionsService.dart';
import '../services/AppConfig.dart';
import 'chat_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  // ── Cores ────────────────────────────────────────────────────────────────
  static const primaryColor = Color(0xFF4F46E5);
  static const bgColor      = Color(0xFFF8FAFC);

  // ── Mapa ─────────────────────────────────────────────────────────────────
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _userLocation;
  Set<Marker>    _markers   = {};
  Set<Polyline>  _polylines = {};

  // ── Lugares ───────────────────────────────────────────────────────────────
  List<PontoTuristico> _lugares        = [];
  PontoTuristico?      _localSelecionado;
  bool   _estaCarregando = false;
  String _statusMsg      = '';

  // ── Rota ──────────────────────────────────────────────────────────────────
  RotaInfo? _rotaAtual;
  bool      _calculandoRota = false;
  String    _modoRota       = 'walking';

  // ── Filtros ───────────────────────────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();
  String _categoriaSelecionada = 'Gastronomia';
  final List<String> _categorias = [
    'Gastronomia', 'Cultura', 'Lazer',
    'Natureza', 'Pontos Turísticos', 'Bares', 'Entretenimento',
  ];

  // ── Modos de rota ─────────────────────────────────────────────────────────
  final Map<String, Map<String, dynamic>> _modos = {
    'walking':   {'label': 'A pé',       'icon': Icons.directions_walk_rounded},
    'driving':   {'label': 'Carro',      'icon': Icons.directions_car_rounded},
    'bicycling': {'label': 'Bicicleta',  'icon': Icons.directions_bike_rounded},
    'transit':   {'label': 'Transporte', 'icon': Icons.directions_transit_rounded},
  };

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  // ── Inicialização ─────────────────────────────────────────────────────────
  Future<void> _inicializar() async {
    await AppConfig.load();
    await _buscarLocalizacao();
  }

  Future<void> _buscarLocalizacao() async {
    setState(() { _estaCarregando = true; _statusMsg = 'Obtendo sua localização... 📡'; });
    try {
      final pos = await GeolocalizacaoService.pegarPosicaoAtual();
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      await _buscarLugares();
    } catch (e) {
      setState(() => _estaCarregando = false);
      _mostrarErro('$e');
    }
  }

  Future<void> _buscarLugares() async {
    if (_userLocation == null) return;
    setState(() {
      _estaCarregando  = true;
      _lugares         = [];
      _localSelecionado = null;
      _rotaAtual       = null;
      _polylines       = {};
      _statusMsg       = 'Buscando lugares de $_categoriaSelecionada... 🗺️';
    });

    try {
      final lugaresGoogle = await GooglePlacesService.buscarLugaresProximos(
        _userLocation!.latitude, _userLocation!.longitude, _categoriaSelecionada,
      );

      if (lugaresGoogle.isEmpty) {
        throw 'Nenhum local encontrado para "$_categoriaSelecionada" nas proximidades.';
      }

      final int max = lugaresGoogle.length < 5 ? lugaresGoogle.length : 5;
      final List<PontoTuristico> temp = [];

      for (int i = 0; i < max; i++) {
        final lugar = lugaresGoogle[i];
        if (!mounted) return;
        setState(() => _statusMsg = 'IA analisando "${lugar['nome']}" (${i + 1}/$max) 🧠');

        final dadosIA = await GeminiService.enriquecerLugar(
          lugar['nome']!, lugar['endereco']!, _categoriaSelecionada,
        );
        temp.add(PontoTuristico.mesclar(lugar, dadosIA));

        if (i < max - 1) await Future.delayed(const Duration(milliseconds: 800));
      }

      if (!mounted) return;
      setState(() { _lugares = temp; _estaCarregando = false; });
      await _atualizarMarcadores();
      await _centralizarMapa();
    } catch (e) {
      if (!mounted) return;
      setState(() => _estaCarregando = false);
      _mostrarErro('$e');
    }
  }

  // ── Marcadores ────────────────────────────────────────────────────────────
  Future<void> _atualizarMarcadores() async {
    final Set<Marker> markers = {};

    if (_userLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('user'),
        position: _userLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Você está aqui'),
        zIndex: 2,
      ));
    }

    for (int i = 0; i < _lugares.length; i++) {
      final lugar = _lugares[i];
      final isSelected = _localSelecionado?.placeId == lugar.placeId;
      markers.add(Marker(
        markerId: MarkerId(lugar.placeId.isEmpty ? 'lugar_$i' : lugar.placeId),
        position: LatLng(lugar.latitude, lugar.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(
          title: lugar.nome,
          snippet: '⭐ ${lugar.rating.toStringAsFixed(1)} · ${lugar.distanciaFormatada}',
        ),
        zIndex: isSelected ? 3 : 1,
        onTap: () => _selecionarLugar(lugar),
      ));
    }

    setState(() => _markers = markers);
  }

  // ── Câmera ────────────────────────────────────────────────────────────────
  Future<void> _centralizarMapa() async {
    if (!_mapController.isCompleted || _userLocation == null) return;
    final ctrl = await _mapController.future;
    await ctrl.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 14));
  }

  Future<void> _moverCamera(PontoTuristico lugar) async {
    if (!_mapController.isCompleted) return;
    final ctrl = await _mapController.future;
    await ctrl.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lugar.latitude, lugar.longitude), 15));
  }

  Future<void> _ajustarCameraRota(List<LatLng> pontos) async {
    if (!_mapController.isCompleted || pontos.isEmpty) return;
    final ctrl = await _mapController.future;

    double minLat = pontos.first.latitude, maxLat = pontos.first.latitude;
    double minLng = pontos.first.longitude, maxLng = pontos.first.longitude;
    for (final p in pontos) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    await ctrl.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      72,
    ));
  }

  // ── Seleção de local ──────────────────────────────────────────────────────
  void _selecionarLugar(PontoTuristico lugar) {
    setState(() {
      _localSelecionado = lugar;
      _rotaAtual        = null;
      _polylines        = {};
    });
    _atualizarMarcadores();
    _moverCamera(lugar);
  }

  // ── Rota nativa no mapa ───────────────────────────────────────────────────
  Future<void> _calcularRotaNoMapa(PontoTuristico lugar, String modo) async {
    if (_userLocation == null) return;
    setState(() { _calculandoRota = true; _modoRota = modo; });

    try {
      final rota = await DirectionsService.calcularRota(
        originLat: _userLocation!.latitude,
        originLng: _userLocation!.longitude,
        destLat:   lugar.latitude,
        destLng:   lugar.longitude,
        modo:      modo,
      );

      if (!mounted) return;
      setState(() {
        _rotaAtual       = rota;
        _calculandoRota  = false;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('rota'),
            points:     rota.pontos,
            color:      primaryColor,
            width:      5,
          ),
        };
      });
      await _ajustarCameraRota(rota.pontos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _calculandoRota = false);
      _mostrarErro('$e');
    }
  }

  void _limparRota() {
    setState(() { _rotaAtual = null; _polylines = {}; });
  }

  // ── Chat ──────────────────────────────────────────────────────────────────
  void _abrirChat(PontoTuristico lugar) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatAssistenteScreen(
          local:              lugar,
          userLat:            _userLocation!.latitude,
          userLng:            _userLocation!.longitude,
          categoriaEscolhida: _categoriaSelecionada,
        ),
      ),
    );
  }

  // ── Modal lista ───────────────────────────────────────────────────────────
  void _abrirListaModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ListaLugaresModal(
        lugares:          _lugares,
        categoria:        _categoriaSelecionada,
        localSelecionado: _localSelecionado,
        onSelect: (lugar) {
          Navigator.pop(context);
          _selecionarLugar(lugar);
        },
      ),
    );
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Mapa
          if (_userLocation != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _userLocation!, zoom: 14),
              onMapCreated: (ctrl) => _mapController.complete(ctrl),
              markers:   _markers,
              polylines: _polylines,
              myLocationEnabled:       true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled:     false,
              mapToolbarEnabled:       false,
              compassEnabled:          true,
              onTap: (_) {
                if (_localSelecionado != null) {
                  setState(() { _localSelecionado = null; _rotaAtual = null; _polylines = {}; });
                  _atualizarMarcadores();
                }
              },
            ),

          if (_userLocation == null && !_estaCarregando)
            Container(
              color: const Color(0xFFE2E8F0),
              child: const Center(
                  child: Text('Aguardando localização...',
                      style: TextStyle(color: Color(0xFF64748B)))),
            ),

          // Barra superior
          SafeArea(
            child: Column(children: [_buildTopBar(), const Spacer()]),
          ),

          // Loading
          if (_estaCarregando) _buildLoadingOverlay(),

          // Calculando rota
          if (_calculandoRota)
            Positioned(
              bottom: 180,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
                      SizedBox(width: 10),
                      Text('Calculando rota...', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),

          // Painel inferior
          if (!_estaCarregando && _lugares.isNotEmpty)
            _localSelecionado != null
                ? _buildCardSelecionado()
                : _buildBotaoLista(),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: primaryColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sua localização atual',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      Text(
                        _userLocation != null
                            ? '${_userLocation!.latitude.toStringAsFixed(4)}, ${_userLocation!.longitude.toStringAsFixed(4)}'
                            : 'Obtendo localização...',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
                if (_lugares.isNotEmpty) _iconBtn(Icons.list_rounded, _abrirListaModal),
                const SizedBox(width: 6),
                _iconBtn(Icons.refresh_rounded, _buscarLocalizacao),
              ],
            ),
          ),
          // Filtros de categoria
          SizedBox(
            height: 56,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categorias.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat    = _categorias[index];
                final isSel  = cat == _categoriaSelecionada;
                final emoji  = _emojiCategoria(cat);
                return GestureDetector(
                  onTap: () {
                    if (!isSel) {
                      setState(() => _categoriaSelecionada = cat);
                      _buscarLugares();
                      const itemW = 110.0;
                      final dest = (index * itemW) -
                          (MediaQuery.of(context).size.width / 2) +
                          (itemW / 2);
                      _scrollController.animateTo(
                        dest.clamp(0.0, _scrollController.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? primaryColor : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
      );

  // ── Loading overlay ───────────────────────────────────────────────────────
  Widget _buildLoadingOverlay() => Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.35),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 20),
                  Text(_statusMsg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: Color(0xFF475569), height: 1.5)),
                ],
              ),
            ),
          ),
        ),
      );

  // ── Botão lista ───────────────────────────────────────────────────────────
  Widget _buildBotaoLista() => Positioned(
        bottom: 16, left: 16, right: 16,
        child: GestureDetector(
          onTap: _abrirListaModal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.place_rounded, color: primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_lugares.length} locais de $_categoriaSelecionada',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      const Text('Toque para ver a lista completa',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_up_rounded, color: primaryColor),
              ],
            ),
          ),
        ),
      );

  // ── Card do local selecionado ─────────────────────────────────────────────
  Widget _buildCardSelecionado() {
    final local = _localSelecionado!;
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto + info básica
                  Row(
                    children: [
                      // Foto
                      if (local.photoName != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: GooglePlacesService.fotoUrl(local.photoName!),
                            width: 72, height: 72, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 72, height: 72,
                              color: primaryColor.withOpacity(0.08),
                              child: const Icon(Icons.image_rounded, color: primaryColor),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 72, height: 72,
                              color: primaryColor.withOpacity(0.08),
                              child: const Icon(Icons.place_rounded, color: primaryColor),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.place_rounded, color: primaryColor, size: 32),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(local.nome,
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E293B))),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                                  onPressed: () {
                                    setState(() { _localSelecionado = null; _rotaAtual = null; _polylines = {}; });
                                    _atualizarMarcadores();
                                  },
                                ),
                              ],
                            ),
                            // Rating + distância
                            Row(children: [
                              Icon(Icons.star_rounded, color: Colors.amber.shade500, size: 14),
                              const SizedBox(width: 2),
                              Text(local.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              if (local.totalAvaliacoes > 0)
                                Text(' (${local.totalAvaliacoes})',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              const SizedBox(width: 10),
                              const Icon(Icons.directions_walk_rounded, size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 2),
                              Text(local.distanciaFormatada,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ]),
                            // Aberto/Fechado
                            if (local.aberto != null)
                              Row(children: [
                                Container(
                                  width: 7, height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: local.aberto! ? const Color(0xFF10B981) : Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(local.statusAberto,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: local.aberto! ? const Color(0xFF10B981) : Colors.redAccent)),
                              ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Descrição da IA
                  Text(local.descricao,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5)),

                  // Endereço
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(local.endereco,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            overflow: TextOverflow.ellipsis)),
                  ]),

                  // Info de rota (distância + tempo) se disponível
                  if (_rotaAtual != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.route_rounded, color: primaryColor, size: 18),
                          const SizedBox(width: 8),
                          Text(_rotaAtual!.distancia,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: primaryColor, fontSize: 14)),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 16),
                          const SizedBox(width: 4),
                          Text(_rotaAtual!.duracao,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          const Spacer(),
                          GestureDetector(
                            onTap: _limparRota,
                            child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── Seletor de modo de rota ───────────────────────────────
                  Row(
                    children: _modos.entries.map((entry) {
                      final isSel = _modoRota == entry.key && _rotaAtual != null;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _calcularRotaNoMapa(local, entry.key),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? primaryColor : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(entry.value['icon'] as IconData,
                                    size: 18,
                                    color: isSel ? Colors.white : const Color(0xFF64748B)),
                                const SizedBox(height: 2),
                                Text(entry.value['label'] as String,
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: isSel ? Colors.white : const Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // ── Botões ação ───────────────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _abrirChat(local),
                        icon: const Icon(Icons.smart_toy_rounded, size: 18),
                        label: const Text('Perguntar à IA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _abrirListaModal,
                        icon: const Icon(Icons.list_rounded, size: 18),
                        label: const Text('Ver Todos'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emojiCategoria(String cat) {
    switch (cat) {
      case 'Gastronomia':       return '🍽️';
      case 'Cultura':           return '🏛️';
      case 'Lazer':             return '🎭';
      case 'Natureza':          return '🌿';
      case 'Pontos Turísticos': return '🗺️';
      case 'Bares':             return '🍺';
      case 'Entretenimento':    return '🎬';
      default:                  return '📍';
    }
  }
}

// ── Modal de lista ────────────────────────────────────────────────────────────
class _ListaLugaresModal extends StatelessWidget {
  final List<PontoTuristico> lugares;
  final String categoria;
  final PontoTuristico? localSelecionado;
  final ValueChanged<PontoTuristico> onSelect;

  const _ListaLugaresModal({
    required this.lugares,
    required this.categoria,
    required this.localSelecionado,
    required this.onSelect,
  });

  static const primaryColor = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
            child: Row(
              children: [
                Text(categoria,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${lugares.length} locais',
                      style: const TextStyle(
                          fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: lugares.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final lugar = lugares[index];
                final isSel = localSelecionado?.placeId == lugar.placeId;
                return GestureDetector(
                  onTap: () => onSelect(lugar),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel ? primaryColor : const Color(0xFFE2E8F0),
                        width: isSel ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isSel ? 0.06 : 0.02),
                          blurRadius: 8, offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        // Foto ou ícone
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: lugar.photoName != null
                              ? CachedNetworkImage(
                                  imageUrl: GooglePlacesService.fotoUrl(lugar.photoName!),
                                  width: 52, height: 52, fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 52, height: 52,
                                    color: primaryColor.withOpacity(0.08),
                                    child: const Icon(Icons.image_rounded, color: primaryColor, size: 22),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 52, height: 52,
                                    color: primaryColor.withOpacity(0.08),
                                    child: const Icon(Icons.place_rounded, color: primaryColor, size: 22),
                                  ),
                                )
                              : Container(
                                  width: 52, height: 52,
                                  color: primaryColor.withOpacity(0.08),
                                  child: const Icon(Icons.location_on_rounded, color: primaryColor, size: 22),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lugar.nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.star_rounded, color: Colors.amber.shade500, size: 13),
                                const SizedBox(width: 2),
                                Text(lugar.rating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(width: 8),
                                const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF64748B)),
                                const SizedBox(width: 2),
                                Text(lugar.distanciaFormatada,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(width: 8),
                                const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF64748B)),
                                const SizedBox(width: 2),
                                Text('${lugar.tempoMinutos}min',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              ]),
                              if (lugar.aberto != null)
                                Row(children: [
                                  Container(
                                    width: 6, height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: lugar.aberto! ? const Color(0xFF10B981) : Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(lugar.statusAberto,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: lugar.aberto! ? const Color(0xFF10B981) : Colors.redAccent)),
                                ]),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
