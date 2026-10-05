import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../widgets/premium_widgets.dart';

class FishDetailScreen extends StatelessWidget {
  const FishDetailScreen({super.key, required this.fish});
  final FishSpecies fish;
  @override
  Widget build(BuildContext context) {
    final bass = fish.name == 'European Sea Bass';
    final bream = fish.name == 'Gilthead Sea Bream';
    final fresh = fish.habitat.startsWith('Freshwater');
    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 290,
                    width: double.infinity,
                    decoration: const BoxDecoration(gradient: oceanGradient),
                    child: Image.asset(
                      fish.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Icon(fish.icon, size: 145, color: Colors.white70),
                    ),
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
                  Positioned(
                    bottom: 20,
                    left: 22,
                    child: const LabelPill(
                      'FISH ENCYCLOPEDIA',
                      color: AppColors.good,
                      textColor: Colors.white,
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
                      fish.scientific,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 19),
                    LayoutBuilder(
                      builder: (context, constraints) => GridView.count(
                        crossAxisCount: constraints.maxWidth > 520 ? 4 : 2,
                        childAspectRatio: 1.55,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _Fact(Icons.water_rounded, 'HABITAT', fish.habitat),
                          _Fact(
                            Icons.straighten_rounded,
                            'AVERAGE SIZE',
                            bass
                                ? '40–70 cm'
                                : bream
                                ? '25–45 cm'
                                : fresh
                                ? '30–60 cm'
                                : '25–60 cm',
                          ),
                          _Fact(
                            Icons.scale_rounded,
                            'MAX WEIGHT',
                            bass
                                ? '12 kg'
                                : bream
                                ? '7 kg'
                                : fresh
                                ? '8 kg'
                                : '10 kg',
                          ),
                          _Fact(
                            Icons.calendar_month_rounded,
                            'BEST SEASON',
                            fresh ? 'Apr – Sep' : 'Mar – Oct',
                          ),
                          const _Fact(
                            Icons.wb_twilight_rounded,
                            'BEST TIME',
                            'Sunrise / sunset',
                          ),
                          _Fact(
                            Icons.phishing_rounded,
                            'BEST BAIT',
                            fresh
                                ? 'Worm · lure'
                                : bass
                                ? 'Sardine · shrimp'
                                : 'Shrimp · lure',
                          ),
                          _Fact(
                            Icons.insights_rounded,
                            'DIFFICULTY',
                            fish.difficulty,
                          ),
                          _Fact(
                            Icons.waves_rounded,
                            'DEPTH',
                            fresh ? '1–8 m' : '2–20 m',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 27),
                    const SectionHeader('About this fish'),
                    Text(
                      bass
                          ? 'A powerful coastal predator known for its silver body and confident strikes. It moves along surf breaks, estuaries and rocky shorelines while hunting small fish and crustaceans.'
                          : '${fish.name} is a ${fish.habitat.toLowerCase()} species. Learn its feeding patterns and preferred structure to plan a more rewarding session.',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.55,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 25),
                    const SectionHeader('Where to find it'),
                    _DetailText(
                      Icons.place_outlined,
                      fresh
                          ? 'Look for shaded banks, gentle current seams and deeper pockets around submerged structure.'
                          : 'Look for current seams, rocky points, harbor walls and sandy surf beaches. The incoming tide often brings fish closer to shore.',
                    ),
                    const SizedBox(height: 22),
                    const SectionHeader('Best fishing techniques'),
                    _DetailText(
                      Icons.sports_rounded,
                      fresh
                          ? 'Present bait or a small lure close to cover. Vary your retrieve until you find the active depth.'
                          : 'Try light spinning with soft plastics or shallow diving lures. Retrieve slowly with occasional pauses near structure.',
                    ),
                    const SizedBox(height: 22),
                    const SectionHeader('Recommended equipment'),
                    _DetailText(
                      Icons.handyman_outlined,
                      fresh
                          ? 'Light spinning rod · 2000 reel · fine braid or monofilament · small hooks.'
                          : '9 ft medium spinning rod · 3000 reel · 20 lb braid · fluorocarbon leader.',
                    ),
                    const SizedBox(height: 22),
                    const SectionHeader('Best bait & lures'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: fresh
                          ? const [
                              LabelPill('Worm'),
                              LabelPill('Small spinner'),
                              LabelPill('Soft lure'),
                            ]
                          : const [
                              LabelPill('Fresh sardine'),
                              LabelPill('Shrimp'),
                              LabelPill('Soft lure'),
                              LabelPill('Pencil lure'),
                            ],
                    ),
                    const SizedBox(height: 26),
                    const SectionHeader('Seasonal activity'),
                    AppCard(
                      child: SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(8, (i) {
                            const values = [
                              .35,
                              .47,
                              .66,
                              .84,
                              1.0,
                              .91,
                              .72,
                              .5,
                            ];
                            const months = [
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                            ];
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 20,
                                  height: 78 * values[i],
                                  decoration: BoxDecoration(
                                    gradient: oceanGradient,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  months[i],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 27),
                    const SectionHeader('Similar fish'),
                    ...DemoData.fish
                        .where((item) => item.name != fish.name)
                        .take(2)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FishCard(
                              fish: item,
                              onTap: () => pushPage(
                                context,
                                FishDetailScreen(fish: item),
                              ),
                            ),
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
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.blue),
        const Spacer(),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class _DetailText extends StatelessWidget {
  const _DetailText(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: AppColors.aqua),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
        ),
      ],
    ),
  );
}
