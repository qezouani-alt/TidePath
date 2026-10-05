class CatchEntry {
  const CatchEntry({
    required this.species,
    required this.weight,
    required this.length,
    required this.spot,
    required this.date,
  });
  final String species, weight, length, spot, date;
}

abstract final class CatchJournal {
  static final entries = <CatchEntry>[
    const CatchEntry(
      species: 'European Sea Bass',
      weight: '3.2 kg',
      length: '58 cm',
      spot: 'Taghazout Coast',
      date: 'Sep 24',
    ),
    const CatchEntry(
      species: 'Gilthead Sea Bream',
      weight: '1.4 kg',
      length: '36 cm',
      spot: 'Agadir Marina',
      date: 'Sep 19',
    ),
    const CatchEntry(
      species: 'Atlantic Mackerel',
      weight: '0.8 kg',
      length: '31 cm',
      spot: 'Aourir Coast',
      date: 'Sep 12',
    ),
  ];
}
