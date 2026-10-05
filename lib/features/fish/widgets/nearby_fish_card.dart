import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../models/nearby_fish.dart';
import '../../../widgets/premium_widgets.dart';

class NearbyFishPortrait extends StatelessWidget {
  const NearbyFishPortrait({super.key, required this.fish, this.size = 76});

  final NearbyFish fish;
  final double size;

  @override
  Widget build(BuildContext context) => FishPhotoPortrait(
    scientificName: fish.scientificName,
    photoUrl: fish.photoUrl,
    size: size,
  );
}

class FishPhotoPortrait extends StatelessWidget {
  const FishPhotoPortrait({
    super.key,
    required this.scientificName,
    this.photoUrl,
    this.size = 76,
  });

  final String scientificName;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bundled = DemoData.fish
        .where((item) => item.scientific == scientificName)
        .firstOrNull;
    final photo = bundled != null
        ? Image.asset(
            bundled.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : photoUrl != null
        ? Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            cacheWidth: (size * 3).round(),
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(child: _fallback()),
                      child,
                    ],
                  ),
            errorBuilder: (_, _, _) => _fallback(),
          )
        : _fallback();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(size * .27),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .27),
        child: photo,
      ),
    );
  }

  Widget _fallback() =>
      const Icon(Icons.phishing_rounded, color: AppColors.ocean, size: 34);
}

class NearbyFishCard extends StatelessWidget {
  const NearbyFishCard({
    super.key,
    required this.fish,
    this.onTap,
    this.compact = false,
  });

  final NearbyFish fish;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final usesRemotePhoto =
        fish.photoUrl != null &&
        !DemoData.fish.any((item) => item.scientific == fish.scientificName);
    return SizedBox(
      width: compact ? 180 : null,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(13),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NearbyFishPortrait(fish: fish, size: 70),
                  const SizedBox(height: 11),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        fish.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Text(
                    fish.observationLabel,
                    style: const TextStyle(
                      color: AppColors.good,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (usesRemotePhoto && fish.photoCredit != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Photo: ${fish.photoCredit} · ${fish.photoLicense}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              )
            : Row(
                children: [
                  NearbyFishPortrait(fish: fish),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fish.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fish.scientificName,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fish.observationLabel,
                          style: const TextStyle(
                            color: AppColors.good,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (usesRemotePhoto && fish.photoCredit != null)
                          Text(
                            'Photo: ${fish.photoCredit} · ${fish.photoLicense}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
      ),
    );
  }
}
