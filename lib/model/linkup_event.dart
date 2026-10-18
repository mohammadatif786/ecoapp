import 'package:link_up/mappers/api_user_mapper.dart';

class LinkupEvent {
  final int id;
  final String title;
  final String slug;
  final String? startTime;
  final String? endTime;
  final String city;
  final String state;
  final String country;
  final String imageUrl;
  final bool isFree;
  final int likesCount;
  final String categoryName;
  final bool isFavourite;
  final String month;
  final String day;

  const LinkupEvent({
    required this.id,
    required this.title,
    required this.slug,
    this.startTime,
    this.endTime,
    required this.city,
    required this.state,
    required this.country,
    required this.imageUrl,
    required this.isFree,
    required this.likesCount,
    required this.categoryName,
    required this.isFavourite,
    required this.month,
    required this.day,
  });

  factory LinkupEvent.fromJson(Map<String, dynamic> json) {
    return LinkupEvent(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      imageUrl: ApiUserMapper.resolveEventImage(json),
      isFree: json['is_free'] == true || json['is_free'] == 1 || json['is_free'].toString().toLowerCase() == 'true',
      likesCount: json['likes_count'] is int ? json['likes_count'] as int : int.tryParse(json['likes_count']?.toString() ?? '') ?? 0,
      categoryName: json['category_name']?.toString() ?? '',
      isFavourite: ApiUserMapper.parseBool(
        json['is_favourite'] ?? json['is_favorite'],
        fallback: false,
      ),
      month: json['month']?.toString() ?? 'JAN',
      day: json['day']?.toString() ?? '1',
    );
  }

  LinkupEvent copyWith({bool? isFavourite}) {
    return LinkupEvent(
      id: id,
      title: title,
      slug: slug,
      startTime: startTime,
      endTime: endTime,
      city: city,
      state: state,
      country: country,
      imageUrl: imageUrl,
      isFree: isFree,
      likesCount: likesCount,
      categoryName: categoryName,
      isFavourite: isFavourite ?? this.isFavourite,
      month: month,
      day: day,
    );
  }
}
