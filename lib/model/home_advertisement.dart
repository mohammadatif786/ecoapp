import 'package:link_up/mappers/api_user_mapper.dart';

/// Admin ad from `GET /api/regular-user/home` → `advertisementList`.
class HomeAdvertisement {
  final int id;
  final String name;
  final String headline;
  final String description;
  final String adType;
  final String thumbnailUrl;
  final String imageUrl;
  final String videoUrl;
  final String ctaText;
  final String website;
  final String brandColor;

  const HomeAdvertisement({
    required this.id,
    required this.name,
    required this.headline,
    required this.description,
    required this.adType,
    required this.thumbnailUrl,
    required this.imageUrl,
    required this.videoUrl,
    required this.ctaText,
    required this.website,
    required this.brandColor,
  });

  factory HomeAdvertisement.fromJson(Map<String, dynamic> json) {
    return HomeAdvertisement(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      adType: (json['ad_type'] ?? 'image').toString().toLowerCase(),
      thumbnailUrl: ApiUserMapper.resolveMediaUrl(
        json['thumbnail']?.toString() ?? json['image']?.toString(),
      ),
      imageUrl: ApiUserMapper.resolveMediaUrl(
        json['image_url']?.toString() ?? json['image']?.toString(),
      ),
      videoUrl: ApiUserMapper.resolveMediaUrl(
        json['video_url']?.toString() ?? json['video']?.toString(),
      ),
      ctaText: json['cta_text']?.toString() ?? 'Learn more',
      website: json['www']?.toString() ?? '',
      brandColor: json['brand_color']?.toString() ?? '#38ABD8',
    );
  }

  String get displayImageUrl {
    if (thumbnailUrl.isNotEmpty) return thumbnailUrl;
    if (imageUrl.isNotEmpty) return imageUrl;
    return '';
  }

  bool get isVideo => adType == 'video';
  bool get isAudio => adType == 'audio';
}
