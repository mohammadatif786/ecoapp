import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:link_up/config/api_config.dart';
import 'package:link_up/model/user_model.dart';

/// Maps Laravel API user JSON into [UserModel] (Firebase-shaped for existing UI).
class ApiUserMapper {
  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final trimmed = path.trim();
    if (trimmed == '[]' || trimmed == 'null') return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    var relative = trimmed;
    while (relative.startsWith('/')) {
      relative = relative.substring(1);
    }
    if (relative.isEmpty) return '';
    if (relative.startsWith('storage/')) {
      return '${ApiConfig.baseUrl}/$relative';
    }
    // Laravel public disk: more_photos/foo.png → /storage/more_photos/foo.png
    return '${ApiConfig.baseUrl}/storage/$relative';
  }

  /// First usable media URL from a string, list, or `{url|path|image_url}` map.
  static String extractMediaUrl(dynamic value) {
    if (value == null) return '';
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == '[]' || trimmed == 'null') return '';
      if ((trimmed.startsWith('[') && trimmed.endsWith(']')) ||
          (trimmed.startsWith('{') && trimmed.endsWith('}'))) {
        try {
          return extractMediaUrl(jsonDecode(trimmed));
        } catch (_) {}
      }
      return resolveMediaUrl(trimmed);
    }
    if (value is List) {
      for (final item in value) {
        final url = extractMediaUrl(item);
        if (url.isNotEmpty) return url;
      }
      return '';
    }
    if (value is Map) {
      for (final key in const [
        'image_url',
        'url',
        'path',
        'image',
        'src',
        'original',
        'full',
        'thumbnail',
        'cover',
        'file',
      ]) {
        if (value[key] == null) continue;
        final url = extractMediaUrl(value[key]);
        if (url.isNotEmpty) return url;
      }
    }
    return '';
  }

  static List<String> extractMediaUrls(dynamic value) {
    if (value == null) return const [];
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == '[]' || trimmed == 'null') {
        return const [];
      }
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          return extractMediaUrls(jsonDecode(trimmed));
        } catch (_) {}
      }
      final one = extractMediaUrl(trimmed);
      return one.isEmpty ? const [] : [one];
    }
    if (value is List) {
      return value
          .map(extractMediaUrl)
          .where((url) => url.isNotEmpty)
          .toList();
    }
    final one = extractMediaUrl(value);
    return one.isEmpty ? const [] : [one];
  }

  /// Cover image for list/detail event payloads (`image_url` may be a list).
  static String resolveEventImage(Map<String, dynamic> json) {
    const keys = [
      'image_url',
      'image',
      'cover_image',
      'cover',
      'thumbnail',
      'banner',
      'photo',
      'featured_image',
      'event_image',
    ];
    for (final key in keys) {
      if (!json.containsKey(key) || json[key] == null) continue;
      final url = extractMediaUrl(json[key]);
      if (url.isNotEmpty) return url;
    }
    final details = json['event_details'];
    if (details is Map) {
      final fromDetails = extractMediaUrl(
        details['image_gallery'] ?? details['images'] ?? details['image'],
      );
      if (fromDetails.isNotEmpty) return fromDetails;
    }
    return extractMediaUrl(json['image_gallery'] ?? json['images']);
  }

  static String? asNullableString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == 'null' || trimmed == '[]') return null;
      return value;
    }
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      final parts = <String>[];
      for (final item in value) {
        final part = asNullableString(item);
        if (part != null && part.trim().isNotEmpty) parts.add(part);
      }
      return parts.isEmpty ? null : parts.join(', ');
    }
    if (value is Map) {
      return asNullableString(
        value['name'] ??
            value['title'] ??
            value['label'] ??
            value['value'] ??
            value['url'] ??
            value['path'],
      );
    }
    return value.toString();
  }

  static String asString(dynamic value, [String fallback = '']) {
    return asNullableString(value) ?? fallback;
  }

  static int parseTimestamp(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }
    return 0;
  }

  static bool parseBool(dynamic value, {bool fallback = true}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return fallback;
  }

  static String capitalizeGender(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Male';
    if (raw.length == 1) return raw.toUpperCase();
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  static List<String> stringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String && value.startsWith('[') && value.endsWith(']')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (e) {
        debugPrint('ApiUserMapper.stringList decode failed: $e');
      }
    }
    return [value.toString()];
  }

  static Map<String, dynamic> normalize(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);

    final firstName = (map['first_name'] ?? '').toString();
    final fullName = (map['name'] ?? '').toString().trim();
    if (firstName.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      map['first_name'] = parts.first;
      map['last_name'] =
          parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    // Keep Firebase `uid` separate from Laravel numeric `id` (used in laravelId).
    final uid = map['uid']?.toString().trim();
    if (uid == null || uid.isEmpty) {
      map['uid'] = '';
    } else {
      map['uid'] = uid;
    }

    if ((map['city']?.toString() ?? '').isNotEmpty &&
        (map['new_city']?.toString() ?? '').isEmpty) {
      map['new_city'] = map['city'];
    }

    final caribbeanInterest = map['caribbean_interest']?.toString().trim();
    if (caribbeanInterest != null && caribbeanInterest.isNotEmpty) {
      map['country'] = caribbeanInterest;
    }

    map['gender'] = capitalizeGender(map['gender']?.toString());
    final linkMeWith = (map['link_me_with'] ?? 'Female').toString();
    map['link_me_with'] = linkMeWith.toLowerCase() == 'both'
        ? 'Both'
        : capitalizeGender(linkMeWith);

    map['birthday'] = parseTimestamp(map['birthday']);
    final now = DateTime.now().millisecondsSinceEpoch;
    map['last_active'] =
        parseTimestamp(map['last_active']).clamp(1, now);
    map['created_at'] =
        parseTimestamp(map['created_at']).clamp(1, now);
    map['updated_at'] =
        parseTimestamp(map['updated_at']).clamp(1, now);
    if (map['last_active'] == 0) map['last_active'] = now;
    if (map['created_at'] == 0) map['created_at'] = now;
    if (map['updated_at'] == 0) map['updated_at'] = now;
    map['status'] = parseBool(map['status'] ?? map['is_active'], fallback: true);

    if ((map['whyarewehere']?.toString() ?? '').isEmpty &&
        map['whyare'] != null) {
      map['whyarewehere'] = map['whyare'].toString();
    }
    if ((map['new_city1']?.toString() ?? '').isEmpty &&
        map['new_city'] != null) {
      map['new_city1'] = map['new_city'].toString();
    }
    if ((map['new_country1']?.toString() ?? '').isEmpty &&
        map['new_country'] != null) {
      map['new_country1'] = map['new_country'].toString();
    }
    if ((map['new_state1']?.toString() ?? '').isEmpty &&
        map['new_state'] != null) {
      map['new_state1'] = map['new_state'].toString();
    }

    map['age_filter'] = stringList(map['age_filter']);
    map['distance_filter'] = stringList(map['distance_filter']);
    map['interests'] = stringList(map['interests']);
    final morePhotos = stringList(map['more_photos'])
        .map(resolveMediaUrl)
        .where((u) => u.isNotEmpty)
        .toList();
    map['more_photos'] = morePhotos;

    var avatar = resolveMediaUrl(map['avatar']?.toString());
    if (avatar.isEmpty && morePhotos.isNotEmpty) {
      avatar = morePhotos.first;
    }
    map['avatar'] = avatar;

    final countryCode =
        (map['country_code'] ?? map['which_latin_country_you_linked_with'] ?? 'BS')
            .toString()
            .toUpperCase();
    map['country_code'] = countryCode;
    map['which_latin_country_you_linked_with'] = countryCode;

    if (map['distance'] != null) {
      map['distance'] = map['distance'].toString();
    }

    return map;
  }

  static UserModel fromApi(Map<String, dynamic> json) {
    final model = UserModel.fromJson(normalize(json));
    model.laravelId = (json['id'] as num?)?.toInt() ??
        int.tryParse(json['user_id']?.toString() ?? '');
    return model;
  }

  static UserModel? tryFromApi(Map<String, dynamic> json) {
    try {
      return fromApi(json);
    } catch (e, stack) {
      debugPrint('ApiUserMapper.tryFromApi failed: $e\n$stack');
      return null;
    }
  }

  /// Dating payloads often wrap the person in `user` / `profile` / `friend`.
  static Map<String, dynamic> unwrapPersonMap(Map raw) {
    final map = Map<String, dynamic>.from(raw);
    final looksLikeUser = map['name'] != null ||
        map['first_name'] != null ||
        map['firstname'] != null ||
        map['avatar'] != null ||
        map['email'] != null;
    if (looksLikeUser) return map;
    const nestedKeys = [
      'user',
      'profile',
      'matched_user',
      'other_user',
      'sender',
      'receiver',
      'friend',
      'liked_by',
      'liker',
    ];
    for (final key in nestedKeys) {
      final nested = map[key];
      if (nested is Map) {
        final person = Map<String, dynamic>.from(nested);
        person['id'] ??=
            map['user_id'] ?? map['matched_user_id'] ?? map['friend_id'] ?? map['id'];
        person['uid'] ??= map['uid'] ?? person['uid'];
        return person;
      }
    }
    return map;
  }

  static List<UserModel> listFromDatingApi(dynamic data) {
    if (data is Map) {
      if (data['data'] is List) return listFromDatingApi(data['data']);
      return listFromDatingApi(data.values.toList());
    }
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => tryFromApi(unwrapPersonMap(item)))
        .whereType<UserModel>()
        .toList();
  }

  static List<UserModel> listFromApi(dynamic data) {
    if (data is Map) return listFromApi(data.values.toList());
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => tryFromApi(Map<String, dynamic>.from(item)))
        .whereType<UserModel>()
        .toList();
  }
}
