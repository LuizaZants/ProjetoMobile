import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/place.dart';
import '../../providers/app_providers.dart';

class PlaceCard extends ConsumerWidget {
  final Place place;
  final VoidCallback onTap;

  const PlaceCard({super.key, required this.place, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getUrl = ref.read(photoUrlProvider);
    final cat    = place.category;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [BoxShadow(color: AppTheme.shadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72, height: 72,
                  child: place.firstPhoto != null
                      ? CachedNetworkImage(
                          imageUrl: getUrl(place.firstPhoto!),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _placeholder(cat),
                          errorWidget: (_, __, ___) => _placeholder(cat),
                        )
                      : _placeholder(cat),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        style: Theme.of(context).textTheme.labelLarge,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (place.address != null) ...[
                      const SizedBox(height: 3),
                      Text(place.address!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 6),
                    Row(children: [
                      if (place.rating != null) ...[
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Text(place.formattedRating,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        if (place.userRatingsTotal != null)
                          Text(' (${_fmt(place.userRatingsTotal!)})',
                              style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 8),
                      ],
                      if (place.distanceInMeters != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(place.formattedDistance,
                              style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                        ),
                    ]),
                    if (place.isOpen != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(width: 6, height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: place.isOpen! ? AppTheme.success : AppTheme.error,
                            )),
                        const SizedBox(width: 4),
                        Text(place.isOpen! ? 'Aberto' : 'Fechado',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: place.isOpen! ? AppTheme.success : AppTheme.error,
                            )),
                      ]),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(cat) => Container(
        color: cat?.color.withOpacity(0.1) ?? AppTheme.surfaceVariant,
        child: Icon(cat?.icon ?? Icons.place_rounded,
            color: cat?.color ?? AppTheme.textHint, size: 28),
      );

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}
