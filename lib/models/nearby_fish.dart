class NearbyFish {
  const NearbyFish({
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

  NearbyFish withPhoto({
    required String url,
    required String credit,
    required String license,
    required String sourceUrl,
  }) => NearbyFish(
    taxonId: taxonId,
    name: name,
    scientificName: scientificName,
    observationCount: observationCount,
    photoUrl: url,
    photoCredit: credit,
    photoLicense: license,
    photoSourceUrl: sourceUrl,
  );

  String get observationLabel => observationCount == 1
      ? '1 observation nearby'
      : '$observationCount observations nearby';
}

class NearbyFishPage {
  const NearbyFishPage({
    required this.fish,
    required this.total,
    required this.page,
  });

  final List<NearbyFish> fish;
  final int total;
  final int page;

  bool get hasMore => page * 100 < total;
}
