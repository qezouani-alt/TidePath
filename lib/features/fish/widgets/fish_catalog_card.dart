import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../models/fish_catalog.dart';
import '../../../widgets/premium_widgets.dart';
import 'nearby_fish_card.dart';

class FishCatalogCard extends StatelessWidget {
  const FishCatalogCard({super.key, required this.fish, this.onTap});

  final FishCatalogSpecies fish;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final usesRemotePhoto =
        fish.photoUrl != null &&
        !DemoData.fish.any((item) => item.scientific == fish.scientificName);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          FishPhotoPortrait(
            scientificName: fish.scientificName,
            photoUrl: fish.photoUrl,
          ),
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
                    style: const TextStyle(color: AppColors.muted, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
