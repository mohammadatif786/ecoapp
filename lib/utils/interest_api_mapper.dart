/// Maps wizard interest labels → API `interests[]` slugs (Postman: `music`, `travel`).
class InterestApiMapper {
  static const _labelToSlug = <String, String>{
    'Music Festivals': 'music',
    'Travel': 'travel',
    'Cooking': 'cooking',
    'Books': 'books',
    'Yoga': 'yoga',
    'Movies': 'movies',
    'Wine': 'wine',
    'Church Events': 'church_events',
    'Liming': 'liming',
    'Carnival / Mas': 'carnival',
    'Junkanoo': 'junkanoo',
    'Soca Fêtes': 'soca',
    'Reggae & Dancehall': 'reggae',
    'Kompa / Zouk': 'kompa',
    'Steel Pan': 'steel_pan',
    'Boat Fêtes': 'boat_fetes',
    'Beach Lime / Bonfire': 'beach',
    'Food & Rum Festivals': 'food_rum',
    'Crop Over': 'crop_over',
    "J'ouvert": 'jouvert',
    'Rake & Scrape': 'rake_scrape',
    'Salsa Socials': 'salsa',
    'Bachata Nights': 'bachata',
    'Reggaetón Parties': 'reggaeton',
    'Cumbia & Vallenato': 'cumbia',
    'Samba Blocos / Pagode': 'samba',
    'Forró Nights': 'forro',
    'Mariachi / Regional Mexicano': 'mariachi',
    'Día de los Muertos (festivals)': 'dia_muertos',
    'Ferias & Street Fairs': 'ferias',
    'Latin Food Fairs': 'latin_food',
    'Folkloric Dance Shows': 'folkloric',
  };

  static String toApiSlug(String label) {
    final trimmed = label.trim();
    if (_labelToSlug.containsKey(trimmed)) {
      return _labelToSlug[trimmed]!;
    }
    return trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static List<String> labelsToSlugs(List<String> labels) {
    return labels.map(toApiSlug).where((s) => s.isNotEmpty).toList();
  }
}
