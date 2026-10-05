import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../widgets/premium_widgets.dart';
import '../../fish/screens/fish_detail_screen.dart';

class IdentifierScreen extends StatelessWidget {
  const IdentifierScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Identify a Fish')),
    body: SingleChildScrollView(
      child: ScreenPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 7),
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: oceanGradient,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.phishing_rounded,
                      color: Colors.white54,
                      size: 130,
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.center_focus_strong_rounded,
                      color: Colors.white,
                      size: 178,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Not sure what\nyou caught?',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'Take a photo and let TidePath help identify the species in your catch.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              'Take Photo',
              icon: Icons.camera_alt_outlined,
              onPressed: () =>
                  pushPage(context, const IdentifierResultScreen()),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    pushPage(context, const IdentifierResultScreen()),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose From Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.mist),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 31),
            const SectionHeader('Recently identified'),
            CatchCard(
              fish: DemoData.fish[0],
              weight: '94% match',
              length: 'Sea Bass',
              spot: 'Identified yesterday',
              date: 'View species',
              onTap: () =>
                  pushPage(context, FishDetailScreen(fish: DemoData.fish[0])),
            ),
          ],
        ),
      ),
    ),
  );
}

class IdentifierResultScreen extends StatefulWidget {
  const IdentifierResultScreen({super.key});
  @override
  State<IdentifierResultScreen> createState() => _IdentifierResultScreenState();
}

class _IdentifierResultScreenState extends State<IdentifierResultScreen> {
  bool loading = true;
  late final Timer timer;
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Identification Result')),
    body: loading
        ? ScreenPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 7),
                SkeletonCard(height: 260),
                SizedBox(height: 22),
                SkeletonCard(height: 35),
                SizedBox(height: 12),
                SkeletonCard(height: 75),
              ],
            ),
          )
        : SingleChildScrollView(
            child: ScreenPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.asset(
                      DemoData.fish.first.imagePath,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const LabelPill(
                    'DEMO IDENTIFICATION',
                    color: AppColors.mist,
                    textColor: AppColors.blue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'European Sea Bass',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Dicentrarchus labrax',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 19),
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.good,
                          size: 27,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '94% match',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const Text(
                          'High confidence',
                          style: TextStyle(
                            color: AppColors.good,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'This preview uses a sample photo and result. Photo recognition can be connected later.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 25),
                  GradientButton(
                    'View Fish Guide',
                    icon: Icons.menu_book_outlined,
                    onPressed: () => pushPage(
                      context,
                      FishDetailScreen(fish: DemoData.fish.first),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Identify another fish'),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}
