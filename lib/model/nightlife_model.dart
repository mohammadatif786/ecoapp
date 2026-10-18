class NightlifeResult {
  final List<NightlifePlace> clubs;
  final List<NightlifePlace> restaurants;
  final NightlifeLocation? location;

  const NightlifeResult({
    required this.clubs,
    required this.restaurants,
    this.location,
  });

  factory NightlifeResult.fromJson(Map<String, dynamic> json) {
    return NightlifeResult(
      clubs: _places(json['clubs'], kind: 'clubs'),
      restaurants: _places(json['restaurants'], kind: 'restaurants'),
      location: json['location'] is Map
          ? NightlifeLocation.fromJson(Map<String, dynamic>.from(json['location']))
          : null,
    );
  }

  static List<NightlifePlace> _places(dynamic raw, {required String kind}) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => NightlifePlace.fromJson(
              Map<String, dynamic>.from(item),
              kind: kind,
            ))
        .toList();
  }
}

class NightlifeLocation {
  final double latitude;
  final double longitude;
  final String city;
  final String country;

  const NightlifeLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
  });

  factory NightlifeLocation.fromJson(Map<String, dynamic> json) {
    return NightlifeLocation(
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      city: (json['city'] ?? '').toString().trim(),
      country: (json['country'] ?? '').toString().trim(),
    );
  }
}

class NightlifePlace {
  final String placeId;
  final String source;
  final String name;
  final String address;
  final double? rating;
  final String imageUrl;
  final String kind;

  const NightlifePlace({
    required this.placeId,
    required this.source,
    required this.name,
    required this.address,
    required this.rating,
    required this.imageUrl,
    required this.kind,
  });

  String get ratingLabel {
    if (rating == null) return '';
    final value = rating!;
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  factory NightlifePlace.fromJson(
    Map<String, dynamic> json, {
    required String kind,
  }) {
    return NightlifePlace(
      placeId: (json['place_id'] ?? json['placeId'] ?? '').toString().trim(),
      source: (json['source'] ?? '').toString(),
      name: (json['name'] ?? '').toString().trim(),
      address: (json['address'] ?? json['formatted_address'] ?? '').toString().trim(),
      rating: _asDoubleOrNull(json['rating']),
      imageUrl: (json['image'] ?? '').toString().trim(),
      kind: kind,
    );
  }
}

class NightlifePlaceDetail {
  final String placeId;
  final String name;
  final String address;
  final double? rating;
  final int userRatingsTotal;
  final String imageUrl;
  final List<String> photos;
  final String phone;
  final String website;
  final String mapsUrl;
  final double? latitude;
  final double? longitude;
  final List<String> openingHours;
  final bool? openNow;
  final List<NightlifeReview> reviews;

  const NightlifePlaceDetail({
    required this.placeId,
    required this.name,
    required this.address,
    required this.rating,
    required this.userRatingsTotal,
    required this.imageUrl,
    required this.photos,
    required this.phone,
    required this.website,
    required this.mapsUrl,
    required this.latitude,
    required this.longitude,
    required this.openingHours,
    required this.openNow,
    required this.reviews,
  });

  String get ratingLabel {
    if (rating == null) return '';
    final value = rating!;
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  factory NightlifePlaceDetail.fromJson(Map<String, dynamic> json) {
    final source = _unwrap(json);
    final photos = _photoUrls(source);
    final image = (source['image'] ?? source['photo'] ?? '').toString().trim();
    final loc = _location(source);
    return NightlifePlaceDetail(
      placeId: (source['place_id'] ?? '').toString(),
      name: (source['name'] ?? '').toString().trim(),
      address: (source['address'] ??
              source['formatted_address'] ??
              source['vicinity'] ??
              '')
          .toString()
          .trim(),
      rating: _asDoubleOrNull(source['rating']),
      userRatingsTotal: _asInt(source['user_ratings_total'] ??
          source['reviews_count'] ??
          source['rating_count']),
      imageUrl: image.isNotEmpty
          ? image
          : (photos.isNotEmpty ? photos.first : ''),
      photos: photos,
      phone: (source['phone'] ??
              source['formatted_phone_number'] ??
              source['international_phone_number'] ??
              '')
          .toString()
          .trim(),
      website: (source['website'] ?? '').toString().trim(),
      mapsUrl: (source['maps_url'] ?? source['url'] ?? source['google_maps_url'] ?? '')
          .toString()
          .trim(),
      latitude: loc['lat'],
      longitude: loc['lng'],
      openingHours: _hours(source['opening_hours'] ?? source['hours']),
      openNow: _asBoolOrNull(
        source['open_now'] ??
            (source['opening_hours'] is Map
                ? Map<String, dynamic>.from(source['opening_hours'] as Map)['open_now']
                : null),
      ),
      reviews: _reviews(source['reviews']),
    );
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    for (final key in const [
      'place',
      'club',
      'restaurant',
      'clubs',
      'restaurants',
      'result',
      'details',
      'data',
      'payload',
      'item',
      'venue',
    ]) {
      final nested = json[key];
      if (nested is! Map) continue;
      final map = Map<String, dynamic>.from(nested);
      if (map.containsKey('name') ||
          map.containsKey('place_id') ||
          map.containsKey('formatted_address') ||
          map.containsKey('address')) {
        return map;
      }
      return _unwrap(map);
    }
    return json;
  }

  static List<String> _photoUrls(Map<String, dynamic> json) {
    final urls = <String>[];
    void add(dynamic value) {
      if (value == null) return;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.startsWith('http')) urls.add(trimmed);
        return;
      }
      if (value is Map) {
        add(value['url'] ?? value['image'] ?? value['photo_url'] ?? value['src']);
      }
    }

    add(json['image']);
    add(json['photo']);
    final photos = json['photos'];
    if (photos is List) {
      for (final item in photos) {
        add(item);
      }
    }
    return urls.toSet().toList();
  }

  static Map<String, double?> _location(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final nested = geometry is Map ? geometry['location'] : json['location'];
    final loc = nested is Map ? Map<String, dynamic>.from(nested) : json;
    return {
      'lat': _asDoubleOrNull(loc['latitude'] ?? loc['lat']),
      'lng': _asDoubleOrNull(loc['longitude'] ?? loc['lng'] ?? loc['lon']),
    };
  }

  static List<String> _hours(dynamic raw) {
    if (raw is List) {
      return raw.map((item) => item.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is Map) {
      final weekday = raw['weekday_text'] ?? raw['weekdayText'];
      if (weekday is List) {
        return weekday
            .map((item) => item.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  static List<NightlifeReview> _reviews(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => NightlifeReview.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class NightlifeReview {
  final String author;
  final double? rating;
  final String text;
  final String time;
  final String avatarUrl;

  const NightlifeReview({
    required this.author,
    required this.rating,
    required this.text,
    required this.time,
    required this.avatarUrl,
  });

  factory NightlifeReview.fromJson(Map<String, dynamic> json) {
    return NightlifeReview(
      author: (json['author_name'] ?? json['author'] ?? json['name'] ?? '')
          .toString()
          .trim(),
      rating: _asDoubleOrNull(json['rating']),
      text: (json['text'] ?? json['comment'] ?? json['review'] ?? '')
          .toString()
          .trim(),
      time: (json['relative_time_description'] ??
              json['time'] ??
              json['created_at'] ??
              '')
          .toString()
          .trim(),
      avatarUrl:
          (json['profile_photo_url'] ?? json['avatar'] ?? json['photo'] ?? '')
              .toString()
              .trim(),
    );
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool? _asBoolOrNull(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase().trim();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return null;
}
