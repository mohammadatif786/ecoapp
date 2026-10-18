import 'package:link_up/mappers/api_user_mapper.dart';

class NewsResponse {
  final bool status;
  final NewsData data;

  NewsResponse({required this.status, required this.data});

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return NewsResponse(
      status: json['status'] == true || json['status'] == 1,
      data: NewsData.fromJson(
        data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
      ),
    );
  }
}

class NewsData {
  final List<NewsItem> news;
  final List<dynamic> newsSource;
  final List<NewsAd> ads;

  NewsData({required this.news, required this.newsSource, required this.ads});

  factory NewsData.fromJson(Map<String, dynamic> json) {
    return NewsData(
      news: (json['news'] as List? ?? [])
          .whereType<Map>()
          .map((item) => NewsItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      newsSource: json['news_source'] as List? ?? [],
      ads: (json['ads'] as List? ?? [])
          .whereType<Map>()
          .map((item) => NewsAd.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class NewsItem {
  final int id;
  final String title;
  final String summary;
  final String body;
  final String imageUrl;
  final String country;
  final String countryCode;
  final String region;
  final String category;
  final String sourceType;
  final String sourceName;
  final String publishedAt;
  final bool isBreaking;
  final String? breakingExpiresAt;
  final int trending;
  final List<NewsMedia> media;
  final bool status;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.imageUrl,
    required this.country,
    required this.countryCode,
    required this.region,
    required this.category,
    required this.sourceType,
    required this.sourceName,
    required this.publishedAt,
    required this.isBreaking,
    this.breakingExpiresAt,
    required this.trending,
    required this.media,
    required this.status,
  });

  DateTime get publishedDate =>
      DateTime.tryParse(publishedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final media = (json['media'] as List? ?? [])
        .whereType<Map>()
        .map((item) => NewsMedia.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final imageFromObject =
        ApiUserMapper.resolveMediaUrl(json['image_object']?.toString());
    final imageFromMedia =
        media.isNotEmpty ? ApiUserMapper.resolveMediaUrl(media.first.dataUrl) : '';
    return NewsItem(
      id: _asInt(json['id']),
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      imageUrl: imageFromObject.isNotEmpty ? imageFromObject : imageFromMedia,
      country: json['country']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? '',
      sourceName: json['sourceName']?.toString() ?? '',
      publishedAt: json['publishedAt']?.toString() ?? '',
      isBreaking: ApiUserMapper.parseBool(json['isBreaking'], fallback: false),
      breakingExpiresAt: json['breakingExpiresAt']?.toString(),
      trending: _asInt(json['trending']),
      media: media,
      status: ApiUserMapper.parseBool(json['status'], fallback: false),
    );
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

class NewsMedia {
  final String type;
  final String name;
  final String dataUrl;
  final int size;

  NewsMedia({required this.type, required this.name, required this.dataUrl, required this.size});

  factory NewsMedia.fromJson(Map<String, dynamic> json) {
    return NewsMedia(
      type: json['type']?.toString() ?? '',
      name: json['name'] ?? '',
      dataUrl: ApiUserMapper.resolveMediaUrl(json['dataUrl']?.toString()),
      size: _asInt(json['size']),
    );
  }
}

class NewsAd {
  final int id;
  final String name;
  final String headline;
  final String description;
  final String category;
  final String adType;
  final String? imageUrl;
  final String? videoUrl;
  final String ctaText;
  final String brandColor;
  final String website;

  NewsAd({
    required this.id,
    required this.name,
    required this.headline,
    required this.description,
    required this.category,
    required this.adType,
    this.imageUrl,
    this.videoUrl,
    required this.ctaText,
    required this.brandColor,
    required this.website,
  });

  factory NewsAd.fromJson(Map<String, dynamic> json) {
    return NewsAd(
      id: _asInt(json['id']),
      name: json['name'] ?? '',
      headline: json['headline'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      adType: json['ad_type']?.toString() ?? json['adType']?.toString() ?? '',
      imageUrl: ApiUserMapper.resolveMediaUrl(json['image_url']?.toString()),
      videoUrl: ApiUserMapper.resolveMediaUrl(json['video_url']?.toString()),
      ctaText: json['cta_text'] ?? '',
      brandColor: json['brand_color'] ?? '#000000',
      website: json['website'] ?? '',
    );
  }
}
