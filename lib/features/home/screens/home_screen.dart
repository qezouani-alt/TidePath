import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart' show FishingSpot;
import '../../../models/fishing_location.dart';
import '../../../models/nearby_fish.dart';
import '../../../services/nearby_fish_service.dart';
import '../../../services/nearby_spots_service.dart';
import '../../../services/user_profile_service.dart';
import '../../../widgets/premium_widgets.dart';
import '../../conditions/screens/fishing_conditions_details_screen.dart';
import '../../conditions/conditions_scope.dart';
import '../../fishing_spots/screens/spot_detail_screen.dart';
import '../../fish/screens/nearby_fish_detail_screen.dart';
import '../../fish/widgets/nearby_fish_card.dart';
import '../../location/location_scope.dart';
import '../../location/screens/location_picker_screen.dart';
import '../widgets/fishing_conditions_hero_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onTabSelected,
    this.nearbySpotsService,
    this.nearbyFishService,
  });
  final ValueChanged<int> onTabSelected;
  final NearbySpotsService? nearbySpotsService;
  final NearbyFishService? nearbyFishService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _spotsKey = GlobalKey<_NearbySpotsStripState>();
  final _fishKey = GlobalKey<_NearbyFishStripState>();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final dateLabel =
        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}'
            .toUpperCase();
    final name = UserProfileService.instance.firstName;
    final greeting = now.hour < 12
        ? 'Good morning, $name 👋'
        : now.hour < 17
        ? 'Good afternoon, $name 👋'
        : 'Good evening, $name 👋';
    final location = FishingLocationScope.of(context).selected;
    final controller = FishingConditionsScope.controllerOf(context);
    final conditions = controller.current;
    final loading = controller.showSkeleton;
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          controller.refresh(forceRefresh: true),
          _spotsKey.currentState?.retry() ??
              (widget.nearbySpotsService ?? NearbySpotsService.shared).load(
                location,
                forceRefresh: true,
              ),
          _fishKey.currentState?.retry() ??
              (widget.nearbyFishService ?? NearbyFishService.shared).load(
                location,
                forceRefresh: true,
              ),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 120),
        child: ScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.aqua,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontSize: 21, letterSpacing: -.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You’re all caught up!')),
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => widget.onTabSelected(4),
                    child: CircleAvatar(
                      radius: 21,
                      backgroundColor: Color(0xFFD8EFF4),
                      child: Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ocean,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              _LocationBar(
                label: location.label,
                onPlaceTap: () =>
                    pushPage(context, const LocationPickerScreen()),
                onLocateTap: () => pushPage(
                  context,
                  const LocationPickerScreen(detectOnOpen: true),
                ),
                onMapTap: () => pushPage(context, const LocationPickerScreen()),
              ),
              const SizedBox(height: 17),
              if (loading || !conditions.hasLiveForecast)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loading
                            ? 'Loading fishing conditions…'
                            : 'Conditions unavailable',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loading
                            ? 'Getting weather and marine forecasts for ${location.shortName}.'
                            : 'A live weather or marine forecast is not available for ${location.shortName}. Pull down or tap Retry to try again.',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      if (loading) ...[
                        const SizedBox(height: 18),
                        const LoadingLine(width: 210, height: 18),
                        const SizedBox(height: 12),
                        const LoadingLine(width: 150, height: 18),
                      ] else ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () =>
                              controller.refresh(forceRefresh: true),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                )
              else
                FishingConditionsHeroCard(
                  conditions: conditions,
                  onDetails: () =>
                      pushPage(context, const FishingConditionsDetailsScreen()),
                ),
              const SizedBox(height: 10),
              if (conditions.hasLiveForecast)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        conditions.sourceLabel,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
              SectionHeader(
                'Spots near ${location.shortName}',
                action: 'Explore',
                onAction: () => widget.onTabSelected(1),
              ),
              _NearbySpotsStrip(
                key: _spotsKey,
                location: location,
                service: widget.nearbySpotsService ?? NearbySpotsService.shared,
              ),
              const SizedBox(height: 30),
              SectionHeader(
                'Fish observed nearby',
                action: 'Fish guide',
                onAction: () => widget.onTabSelected(2),
                stackOnNarrow: true,
              ),
              _NearbyFishStrip(
                key: _fishKey,
                location: location,
                service: widget.nearbyFishService ?? NearbyFishService.shared,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationBar extends StatelessWidget {
  const _LocationBar({
    required this.label,
    required this.onPlaceTap,
    required this.onLocateTap,
    required this.onMapTap,
  });

  final String label;
  final VoidCallback onPlaceTap;
  final VoidCallback onLocateTap;
  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ocean.withValues(alpha: .055),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showActionLabels =
              constraints.maxWidth >= 310 &&
              MediaQuery.textScalerOf(context).scale(10) <= 12;
          return Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onPlaceTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'FISHING AT',
                                maxLines: 1,
                                style: TextStyle(
                                  color: AppColors.aqua,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              _LocationAction(
                icon: Icons.my_location_rounded,
                text: 'Locate',
                tooltip: 'Use my location',
                showLabel: showActionLabels,
                onTap: onLocateTap,
              ),
              const SizedBox(width: 6),
              _LocationAction(
                icon: Icons.map_outlined,
                text: 'Map',
                tooltip: 'Pick on map',
                showLabel: showActionLabels,
                onTap: onMapTap,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LocationAction extends StatelessWidget {
  const _LocationAction({
    required this.icon,
    required this.text,
    required this.tooltip,
    required this.showLabel,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final String tooltip;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: showLabel ? 7 : 13,
              vertical: 13,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: Theme.of(context).colorScheme.primary,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 4),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NearbyFishStrip extends StatefulWidget {
  const _NearbyFishStrip({
    super.key,
    required this.location,
    required this.service,
  });

  final FishingLocation location;
  final NearbyFishService service;

  @override
  State<_NearbyFishStrip> createState() => _NearbyFishStripState();
}

class _NearbyFishStripState extends State<_NearbyFishStrip> {
  late Future<NearbyFishPage> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.load(widget.location);
  }

  @override
  void didUpdateWidget(_NearbyFishStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.coordinates != widget.location.coordinates ||
        oldWidget.service != widget.service) {
      _future = widget.service.load(widget.location);
    }
  }

  Future<NearbyFishPage> retry() {
    final request = widget.service.load(widget.location, forceRefresh: true);
    setState(() => _future = request);
    return request;
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final cardHeight = (225 + (textScale - 1) * 95).clamp(225.0, 350.0);
    return FutureBuilder<NearbyFishPage>(
      future: _future,
      initialData: widget.service.cachedFor(widget.location),
      builder: (context, snapshot) {
        final page = snapshot.data;
        if (page == null) {
          return SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const SizedBox(
                width: 180,
                child: AppCard(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          );
        }
        final fish = page.fish;
        if (fish.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.service.isUnavailable(widget.location)
                    ? 'Local fish observations are unavailable right now.'
                    : 'No fish observations were found nearby.',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              if (widget.service.isUnavailable(widget.location))
                TextButton.icon(
                  onPressed: retry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry fish search'),
                ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Fish observed within 30 km · iNaturalist · not a catch forecast',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
            SizedBox(
              height: cardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fish.length.clamp(0, 8),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => NearbyFishCard(
                  fish: fish[i],
                  compact: true,
                  onTap: () => pushPage(
                    context,
                    NearbyFishDetailScreen(
                      fish: fish[i],
                      locationName: widget.location.shortName,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NearbySpotsStrip extends StatefulWidget {
  const _NearbySpotsStrip({
    super.key,
    required this.location,
    required this.service,
  });

  final FishingLocation location;
  final NearbySpotsService service;

  @override
  State<_NearbySpotsStrip> createState() => _NearbySpotsStripState();
}

class _NearbySpotsStripState extends State<_NearbySpotsStrip> {
  late Future<List<FishingSpot>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.load(widget.location);
  }

  @override
  void didUpdateWidget(_NearbySpotsStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.coordinates != widget.location.coordinates ||
        oldWidget.service != widget.service) {
      _future = widget.service.load(widget.location);
    }
  }

  Future<List<FishingSpot>> retry() {
    final request = widget.service.load(widget.location, forceRefresh: true);
    setState(() {
      _future = request;
    });
    return request;
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final service = widget.service;
    return FutureBuilder<List<FishingSpot>>(
      future: _future,
      initialData: service.cachedFor(location),
      builder: (context, snapshot) {
        final spots = snapshot.data;
        if (spots == null) {
          return SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 13),
              itemBuilder: (_, _) => const SizedBox(
                width: 250,
                child: AppCard(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          );
        }
        if (spots.isEmpty) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.connectionState == ConnectionState.waiting
                      ? 'Searching for nearby places…'
                      : service.isUnavailable(location)
                      ? 'Nearby places could not be loaded right now.'
                      : 'No mapped fishing or coastal places found within ${NearbySpotsService.radiusKm} km. Try another location.',
                  style: const TextStyle(color: AppColors.muted),
                ),
                if (snapshot.connectionState != ConnectionState.waiting) ...[
                  const SizedBox(height: 9),
                  TextButton.icon(
                    onPressed: retry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry nearby search'),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                service.isUnavailable(location)
                    ? 'Showing cached places while the place search is unavailable.'
                    : 'Nearby mapped places · ${service.attribution}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
            SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: spots.length,
                separatorBuilder: (_, _) => const SizedBox(width: 13),
                itemBuilder: (context, i) => FishingSpotCard(
                  spot: spots[i],
                  compact: true,
                  onTap: () =>
                      pushPage(context, SpotDetailScreen(spot: spots[i])),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
