import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/fishing_location.dart';
import '../../../services/location_service.dart';
import '../../../widgets/premium_widgets.dart';
import '../location_scope.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.detectOnOpen = false,
    this.locationService,
  });
  final bool detectOnOpen;
  final LocationService? locationService;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _searchController = TextEditingController();
  final _mapController = MapController();
  late final _service = widget.locationService ?? LocationService();
  late FishingLocation _pending;
  bool _busy = false;
  int _requestNumber = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pending = FishingLocationScope.of(context).selected;
      setState(() {});
      if (widget.detectOnOpen) _detectLocation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pending = FishingLocationScope.of(context).selected;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    final request = ++_requestNumber;
    setState(() => _busy = true);
    try {
      final result = await _service.detectDeviceLocation();
      if (!mounted || request != _requestNumber) return;
      setState(() => _pending = result);
      FishingLocationScope.of(context).select(result);
      _mapController.move(result.point, 12);
    } catch (error) {
      if (!mounted || request != _requestNumber) return;
      _showError(
        error is LocationServiceException
            ? error.message
            : 'Could not detect your location. Try the map instead.',
      );
    } finally {
      if (mounted && request == _requestNumber) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final request = ++_requestNumber;
    setState(() => _busy = true);
    try {
      final result = await _service.search(_searchController.text);
      if (!mounted || request != _requestNumber) return;
      setState(() => _pending = result);
      _mapController.move(result.point, 11);
    } catch (error) {
      if (!mounted || request != _requestNumber) return;
      _showError(
        error is LocationServiceException
            ? error.message
            : 'Could not find that place.',
      );
    } finally {
      if (mounted && request == _requestNumber) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _choosePoint(LatLng point) async {
    final request = ++_requestNumber;
    setState(() {
      _busy = true;
      _pending = FishingLocation(label: 'Finding place name…', point: point);
    });
    final described = await _service.describePoint(point);
    if (mounted && request == _requestNumber) {
      setState(() {
        _pending = described;
        _busy = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: message.contains('settings')
            ? SnackBarAction(
                label: 'Open settings',
                onPressed: Geolocator.openAppSettings,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _pending;
    return Scaffold(
      appBar: AppBar(title: const Text('Choose location')),
      body: SafeArea(
        child: Column(
          children: [
            ScreenPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text(
                    'Search anywhere or tap a point on the map.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'City, region, or address',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.blue,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Search location',
                        onPressed: _busy ? null : _search,
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  TextButton.icon(
                    onPressed: _busy ? null : _detectLocation,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, size: 19),
                    label: const Text('Use my current location'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                  bottom: Radius.circular(25),
                ),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: selected.point,
                        initialZoom: 10,
                        minZoom: 2,
                        maxZoom: 18,
                        onTap: (_, point) => _choosePoint(point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.fish.mood',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: selected.point,
                              width: 52,
                              height: 62,
                              child: const Icon(
                                Icons.location_pin,
                                size: 48,
                                color: AppColors.blue,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 8,
                      bottom: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .88),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          '© OpenStreetMap contributors',
                          style: TextStyle(color: AppColors.ink, fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ScreenPadding(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 13, 0, 13),
                child: Column(
                  children: [
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            color: AppColors.blue,
                            size: 23,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  selected.coordinates,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                    IgnorePointer(
                      ignoring: _busy,
                      child: GradientButton(
                        _busy ? 'Finding place name…' : 'Use this location',
                        icon: Icons.check_rounded,
                        onPressed: () {
                          FishingLocationScope.of(context).select(selected);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
