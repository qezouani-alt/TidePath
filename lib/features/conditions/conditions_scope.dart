import 'package:flutter/widgets.dart';

import '../../models/fishing_conditions.dart';
import '../../models/fishing_location.dart';
import '../../services/demo_condition_data.dart';
import '../../services/fishing_conditions_repository.dart';

enum ConditionsLoadStatus { loading, ready, fallback }

class FishingConditionsController extends ChangeNotifier {
  FishingConditionsController({
    required FishingLocationController location,
    required this.repository,
  }) : _location = location,
       _current = DemoConditionData.forLocation(location.selected) {
    _location.addListener(_onLocationChanged);
    refresh();
  }

  final FishingLocationController _location;
  final FishingConditionsRepository repository;
  FishingConditions _current;
  ConditionsLoadStatus _status = ConditionsLoadStatus.loading;
  bool _isRefreshing = false;
  int _request = 0;

  FishingConditions get current => _current;
  ConditionsLoadStatus get status => _status;
  bool get showSkeleton => _status == ConditionsLoadStatus.loading;
  bool get isRefreshing => _isRefreshing;

  Future<void> refresh({bool forceRefresh = false}) async {
    final request = ++_request;
    final selected = _location.selected;
    if (_status != ConditionsLoadStatus.loading) {
      _isRefreshing = true;
      notifyListeners();
    }
    try {
      final result = await repository.load(
        selected,
        forceRefresh: forceRefresh,
      );
      if (request != _request) return;
      _current = result;
      _status =
          result.isAllSample ||
              result.updateFailed ||
              result.weather.origin == DataOrigin.sample ||
              result.marine.origin == DataOrigin.sample ||
              result.tide.origin == DataOrigin.sample
          ? ConditionsLoadStatus.fallback
          : ConditionsLoadStatus.ready;
    } catch (_) {
      if (request != _request) return;
      _current = DemoConditionData.forLocation(selected).withUpdateFailed(true);
      _status = ConditionsLoadStatus.fallback;
    }
    _isRefreshing = false;
    notifyListeners();
  }

  void _onLocationChanged() {
    _current = DemoConditionData.forLocation(_location.selected);
    _status = ConditionsLoadStatus.loading;
    _isRefreshing = false;
    notifyListeners();
    refresh();
  }

  @override
  void dispose() {
    _request++;
    _location.removeListener(_onLocationChanged);
    repository.dispose();
    super.dispose();
  }
}

class FishingConditionsScope
    extends InheritedNotifier<FishingConditionsController> {
  const FishingConditionsScope({
    super.key,
    required FishingConditionsController controller,
    required super.child,
  }) : super(notifier: controller);

  static FishingConditions of(BuildContext context) {
    return controllerOf(context).current;
  }

  static FishingConditionsController controllerOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FishingConditionsScope>();
    assert(scope != null, 'FishingConditionsScope is missing from the tree.');
    return scope!.notifier!;
  }
}
