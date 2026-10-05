import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../models/fish_catalog.dart';
import '../../../widgets/premium_widgets.dart';

class FishCatalogDetailScreen extends StatelessWidget {
  const FishCatalogDetailScreen({super.key, required this.fish});

  final FishCatalogSpecies fish;

  @override
  Widget build(BuildContext context) {
    final bundled = DemoData.fish
        .where((item) => item.scientific == fish.scientificName)
        .firstOrNull;
    final photo = bundled != null
        ? Image.asset(
            bundled.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : fish.photoUrl != null
        ? Image.network(
            fish.photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : _fallback();
    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 290,
                    width: double.infinity,
                    decoration: const BoxDecoration(gradient: oceanGradient),
                    child: photo,
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 12,
                    left: 20,
                    child: IconButton.filled(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .93),
                        foregroundColor: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              ScreenPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 21),
                    Text(
                      fish.name,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fish.scientificName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.public_rounded,
                            color: AppColors.blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fish.observationLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ocean,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 21),
                    const SectionHeader('About this record'),
                    const Text(
                      'This species is listed in the worldwide iNaturalist catalog. '
                      'The observation count is global and historical; it does not '
                      'describe fishing conditions or the chance of catching it today.',
                      style: TextStyle(color: AppColors.muted, height: 1.5),
                    ),
                    if (bundled == null &&
                        fish.photoUrl != null &&
                        fish.photoCredit != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Photo: ${fish.photoCredit} · ${fish.photoLicense} · ${fish.photoSourceUrl?.contains('commons.wikimedia.org') == true ? 'Wikimedia Commons' : 'iNaturalist'}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                      if (fish.photoSourceUrl != null) ...[
                        const SizedBox(height: 4),
                        SelectableText(
                          fish.photoSourceUrl!,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() =>
      const Icon(Icons.phishing_rounded, size: 130, color: Colors.white70);
}
