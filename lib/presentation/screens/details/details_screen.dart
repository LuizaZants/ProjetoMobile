import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/place.dart';
import '../../providers/app_providers.dart';
import '../navigation/navigation_screen.dart';
import 'package:tour/core/constants/place_categories.dart';
import '../../../core/constants/place_categories.dart';
 // Ajuste os caminhos (../) se necessário para chegar na sua pasta core
class DetailsScreen extends ConsumerWidget {
  final Place place;
  const DetailsScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getUrl  = ref.read(photoUrlProvider);
    final locState = ref.read(locationNotifierProvider);
    final cat     = place.category;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppTheme.surface,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: place.firstPhoto != null
                ? CachedNetworkImage(
                    imageUrl: getUrl(place.firstPhoto!),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _imgPlaceholder(cat),
                    errorWidget: (_, __, ___) => _imgPlaceholder(cat),
                  )
                : _imgPlaceholder(cat),
          ),
        ),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Nome + categoria
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(place.name,
                  style: Theme.of(context).textTheme.headlineLarge)),
              if (cat != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(cat.label,
                      style: TextStyle(color: cat.color, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ]),
            const SizedBox(height: 12),

            // Rating
            if (place.rating != null) Row(children: [
              RatingBarIndicator(
                rating: place.rating!,
                itemSize: 18,
                itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 8),
              Text(place.formattedRating,
                  style: Theme.of(context).textTheme.labelLarge),
              if (place.userRatingsTotal != null)
                Text('  (${place.userRatingsTotal} avaliacoes)',
                    style: Theme.of(context).textTheme.bodySmall),
            ]),

            const SizedBox(height: 14),

            // Chips info
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (place.distanceInMeters != null)
                _chip(Icons.directions_walk_rounded, place.formattedDistance, AppTheme.primary),
              if (place.isOpen != null)
                _chip(
                  place.isOpen! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  place.isOpen! ? 'Aberto agora' : 'Fechado',
                  place.isOpen! ? AppTheme.success : AppTheme.error,
                ),
            ]),

            const SizedBox(height: 18),
            const Divider(color: AppTheme.divider),
            const SizedBox(height: 14),

            // Endereco
            if (place.address != null)
              _infoRow(context, Icons.location_on_rounded, place.address!, AppTheme.error),

            // Telefone
            if (place.phoneNumber != null) ...[
              const SizedBox(height: 12),
              _infoRow(context, Icons.phone_rounded, place.phoneNumber!, AppTheme.success,
                  onTap: () => launchUrl(Uri(scheme: 'tel', path: place.phoneNumber!))),
            ],

            // Website
            if (place.website != null) ...[
              const SizedBox(height: 12),
              _infoRow(context, Icons.language_rounded, 'Visitar site', AppTheme.primary,
                  onTap: () => launchUrl(Uri.parse(place.website!))),
            ],

            // Horarios
            if (place.weekdayText != null && place.weekdayText!.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('Horarios de Funcionamento',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              ...place.weekdayText!.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(l, style: Theme.of(context).textTheme.bodySmall),
                  )),
            ],

            // Galeria
            if (place.photoReferences != null && place.photoReferences!.length > 1) ...[
              const SizedBox(height: 18),
              Text('Fotos', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: place.photoReferences!.length.clamp(0, 6),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: getUrl(place.photoReferences![i]),
                      width: 120, height: 96, fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 100),
          ]),
        )),
      ]),

      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: FloatingActionButton.extended(
          onPressed: locState.currentLocation != null
              ? () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => NavigationScreen(
                        destination: place, origin: locState.currentLocation!)))
              : null,
          backgroundColor: AppTheme.primary,
          label: const Row(children: [
            Icon(Icons.directions_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Ver Rota', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _imgPlaceholder(cat) => Container(
        color: cat?.color.withOpacity(0.15) ?? AppTheme.surfaceVariant,
        child: Icon(cat?.icon ?? Icons.place_rounded,
            size: 72, color: cat?.color ?? AppTheme.primary),
      );

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _infoRow(BuildContext ctx, IconData icon, String text, Color color, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: onTap != null ? color : null,
                decoration: onTap != null ? TextDecoration.underline : null,
              ))),
          if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 18),
        ]),
      );
}
