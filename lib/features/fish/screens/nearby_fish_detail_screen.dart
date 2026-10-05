import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../models/nearby_fish.dart';
import '../../../widgets/premium_widgets.dart';

class NearbyFishDetailScreen extends StatelessWidget {
  const NearbyFishDetailScreen({
    super.key,
    required this.fish,
    required this.locationName,
  });

  final NearbyFish fish;
  final String locationName;

  @override
  Widget build(BuildContext context) {
    final bundled = DemoData.fish
        .where((item) => item.scientific == fish.scientificName)
        .firstOrNull;
    final photo = bundled != null
        ? Image.asset(
            bundled.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _heroFallback(),
          )
        : fish.photoUrl != null
        ? Image.network(
            fish.photoUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(child: _heroFallback()),
                      child,
                    ],
                  ),
            errorBuilder: (_, _, _) => _heroFallback(),
          )
        : _heroFallback();
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
                            Icons.place_outlined,
                            color: AppColors.blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fish.observationLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ocean,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Within 30 km of $locationName',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 21),
                    const SectionHeader('About these records'),
                    const Text(
                      'People have reported this species nearby on iNaturalist. '
                      'The count is historical observation data, not a prediction '
                      'that it can be caught today or at this exact fishing spot.',
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

  Widget _heroFallback() =>
      const Icon(Icons.phishing_rounded, size: 130, color: Colors.white70);
}
