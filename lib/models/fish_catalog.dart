class FishCatalogSpecies {
  const FishCatalogSpecies({
    required this.taxonId,
    required this.name,
    required this.scientificName,
    required this.observationCount,
    this.photoUrl,
    this.photoCredit,
    this.photoLicense,
    this.photoSourceUrl,
  });

  final int taxonId;
  final String name;
  final String scientificName;
  final int observationCount;
  final String? photoUrl;
  final String? photoCredit;
  final String? photoLicense;
  final String? photoSourceUrl;

  String get observationLabel => observationCount == 1
      ? '1 observation worldwide'
      : '$observationCount observations worldwide';

  FishCatalogSpecies withPhoto({
    required String url,
    required String credit,
    required String license,
    required String sourceUrl,
  }) => FishCatalogSpecies(
    taxonId: taxonId,
    name: name,
    scientificName: scientificName,
    observationCount: observationCount,
    photoUrl: url,
    photoCredit: credit,
    photoLicense: license,
    photoSourceUrl: sourceUrl,
  );
}

class FishCatalogPage {
  const FishCatalogPage({
    required this.species,
    required this.total,
    required this.page,
  });

  final List<FishCatalogSpecies> species;
  final int total;
  final int page;

  static const pageSize = 20;

  // iNaturalist limits deep paging. Search can still reach the long tail.
  bool get hasMore => page * pageSize < total && page * pageSize < 10000;
}
