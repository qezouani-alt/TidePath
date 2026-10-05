import 'package:flutter/widgets.dart';

import '../../models/fishing_location.dart';

class FishingLocationScope
    extends InheritedNotifier<FishingLocationController> {
  const FishingLocationScope({
    super.key,
    required FishingLocationController controller,
    required super.child,
  }) : super(notifier: controller);

  static FishingLocationController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FishingLocationScope>();
    assert(scope != null, 'FishingLocationScope is missing from the tree.');
    return scope!.notifier!;
  }
}
