import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../models/fishing_location.dart';
import '../../../models/nearby_fish.dart';
import '../../../services/nearby_fish_service.dart';
import '../../../widgets/premium_widgets.dart';
import '../../fish/screens/nearby_fish_detail_screen.dart';
import '../../fish/widgets/nearby_fish_card.dart';
import '../../location/location_scope.dart';

class SpotDetailScreen extends StatefulWidget {
  const SpotDetailScreen({super.key, required this.spot});
  final FishingSpot spot;
  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  int selected = 0;
  bool favorite = false;
  @override
  Widget build(BuildContext context) {
    if (widget.spot.mapped) return _mappedDetail(context);
    const tabs = ['Overview', 'Conditions', 'Fish', 'Guide'];
    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SeaPhoto(height: 308, asset: widget.spot.image),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: .28),
                            Colors.transparent,
                            Colors.black.withValues(alpha: .42),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 11,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        _HeroButton(
                          Icons.arrow_back_ios_new_rounded,
                          () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        _HeroButton(
                          favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          () => setState(() => favorite = !favorite),
                          active: favorite,
                        ),
                        const SizedBox(width: 9),
                        _HeroButton(
                          Icons.share_outlined,
                          () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Spot link ready to share'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 23,
                    left: 22,
                    right: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LabelPill(
                          'EXCELLENT FISHING',
                          color: AppColors.good,
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 9),
                        Text(
                          widget.spot.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.spot.distance} · Agadir, Morocco',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ScreenPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F8F1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(
                                '${widget.spot.score}',
                                style: const TextStyle(
                                  color: AppColors.good,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fishing score',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Excellent conditions right now',
                                  style: TextStyle(
                                    color: AppColors.good,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_upward_rounded,
                            color: AppColors.good,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tabs.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 7),
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () => setState(() => selected = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 17),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected == i
                                  ? AppColors.ocean
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Text(
                              tabs[i],
                              style: TextStyle(
                                color: selected == i
                                    ? Colors.white
                                    : AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 23),
                    if (selected == 0)
                      _overview(context)
                    else if (selected == 1)
                      _conditions(context)
                    else if (selected == 2)
                      _fish(context)
                    else
                      _guide(context),
                    const SizedBox(height: 35),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mappedDetail(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SeaPhoto(height: 245, asset: widget.spot.image),
                Positioned(
                  top: 15,
                  left: 18,
                  child: _HeroButton(
                    Icons.arrow_back_ios_new_rounded,
                    () => Navigator.pop(context),
                  ),
                ),
                const Positioned(
                  right: 18,
                  bottom: 14,
                  child: LabelPill(
                    'ILLUSTRATIVE PHOTO',
                    color: Colors.white,
                    textColor: AppColors.ocean,
                  ),
                ),
              ],
            ),
            ScreenPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    widget.spot.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.spot.type} · ${widget.spot.distance}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  const AppCard(
                    child: Text(
                      'Mapped place from OpenStreetMap. Fishing access, rules, safety, and local conditions have not been verified. Check before visiting.',
                      style: TextStyle(color: AppColors.muted, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 270,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: widget.spot.point!,
                              initialZoom: 13,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.fish.mood',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: widget.spot.point!,
                                    width: 42,
                                    height: 42,
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.blue,
                                      size: 38,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            right: 8,
                            bottom: 7,
                            child: Text(
                              '© OpenStreetMap contributors',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 9,
                                backgroundColor: Colors.white.withValues(
                                  alpha: .8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.spot.point!.latitude.toStringAsFixed(5)}, '
                    '${widget.spot.point!.longitude.toStringAsFixed(5)} · '
                    '${widget.spot.sourceId ?? 'OpenStreetMap'}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _observedFish(
                    context,
                    FishingLocation(
                      label: widget.spot.name,
                      point: widget.spot.point!,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _observedFish(BuildContext context, FishingLocation location) {
    final service = NearbyFishService.shared;
    return FutureBuilder<NearbyFishPage>(
      future: service.load(location),
      initialData: service.cachedFor(location),
      builder: (context, snapshot) {
        final fish = snapshot.data?.fish ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Fish observed nearby'),
            const SizedBox(height: 5),
            const Text(
              'iNaturalist records within 30 km · not confirmed catches at this spot',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 12),
            if (snapshot.data == null)
              const AppCard(child: Center(child: CircularProgressIndicator()))
            else if (fish.isEmpty)
              AppCard(
                child: Text(
                  service.isUnavailable(location)
                      ? 'Local fish records are unavailable right now.'
                      : 'No fish observations found around this place.',
                  style: const TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...fish
                  .take(4)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: NearbyFishCard(
                        fish: item,
                        onTap: () => pushPage(
                          context,
                          NearbyFishDetailScreen(
                            fish: item,
                            locationName: widget.spot.name,
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

  Widget _overview(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader('About this spot'),
      Text(
        'A beautiful stretch of Atlantic coastline with rocky outcrops, sandy access and productive water around the headland. Early morning and a rising tide offer the best chance.',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 21),
      _infoRow(Icons.terrain_rounded, 'Beach type', widget.spot.type),
      _infoRow(Icons.hiking_rounded, 'Access difficulty', 'Easy to moderate'),
      _infoRow(Icons.local_parking_rounded, 'Parking', 'Available nearby'),
      _infoRow(Icons.school_outlined, 'Skill level', 'Beginner friendly'),
      _infoRow(
        Icons.phishing_rounded,
        'Best method',
        'Shore casting & light spinning',
      ),
      const SizedBox(height: 23),
      const SectionHeader('Best time to visit'),
      const AppCard(
        child: Row(
          children: [
            Icon(Icons.wb_twilight_rounded, color: AppColors.aqua, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tomorrow morning',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '06:15 – 09:30 · Rising tide',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ],
  );

  Widget _conditions(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader('Live sea conditions'),
      LayoutBuilder(
        builder: (context, constraints) => GridView.count(
          crossAxisCount: constraints.maxWidth > 520 ? 3 : 2,
          childAspectRatio: constraints.maxWidth > 520 ? 1.13 : 1.0,
          mainAxisSpacing: 11,
          crossAxisSpacing: 11,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            WeatherMetricCard(
              title: 'Wind',
              value: '10 km/h',
              subtitle: 'NW · gusts 16',
              icon: Icons.air_rounded,
            ),
            WeatherMetricCard(
              title: 'Waves',
              value: '1.0 m',
              subtitle: '8 second period',
              icon: Icons.waves_rounded,
            ),
            WeatherMetricCard(
              title: 'Swell',
              value: '0.8 m',
              subtitle: 'From the west',
              icon: Icons.water_rounded,
            ),
            WeatherMetricCard(
              title: 'Tide',
              value: 'Rising',
              subtitle: 'High at 10:42',
              icon: Icons.trending_up_rounded,
            ),
            WeatherMetricCard(
              title: 'Water',
              value: '19°C',
              subtitle: 'Comfortable',
              icon: Icons.thermostat_rounded,
            ),
            WeatherMetricCard(
              title: 'Weather',
              value: '22°C',
              subtitle: 'Mostly sunny',
              icon: Icons.wb_sunny_outlined,
            ),
            WeatherMetricCard(
              title: 'Sunrise',
              value: '07:24',
              subtitle: 'Golden hour',
              icon: Icons.wb_twilight_rounded,
            ),
            WeatherMetricCard(
              title: 'Sunset',
              value: '19:33',
              subtitle: 'Evening bite',
              icon: Icons.nights_stay_outlined,
            ),
            WeatherMetricCard(
              title: 'Moon',
              value: 'Waxing',
              subtitle: '62% illumination',
              icon: Icons.brightness_2_outlined,
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const SectionHeader('Hourly forecast'),
      SizedBox(
        height: 139,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(width: 9),
          itemBuilder: (_, i) => ForecastHourlyCard(
            time: ['06:00', '08:00', '10:00', '12:00', '14:00'][i],
            label: ['Excellent', 'Excellent', 'Good', 'Average', 'Poor'][i],
            icon: Icons.wb_sunny_outlined,
            score: [91, 88, 75, 62, 48][i],
          ),
        ),
      ),
    ],
  );

  Widget _fish(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _observedFish(context, FishingLocationScope.of(context).selected),
      const SizedBox(height: 11),
      const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Local bait tip',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            SizedBox(height: 5),
            Text(
              'Fresh sardine and shrimp work well around the rocky edges. Try soft lures at sunrise.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _guide(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader('Local fishing guide'),
      _guideCard(
        Icons.gps_fixed_rounded,
        'Where to cast',
        'Work the edge where sand meets the rocky headland. Keep a safe distance from breaking waves.',
      ),
      _guideCard(
        Icons.water_rounded,
        'Best tide',
        'A rising tide two hours before high water is especially productive.',
      ),
      _guideCard(
        Icons.sports_rounded,
        'Recommended gear',
        'A 9–10 ft medium spinning rod, 20 lb braid, fluorocarbon leader and 15–30 g lures.',
      ),
      _guideCard(
        Icons.health_and_safety_outlined,
        'Stay safe',
        'Rock surfaces can be slippery. Check swell and wind before approaching the water.',
      ),
    ],
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _guideCard(IconData icon, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.blue, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _HeroButton extends StatelessWidget {
  const _HeroButton(this.icon, this.onTap, {this.active = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(13),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          icon,
          key: ValueKey(icon),
          size: 19,
          color: active ? Colors.redAccent : AppColors.ink,
        ),
      ),
    ),
  );
}
