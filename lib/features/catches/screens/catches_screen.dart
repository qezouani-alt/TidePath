import '../../../services/navigation_ad_service.dart';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../widgets/premium_widgets.dart';
import '../models/catch_entry.dart';
import 'add_catch_screen.dart';

class CatchesScreen extends StatefulWidget {
  const CatchesScreen({super.key});
  @override
  State<CatchesScreen> createState() => _CatchesScreenState();
}

class _CatchesScreenState extends State<CatchesScreen> {
  final catches = CatchJournal.entries;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Catches')),
    body: SingleChildScrollView(
      child: ScreenPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your fishing story, one catch at a time.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 23),
            LayoutBuilder(
              builder: (context, constraints) => GridView.count(
                crossAxisCount: constraints.maxWidth > 520 ? 4 : 2,
                childAspectRatio: 1.46,
                mainAxisSpacing: 11,
                crossAxisSpacing: 11,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Stat(
                    Icons.phishing_rounded,
                    'TOTAL CATCHES',
                    '${24 + catches.length - 3}',
                  ),
                  const _Stat(Icons.pets_outlined, 'SPECIES', '9'),
                  const _Stat(
                    Icons.emoji_events_outlined,
                    'BIGGEST CATCH',
                    '6.4 kg',
                  ),
                  const _Stat(
                    Icons.place_outlined,
                    'FAVORITE SPOT',
                    'Taghazout',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 29),
            SectionHeader('Recent catches', action: '${catches.length} shown'),
            ...catches.map((entry) {
              final fish = DemoData.fish.firstWhere(
                (f) => f.name == entry.species,
                orElse: () => DemoData.fish.first,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: CatchCard(
                  fish: fish,
                  weight: entry.weight,
                  length: entry.length,
                  spot: entry.spot,
                  date: entry.date,
                ),
              );
            }),
            const SizedBox(height: 90),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: AppColors.blue,
      foregroundColor: Colors.white,
      onPressed: () async {
        Future<CatchEntry?>? opened;
        await NavigationAdService.navigate(() {
          if (!context.mounted) return;
          opened = Navigator.push<CatchEntry>(
            context,
            MaterialPageRoute(builder: (_) => const AddCatchScreen()),
          );
        });
        final result = await opened;
        if (result != null && mounted) {
          setState(() => catches.insert(0, result));
        }
      },
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Add Catch',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.aqua, size: 21),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
