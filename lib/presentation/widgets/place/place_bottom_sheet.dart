import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/place.dart';
import '../../providers/app_providers.dart';
import '../../screens/details/details_screen.dart';
import '../../screens/navigation/navigation_screen.dart';

class PlaceBottomSheet extends ConsumerWidget {
  final Place place;
  const PlaceBottomSheet({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getUrl  = ref.read(photoUrlProvider);
    final locState = ref.read(locationNotifierProvider);
    final cat     = place.category;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          Row(children: [
            // Foto
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 68, height: 68,
                child: place.firstPhoto != null
                    ? CachedNetworkImage(
                        imageUrl: getUrl(place.firstPhoto!),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _thumb(cat),
                        errorWidget: (_, __, ___) => _thumb(cat),
                      )
                    : _thumb(cat),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name, style: Theme.of(context).textTheme.headlineSmall,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (place.address != null) ...[
                  const SizedBox(height: 2),
                  Text(place.address!, style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 4),
                Row(children: [
                  if (place.rating != null) ...[
                    const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                    Text(' ${place.formattedRating}  ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ],
                  if (place.distanceInMeters != null)
                    Text(place.formattedDistance,
                        style: Theme.of(context).textTheme.bodySmall),
                ]),
              ],
            )),
          ]),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => DetailsScreen(place: place)));
                },
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                label: const Text('Detalhes'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: locState.currentLocation != null
                    ? () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => NavigationScreen(
                              destination: place,
                              origin: locState.currentLocation!,
                            )));
                      }
                    : null,
                icon: const Icon(Icons.directions_rounded, size: 16),
                label: const Text('Rota'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _thumb(cat) => Container(
        color: cat?.color.withOpacity(0.1) ?? AppTheme.surfaceVariant,
        child: Icon(cat?.icon ?? Icons.place_rounded,
            color: cat?.color ?? AppTheme.primary, size: 28),
      );
}
