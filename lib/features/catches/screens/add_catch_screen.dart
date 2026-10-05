import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../widgets/premium_widgets.dart';
import '../models/catch_entry.dart';

class AddCatchScreen extends StatefulWidget {
  const AddCatchScreen({super.key});
  @override
  State<AddCatchScreen> createState() => _AddCatchScreenState();
}

class _AddCatchScreenState extends State<AddCatchScreen> {
  final weight = TextEditingController();
  final length = TextEditingController();
  final notes = TextEditingController();
  String species = DemoData.fish.first.name;
  String spot = DemoData.spots.first.name;
  String method = 'Shore casting';
  String bait = 'Sardine';
  bool photoAdded = false;
  DateTime date = DateTime.now();
  TimeOfDay time = TimeOfDay.now();
  @override
  void dispose() {
    weight.dispose();
    length.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add Catch')),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: ScreenPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 7),
                    GestureDetector(
                      onTap: _choosePhoto,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.mist,
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(
                            color: AppColors.aqua.withValues(alpha: .4),
                            width: 1.5,
                          ),
                        ),
                        child: photoAdded
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.asset(
                                  DemoData.fish.first.imagePath,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: AppColors.blue,
                                    size: 35,
                                  ),
                                  SizedBox(height: 9),
                                  Text(
                                    'Add catch photo',
                                    style: TextStyle(
                                      color: AppColors.blue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 23),
                    _label('FISH SPECIES'),
                    _select(
                      species,
                      Icons.phishing_rounded,
                      () => _choose(
                        'Fish species',
                        DemoData.fish.map((f) => f.name).toList(),
                        (value) => setState(() => species = value),
                      ),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('WEIGHT (KG)'),
                              TextField(
                                controller: weight,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 2.4',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('LENGTH (CM)'),
                              TextField(
                                controller: length,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 48',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    _label('FISHING SPOT'),
                    _select(
                      spot,
                      Icons.place_outlined,
                      () => _choose(
                        'Fishing spot',
                        DemoData.spots.map((s) => s.name).toList(),
                        (value) => setState(() => spot = value),
                      ),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('DATE'),
                              _select(
                                '${date.day}/${date.month}/${date.year}',
                                Icons.calendar_today_outlined,
                                () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: date,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => date = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('TIME'),
                              _select(
                                time.format(context),
                                Icons.schedule_rounded,
                                () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: time,
                                  );
                                  if (picked != null) {
                                    setState(() => time = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    _label('FISHING METHOD'),
                    _select(
                      method,
                      Icons.sports_rounded,
                      () => _choose('Fishing method', [
                        'Shore casting',
                        'Light spinning',
                        'Surf fishing',
                        'Boat fishing',
                        'Rock fishing',
                      ], (value) => setState(() => method = value)),
                    ),
                    const SizedBox(height: 17),
                    _label('BAIT / LURE'),
                    _select(
                      bait,
                      Icons.auto_awesome_rounded,
                      () => _choose('Bait or lure', [
                        'Sardine',
                        'Shrimp',
                        'Soft lure',
                        'Pencil lure',
                        'Worm',
                      ], (value) => setState(() => bait = value)),
                    ),
                    const SizedBox(height: 17),
                    _label('WEATHER'),
                    const AppCard(
                      child: Row(
                        children: [
                          Icon(Icons.wb_sunny_outlined, color: AppColors.blue),
                          SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              'Sunny · 22°C · Light wind',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    _label('NOTES'),
                    TextField(
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tell the story of this catch...',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          ScreenPadding(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: GradientButton(
                'Save Catch',
                icon: Icons.check_rounded,
                onPressed: () {
                  if (weight.text.trim().isEmpty ||
                      length.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Add a weight and length to save your catch.',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(
                    context,
                    CatchEntry(
                      species: species,
                      weight: '${weight.text.trim()} kg',
                      length: '${length.text.trim()} cm',
                      spot: spot,
                      date: '${date.day}/${date.month}',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: .9,
      ),
    ),
  );
  Widget _select(String value, IconData icon, VoidCallback onTap) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    child: Row(
      children: [
        Icon(icon, color: AppColors.blue, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.muted),
      ],
    ),
  );
  void _choose(
    String title,
    List<String> options,
    ValueChanged<String> onPick,
  ) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            ...options.map(
              (value) => ListTile(
                title: Text(value),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  onPick(value);
                  Navigator.pop(sheetContext);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _choosePhoto() => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catch photo', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Use a sample photo for this demo catch.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.blue,
              ),
              title: const Text('Use sample sea bass photo'),
              onTap: () {
                setState(() => photoAdded = true);
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
