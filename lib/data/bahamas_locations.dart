/// Mirrors web `resources/js/data/bahamas.ts`.
class BahamasLocation {
  final String name;
  final String code;
  final List<String> cities;

  const BahamasLocation({
    required this.name,
    required this.code,
    required this.cities,
  });
}

const bahamasLocations = <BahamasLocation>[
  BahamasLocation(
    name: 'Abaco',
    code: 'AB',
    cities: [
      'Marsh Harbour',
      'Treasure Cay',
      'Green Turtle Cay',
      'Sandy Point',
      'Hope Town',
    ],
  ),
  BahamasLocation(name: 'Acklins', code: 'AK', cities: ['Snug Corner']),
  BahamasLocation(
    name: 'Andros',
    code: 'AN',
    cities: ['Nicholl\'s Town', 'Fresh Creek', 'Kemps Bay', 'Mangrove Cay'],
  ),
  BahamasLocation(
    name: 'Berry Islands',
    code: 'BY',
    cities: ['Great Harbour Cay'],
  ),
  BahamasLocation(name: 'Bimini', code: 'BI', cities: ['Alice Town']),
  BahamasLocation(
    name: 'Cat Island',
    code: 'CI',
    cities: ['New Bight', 'Arthur\'s Town'],
  ),
  BahamasLocation(
    name: 'Crooked Island',
    code: 'CR',
    cities: ['Colonel Hill'],
  ),
  BahamasLocation(
    name: 'Eleuthera',
    code: 'EL',
    cities: [
      'North Eleuthera',
      'Harbour Island',
      'Spanish Wells',
      'Governor\'s Harbour',
      'Palmetto Point',
      'Tarpum Bay',
      'Wemyss Bight',
      'Green Castle',
      'Waterford',
      'Rock Sound',
    ],
  ),
  BahamasLocation(
    name: 'Exuma',
    code: 'EX',
    cities: ['George Town', 'Black Point'],
  ),
  BahamasLocation(
    name: 'Grand Bahama',
    code: 'GB',
    cities: ['Freeport', 'West End', 'Lucaya', 'High Rock'],
  ),
  BahamasLocation(
    name: 'Inagua',
    code: 'IN',
    cities: ['Matthew Town'],
  ),
  BahamasLocation(
    name: 'Long Island',
    code: 'LI',
    cities: ['Clarence Town', 'Simms'],
  ),
  BahamasLocation(
    name: 'Mayaguana',
    code: 'MG',
    cities: ['Abraham\'s Bay'],
  ),
  BahamasLocation(name: 'Moore\'s Island', code: 'MI', cities: ['Hard Bargain']),
  BahamasLocation(name: 'New Providence', code: 'NP', cities: ['Nassau']),
  BahamasLocation(
    name: 'Ragged Island',
    code: 'RI',
    cities: ['Duncan Town'],
  ),
  BahamasLocation(
    name: 'Rum Cay',
    code: 'RC',
    cities: ['Port Nelson'],
  ),
  BahamasLocation(
    name: 'San Salvador',
    code: 'SS',
    cities: ['Cockburn Town'],
  ),
  BahamasLocation(
    name: 'Spanish Wells',
    code: 'SW',
    cities: ['Spanish Wells'],
  ),
];
