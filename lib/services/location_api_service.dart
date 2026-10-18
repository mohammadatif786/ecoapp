import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:link_up/data/bahamas_locations.dart';
import 'package:link_up/services/linkup_api_service.dart';

class CountryOption {
  final String iso2;
  final String name;
  final String flag;

  const CountryOption({
    required this.iso2,
    required this.name,
    required this.flag,
  });
}

/// Countries / states / cities via countriesnow.space (same source as web `/proxy/*`).
/// Uses GET endpoints so mobile avoids Laravel CSRF on POST proxy routes.
class LocationApiService {
  static const _base = 'https://countriesnow.space/api/v0.1';

  static Future<List<CountryOption>> fetchCountries() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/countries'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode >= 400) {
        return _countriesFromProxyFallback();
      }
      final body = jsonDecode(response.body);
      final data = body is Map ? body['data'] : null;
      if (data is! List) return _countriesFromProxyFallback();

      return data
          .map((item) {
            final map = item as Map;
            final name =
                (map['country'] ?? map['name'] ?? '').toString().trim();
            final iso2 = (map['iso2'] ?? '').toString().trim();
            if (name.isEmpty || iso2.isEmpty) return null;
            return CountryOption(
              iso2: iso2,
              name: name,
              flag: _flag(iso2),
            );
          })
          .whereType<CountryOption>()
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) {
      return _countriesFromProxyFallback();
    }
  }

  static Future<List<CountryOption>> _countriesFromProxyFallback() async {
    final rows = await LinkupApiService.fetchCountries();
    return rows
        .map((r) {
          final iso2 = r['value'] ?? '';
          final name = r['label'] ?? '';
          if (iso2.isEmpty || name.isEmpty) return null;
          return CountryOption(iso2: iso2, name: name, flag: _flag(iso2));
        })
        .whereType<CountryOption>()
        .toList();
  }

  static String _flag(String iso2) {
    if (iso2.length != 2) return '';
    final upper = iso2.toUpperCase();
    return upper.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) + 127397),
    );
  }

  static Future<List<String>> fetchStates({
    required String countryIso2,
    required String countryName,
  }) async {
    if (countryIso2 == 'BS') {
      return bahamasLocations.map((s) => s.name).toList();
    }

    final encoded = Uri.encodeQueryComponent(countryName);
    final response = await http
        .get(Uri.parse('$_base/countries/states/q?country=$encoded'))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode >= 400) return [];

    final body = jsonDecode(response.body);
    final data = body is Map ? body['data'] : null;
    if (data is! Map) return [];

    final states = data['states'];
    if (states is! List) return [];

    return states
        .map((s) {
          if (s is Map) return (s['name'] ?? '').toString();
          return s.toString();
        })
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static Future<List<String>> fetchCities({
    required String countryIso2,
    required String countryName,
    required String stateName,
  }) async {
    if (countryIso2 == 'BS') {
      final match = bahamasLocations.where((s) => s.name == stateName);
      if (match.isEmpty) return [];
      return match.first.cities;
    }

    final country = Uri.encodeQueryComponent(countryName);
    final state = Uri.encodeQueryComponent(stateName);
    final response = await http
        .get(Uri.parse(
            '$_base/countries/state/cities/q?country=$country&state=$state'))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode >= 400) return [];

    final body = jsonDecode(response.body);
    final data = body is Map ? body['data'] : null;
    if (data is! List) return [];

    return data.map((c) => c.toString()).where((c) => c.isNotEmpty).toList();
  }
}
