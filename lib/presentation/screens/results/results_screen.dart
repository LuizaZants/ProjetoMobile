import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/place_categories.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/category_chip.dart';
import '../../widgets/place/place_card.dart';
import '../details/details_screen.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final PlaceCategory category;
  final String? searchQuery;
  const ResultsScreen({super.key, required this.category, this.searchQuery});
  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  late PlaceCategory _cat;

  @override
  void initState() { super.initState(); _cat = widget.category; }

  void _onCategory(PlaceCategory cat) {
    setState(() => _cat = cat);
    final loc = ref.read(locationNotifierProvider).currentLocation;
    if (loc != null) ref.read(placesNotifierProvider.notifier).loadNearby(location: loc, category: cat);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placesNotifierProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.searchQuery != null ? '"${widget.searchQuery}"' : _cat.label),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(children: [
        if (widget.searchQuery == null)
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: PlaceCategory.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = PlaceCategory.values[i];
                  return CategoryChip(category: cat, isSelected: _cat == cat,
                      onTap: () => _onCategory(cat));
                },
              ),
            ),
          ),
        const Divider(height: 1, color: AppTheme.divider),
        Expanded(child: _body(state)),
      ]),
    );
  }

  Widget _body(PlacesState state) {
    if (state.isLoading) return _skeleton();
    if (state.error != null) return _error(state.error!);
    if (state.places.isEmpty) return _empty();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => PlaceCard(
        place: state.places[i],
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => DetailsScreen(place: state.places[i]))),
      ),
    );
  }

  Widget _skeleton() => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 96,
          decoration: BoxDecoration(color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
        ),
      );

  Widget _empty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(_cat.icon, size: 56, color: AppTheme.textHint),
        const SizedBox(height: 14),
        Text('Nenhum local encontrado', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('Tente outra categoria', style: Theme.of(context).textTheme.bodySmall),
      ]));

  Widget _error(String e) => Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 14),
          Text(e, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textHint)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final loc = ref.read(locationNotifierProvider).currentLocation;
              if (loc != null) ref.read(placesNotifierProvider.notifier)
                  .loadNearby(location: loc, category: _cat);
            },
            child: const Text('Tentar novamente'),
          ),
        ]),
      ));
}
