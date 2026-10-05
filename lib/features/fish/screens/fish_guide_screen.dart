import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../models/fishing_location.dart';
import '../../../models/nearby_fish.dart';
import '../../../services/fish_catalog_service.dart';
import '../../../services/nearby_fish_service.dart';
import '../../../widgets/premium_widgets.dart';
import '../../fish_identifier/screens/identifier_screen.dart';
import '../../location/location_scope.dart';
import 'fish_detail_screen.dart';
import 'nearby_fish_detail_screen.dart';
import '../widgets/nearby_fish_card.dart';
import '../widgets/fish_catalog_section.dart';

class FishGuideScreen extends StatefulWidget {
  const FishGuideScreen({
    super.key,
    this.nearbyFishService,
    this.fishCatalogService,
  });
  final NearbyFishService? nearbyFishService;
  final FishCatalogService? fishCatalogService;
  @override
  State<FishGuideScreen> createState() => _FishGuideScreenState();
}

class _FishGuideScreenState extends State<FishGuideScreen> {
  final _catalogKey = GlobalKey<FishCatalogSectionState>();
  String query = '';
  String category = 'Nearby';
  String? _locationKey;
  Future<NearbyFishPage>? _nearbyFuture;
  final List<NearbyFish> _extraFish = [];
  int _loadedPage = 1;
  bool _loadingMore = false;

  NearbyFishService get _service =>
      widget.nearbyFishService ?? NearbyFishService.shared;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = FishingLocationScope.of(context).selected;
    if (_locationKey != location.coordinates) {
      _locationKey = location.coordinates;
      _nearbyFuture = _service.load(location);
      _extraFish.clear();
      _loadedPage = 1;
      _loadingMore = false;
    }
  }

  Future<void> _refresh(FishingLocation location) async {
    if (category == 'All') {
      await _catalogKey.currentState?.refresh();
      return;
    }
    if (category != 'Nearby') return;
    final request = _service.load(location, forceRefresh: true);
    setState(() {
      _nearbyFuture = request;
      _extraFish.clear();
      _loadedPage = 1;
      _loadingMore = false;
    });
    await request;
  }

  Future<void> _loadMore(FishingLocation location) async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    final nextPage = _loadedPage + 1;
    final result = await _service.load(location, page: nextPage);
    if (!mounted || _locationKey != location.coordinates) return;
    setState(() {
      _extraFish.addAll(result.fish);
      if (!_service.isUnavailable(location, page: nextPage)) {
        _loadedPage = nextPage;
      }
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = FishingLocationScope.of(context).selected;
    final fish = DemoData.fish.where((f) {
      final matchesQuery =
          f.name.toLowerCase().contains(query.toLowerCase()) ||
          f.scientific.toLowerCase().contains(query.toLowerCase());
      final matchesCategory =
          (category == 'Saltwater' && f.habitat.startsWith('Saltwater')) ||
          (category == 'Freshwater' && f.habitat.startsWith('Freshwater')) ||
          (category == 'Predator' &&
              [
                'European Sea Bass',
                'Bluefin Tuna',
                'Grouper',
              ].contains(f.name)) ||
          (category == 'Bottom Fish' &&
              ['Common Sole', 'Grouper', 'Red Snapper'].contains(f.name)) ||
          (category == 'Popular' && DemoData.fish.indexOf(f) < 4);
      return matchesQuery && matchesCategory;
    }).toList();
    return RefreshIndicator(
      onRefresh: () => _refresh(location),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 22, bottom: 120),
        child: ScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fish Guide',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 5),
              const Text(
                'Get to know what swims below.',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 21),
              PremiumSearchBar(
                hint: 'Search fish species',
                onChanged: (value) => setState(() => query = value),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    const categories = [
                      'Nearby',
                      'All',
                      'Saltwater',
                      'Freshwater',
                      'Predator',
                      'Bottom Fish',
                      'Popular',
                    ];
                    final selected = category == categories[i];
                    return ChoiceChip(
                      label: Text(categories[i]),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => category = categories[i]),
                      showCheckmark: false,
                      selectedColor: AppColors.blue,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 23),
              GestureDetector(
                onTap: () => pushPage(context, const IdentifierScreen()),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: oceanGradient,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.center_focus_strong_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Caught something new?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Identify a fish from a photo',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              if (category == 'Nearby')
                _buildNearby(context, location)
              else if (category == 'All')
                FishCatalogSection(
                  key: _catalogKey,
                  query: query,
                  service:
                      widget.fishCatalogService ?? FishCatalogService.shared,
                )
              else ...[
                SectionHeader(
                  'Curated species',
                  action: '${fish.length} species',
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 13),
                  child: Text(
                    'These categories use the saved guide profiles.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ),
                if (fish.isEmpty)
                  const AppCard(
                    child: Text('No species found. Try another search.'),
                  )
                else
                  ...fish.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: EntryReveal(
                        child: FishCard(
                          fish: item,
                          onTap: () =>
                              pushPage(context, FishDetailScreen(fish: item)),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearby(
    BuildContext context,
    FishingLocation location,
  ) => FutureBuilder<NearbyFishPage>(
    future: _nearbyFuture,
    initialData: _service.cachedFor(location),
    builder: (context, snapshot) {
      final page = snapshot.data;
      final all = [...?page?.fish, ..._extraFish];
      final filtered = all
          .where(
            (item) =>
                item.name.toLowerCase().contains(query.toLowerCase()) ||
                item.scientificName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'Fish near ${location.shortName}',
            action: page == null ? 'Loading' : '${page.total} species',
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 13),
            child: Text(
              'Research-grade observations within 30 km · iNaturalist · not a catch forecast',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
          if (page == null)
            const AppCard(child: Center(child: CircularProgressIndicator()))
          else if (all.isEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _service.isUnavailable(location)
                        ? 'Nearby fish records are unavailable right now. Try again or browse the curated guide.'
                        : 'No fish observations found near this location. Try another place or browse the curated guide.',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _refresh(location),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry fish search'),
                  ),
                ],
              ),
            )
          else if (filtered.isEmpty)
            const AppCard(child: Text('No nearby species match this search.'))
          else
            ...filtered.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: EntryReveal(
                  child: NearbyFishCard(
                    fish: item,
                    onTap: () => pushPage(
                      context,
                      NearbyFishDetailScreen(
                        fish: item,
                        locationName: location.shortName,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (page != null && _loadedPage * 100 < page.total)
            Center(
              child: TextButton(
                onPressed: _loadingMore ? null : () => _loadMore(location),
                child: Text(
                  _loadingMore ? 'Loading more…' : 'Show more species',
                ),
              ),
            ),
        ],
      );
    },
  );
}
