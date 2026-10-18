/// Converts ISO 3166-1 alpha-2 code to flag emoji (e.g. PK → 🇵🇰).
String countryFlagEmoji(String iso2) {
  if (iso2.length != 2) return '';
  final upper = iso2.toUpperCase();
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(upper)) return '';
  return upper.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) + 127397),
  );
}
