import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../models/fish_activity_level.dart';
import '../../../services/spot_conditions_service.dart';
import '../../../models/fishing_location.dart';
import '../../../services/nearby_spots_service.dart';
import '../../../widgets/premium_widgets.dart';
import '../../fishing_spots/screens/spot_detail_screen.dart';
import '../../location/location_scope.dart';
import '../../location/screens/location_picker_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.nearbySpotsService});
  final NearbySpotsService? nearbySpotsService;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String query = '';
  String filter = 'All spots';
  bool mapView = false;
  final Map<String, String> activeFilters = {};
  final _conditions = SpotConditionsService();
  String? _loadedLocation;
  Future<List<FishingSpot>>? _request;
  List<FishingSpot>? _ratedSpots;

  Future<List<FishingSpot>> _load(
    FishingLocation location, {
    bool refresh = false,
  }) async {
    final spots = await (widget.nearbySpotsService ?? NearbySpotsService.shared)
        .load(location, forceRefresh: refresh);
    final rated = await _conditions.load(spots, forceRefresh: refresh);
    if (mounted && _loadedLocation == location.coordinates) _ratedSpots = rated;
    return rated;
  }

  @override
  void dispose() {
    _conditions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = FishingLocationScope.of(context).selected;
    final service = widget.nearbySpotsService ?? NearbySpotsService.shared;
    if (_loadedLocation != location.coordinates) {
      _loadedLocation = location.coordinates;
      _ratedSpots = null;
      _request = _load(location);
    }
    return FutureBuilder<List<FishingSpot>>(
      key: ValueKey(location.coordinates),
      future: _request,
      initialData: _ratedSpots,
      builder: (context, snapshot) => _buildContents(
        context,
        location,
        snapshot.data,
        service.isSample(location),
        service.isUnavailable(location),
        service.attribution,
      ),
    );
  }

  Widget _buildContents(
    BuildContext context,
    FishingLocation location,
    List<FishingSpot>? spots,
    bool sample,
    bool unavailable,
    String attribution,
  ) {
    final results = (spots ?? const <FishingSpot>[])
        .where(
          (spot) =>
              spot.name.toLowerCase().contains(query.toLowerCase()) &&
              (filter == 'All spots' ||
                  (['Good', 'Excellent', 'Perfect'].contains(filter)
                      ? spot.hasForecast &&
                            FishActivityLevel.fromScore(spot.score).label ==
                                filter
                      : _matchesType(spot, filter))) &&
              _matchesFilters(spot),
        )
        .toList();
    return RefreshIndicator(
      onRefresh: () => _retry(location),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 22, bottom: 120),
        child: ScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Explore', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 5),
              const Text(
                'Find your next great fishing spot.',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 15),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => pushPage(context, const LocationPickerScreen()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          location.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.blue,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PremiumSearchBar(
                hint: 'Search fishing spots or beaches',
                onChanged: (value) => setState(() => query = value),
                onFilter: _showFilters,
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 37,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    const filters = [
                      'All spots',
                      'Good',
                      'Excellent',
                      'Perfect',
                      'Beach',
                      'Headland',
                      'Harbor',
                    ];
                    final selected = filter == filters[i];
                    return ChoiceChip(
                      label: Text(filters[i]),
                      selected: selected,
                      onSelected: (_) => setState(() => filter = filters[i]),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: selected ? Colors.white : AppColors.blue,
                      ),
                      selectedColor: AppColors.blue,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide.none,
                      showCheckmark: false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 21),
              Row(
                children: [
                  Text(
                    'Around ${location.shortName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.map_outlined, size: 17),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.view_list_rounded, size: 17),
                      ),
                    ],
                    selected: {mapView},
                    onSelectionChanged: (value) =>
                        setState(() => mapView = value.first),
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              if (mapView)
                _SpotMap(
                  location: location,
                  spots: results,
                  onSpot: (spot) =>
                      pushPage(context, SpotDetailScreen(spot: spot)),
                ),
              const SizedBox(height: 26),
              SectionHeader(
                'Fishing spots near ${location.shortName}',
                action: spots == null ? 'Loading' : '${results.length} spots',
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  sample
                      ? 'Sample Agadir spots shown while the place search is unavailable.'
                      : unavailable
                      ? 'Place search unavailable · showing cached places when available. Pull down to retry.'
                      : 'Places within ${NearbySpotsService.radiusKm} km · $attribution. Ratings use each spot’s weather and sea forecast; catches are not guaranteed.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
              if (spots == null)
                const AppCard(child: Center(child: CircularProgressIndicator()))
              else if (results.isEmpty)
                AppCard(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(25),
                        child: Text(
                          'No mapped places match this location or filter. Try another location or filter.',
                        ),
                      ),
                      if (filter != 'All spots' || activeFilters.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() {
                            filter = 'All spots';
                            activeFilters.clear();
                          }),
                          child: const Text('Show all nearby spots'),
                        ),
                      if (unavailable)
                        TextButton.icon(
                          onPressed: () => _retry(location),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry nearby search'),
                        ),
                    ],
                  ),
                )
              else
                ...results.map(
                  (spot) => Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: EntryReveal(
                      child: FishingSpotCard(
                        spot: spot,
                        onTap: () =>
                            pushPage(context, SpotDetailScreen(spot: spot)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _retry(FishingLocation location) async {
    setState(() => _request = _load(location, refresh: true));
    await _request;
  }

  bool _matchesType(FishingSpot spot, String type) => type == 'Harbor'
      ? ['Marina', 'Pier', 'Harbor'].contains(spot.type)
      : spot.type.toLowerCase().contains(type.toLowerCase());

  bool _matchesFilters(FishingSpot spot) {
    final distance = double.tryParse(spot.distance.split(' ').first) ?? 99;
    final wind = double.tryParse(spot.wind.split(' ').first) ?? 99;
    final waves = double.tryParse(spot.waves.split(' ').first) ?? 99;
    for (final entry in activeFilters.entries) {
      final matches = switch (entry.key) {
        'Distance' =>
          entry.value == 'Within 10 km' ? distance <= 10 : distance <= 15,
        'Fishing score' => spot.hasForecast && spot.score >= 85,
        'Beach type' => _matchesType(spot, entry.value),
        'Wave height' => spot.hasForecast && waves < 1,
        'Wind' => spot.hasForecast && wind < 12,
        'Target fish' => spot.fish.any(
          (fish) => fish.toLowerCase().contains(entry.value.toLowerCase()),
        ),
        'Difficulty' => !spot.mapped && spot.type != 'Rocky shore',
        _ => true,
      };
      if (!matches) return false;
    }
    return true;
  }

  void _showFilters() {
    const sections = <String, List<String>>{
      'Distance': ['Within 10 km', 'Within 15 km'],
      'Fishing score': ['85+ score'],
      'Beach type': ['Beach', 'Headland', 'Harbor'],
      'Wave height': ['Under 1 m'],
      'Wind': ['Under 12 km/h'],
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .78,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Filter fishing spots',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(activeFilters.clear);
                          updateSheet(() {});
                        },
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: sections.entries
                            .map(
                              (section) => Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      section.key,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 7,
                                      children: section.value.map((option) {
                                        final selected =
                                            activeFilters[section.key] ==
                                            option;
                                        return ChoiceChip(
                                          label: Text(option),
                                          selected: selected,
                                          showCheckmark: false,
                                          selectedColor: AppColors.blue,
                                          side: BorderSide.none,
                                          labelStyle: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: selected
                                                ? Colors.white
                                                : AppColors.blue,
                                          ),
                                          onSelected: (_) {
                                            setState(() {
                                              if (selected) {
                                                activeFilters.remove(
                                                  section.key,
                                                );
                                              } else {
                                                activeFilters[section.key] =
                                                    option;
                                              }
                                            });
                                            updateSheet(() {});
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  GradientButton(
                    'Show spots',
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotMap extends StatelessWidget {
  const _SpotMap({
    required this.location,
    required this.spots,
    required this.onSpot,
  });
  final FishingLocation location;
  final List<FishingSpot> spots;
  final ValueChanged<FishingSpot> onSpot;
  @override
  Widget build(BuildContext context) => Container(
    height: 230,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xFFB6E6E7), Color(0xFFE7E2C8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          FlutterMap(
            key: ValueKey(location.coordinates),
            options: MapOptions(initialCenter: location.point, initialZoom: 10),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fish.mood',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: location.point,
                    width: 32,
                    height: 32,
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.ocean,
                      size: 25,
                    ),
                  ),
                  for (final spot in spots)
                    if (spot.point != null)
                      Marker(
                        point: spot.point!,
                        width: 55,
                        height: 35,
                        child: _MapPin(spot: spot, onTap: () => onSpot(spot)),
                      ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 9,
            child: Text(
              '© OpenStreetMap contributors',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 9,
                backgroundColor: Colors.white.withValues(alpha: .8),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.spot, required this.onTap});
  final FishingSpot spot;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: !spot.hasForecast || spot.score < 70
            ? AppColors.blue
            : AppColors.good,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.phishing_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            spot.hasForecast ? '${spot.score}' : '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}
