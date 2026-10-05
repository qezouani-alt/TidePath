import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../widgets/premium_widgets.dart';

class PhotoCreditsScreen extends StatelessWidget {
  const PhotoCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Fish photo credits')),
    body: FutureBuilder<String>(
      future: rootBundle.loadString('assets/images/fish/credits.json'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final credits = (jsonDecode(snapshot.data!) as List<dynamic>)
            .cast<Map<String, dynamic>>();
        return SingleChildScrollView(
          child: ScreenPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Real species photographs from Wikimedia Commons. Tap and hold a source link to copy it.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                ...List.generate(credits.length, (index) {
                  final credit = credits[index];
                  final fish = DemoData.fish[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FishPortrait(fish: fish, size: 64),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fish.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${credit['creator']} · ${credit['license']}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SelectableText(
                                  credit['source'] as String,
                                  style: const TextStyle(
                                    color: AppColors.blue,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 22),
              ],
            ),
          ),
        );
      },
    ),
  );
}
