import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/demo_data.dart';
import '../../../models/fish_catalog.dart';
import '../../../services/fish_catalog_service.dart';
import '../../../widgets/premium_widgets.dart';
import '../screens/fish_catalog_detail_screen.dart';
import '../screens/fish_detail_screen.dart';
import 'fish_catalog_card.dart';

class FishCatalogSection extends StatefulWidget {
  const FishCatalogSection({
    super.key,
    required this.query,
    required this.service,
  });

  final String query;
  final FishCatalogService service;

  @override
  State<FishCatalogSection> createState() => FishCatalogSectionState();
}

class FishCatalogSectionState extends State<FishCatalogSection> {
  Timer? _debounce;
  late String _activeQuery;
  late Future<FishCatalogPage> _future;
  final List<FishCatalogSpecies> _extra = [];
  int _loadedPage = 1;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;

  @override
  void initState() {
    super.initState();
    _activeQuery = widget.query.trim();
    _future = widget.service.load(_activeQuery);
  }

  @override
  void didUpdateWidget(FishCatalogSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextQuery = widget.query.trim();
    if (oldWidget.service != widget.service) {
      _debounce?.cancel();
      _startQuery(nextQuery);
    } else if (nextQuery != oldWidget.query.trim()) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _startQuery(nextQuery));
      });
    }
  }

  void _startQuery(String query) {
    _activeQuery = query;
    _future = widget.service.load(query);
    _extra.clear();
    _loadedPage = 1;
    _loadingMore = false;
    _loadMoreFailed = false;
  }

  Future<void> refresh() async {
    _debounce?.cancel();
    final query = widget.query.trim();
    final request = widget.service.load(query, forceRefresh: true);
    setState(() {
      _activeQuery = query;
      _future = request;
      _extra.clear();
      _loadedPage = 1;
      _loadingMore = false;
      _loadMoreFailed = false;
    });
    await request;
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    final query = _activeQuery;
    final nextPage = _loadedPage + 1;
    final retryAfterFailure = _loadMoreFailed;
    setState(() {
      _loadingMore = true;
      _loadMoreFailed = false;
    });
    final result = await widget.service.load(
      query,
      page: nextPage,
      forceRefresh: retryAfterFailure,
    );
    if (!mounted || query != _activeQuery) return;
    setState(() {
      if (widget.service.isUnavailable(query, page: nextPage)) {
        _loadMoreFailed = true;
      } else {
        final existingIds = _extra.map((fish) => fish.taxonId).toSet();
        _extra.addAll(
          result.species.where((fish) => existingIds.add(fish.taxonId)),
        );
        _loadedPage = nextPage;
      }
      _loadingMore = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.query.trim() != _activeQuery) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Explore species', action: 'Searching'),
          _loadingCard(),
        ],
      );
    }
    return FutureBuilder<FishCatalogPage>(
      future: _future,
      initialData: widget.service.cachedFor(_activeQuery),
      builder: (context, snapshot) {
        final page = snapshot.data;
        final ids = <int>{};
        final all = [
          ...?page?.species,
          ..._extra,
        ].where((fish) => ids.add(fish.taxonId)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              'Explore species',
              action: page == null
                  ? 'Loading'
                  : widget.service.isUnavailable(_activeQuery) && all.isEmpty
                  ? 'Offline'
                  : '${page.total} species',
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 13),
              child: Text(
                'Worldwide fish catalog · iNaturalist · search by common or scientific name',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
            if (page == null)
              _loadingCard()
            else if (widget.service.isUnavailable(_activeQuery) && all.isEmpty)
              _fallback(context)
            else if (all.isEmpty)
              const AppCard(child: Text('No fish found. Try another name.'))
            else
              ...all.map(
                (fish) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: EntryReveal(
                    child: FishCatalogCard(
                      fish: fish,
                      onTap: () => pushPage(
                        context,
                        FishCatalogDetailScreen(fish: fish),
                      ),
                    ),
                  ),
                ),
              ),
            if (page != null &&
                FishCatalogPage(
                  species: const [],
                  total: page.total,
                  page: _loadedPage,
                ).hasMore)
              Center(
                child: TextButton(
                  onPressed: _loadingMore ? null : _loadMore,
                  child: Text(
                    _loadingMore
                        ? 'Loading more…'
                        : _loadMoreFailed
                        ? 'Could not load more · Retry'
                        : 'Show more species',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _loadingCard() => const AppCard(
    child: SizedBox(
      height: 78,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  Widget _fallback(BuildContext context) {
    final query = _activeQuery.toLowerCase();
    final curated = DemoData.fish.where(
      (fish) =>
          fish.name.toLowerCase().contains(query) ||
          fish.scientific.toLowerCase().contains(query),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The worldwide catalog is unavailable. Showing saved guide species.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: refresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry catalog'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        ...curated.map(
          (fish) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: FishCard(
              fish: fish,
              subtitle: 'Saved guide species',
              onTap: () => pushPage(context, FishDetailScreen(fish: fish)),
            ),
          ),
        ),
      ],
    );
  }
}
