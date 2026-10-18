import 'package:link_up/model/user_model.dart';
import 'package:link_up/mappers/api_user_mapper.dart';

class LiveStreamResponse {
  final bool status;
  final List<LiveStream> streams;
  final List<String> categories;
  final String? activeCategory;

  LiveStreamResponse({
    required this.status,
    required this.streams,
    required this.categories,
    this.activeCategory,
  });

  factory LiveStreamResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return LiveStreamResponse(
      status: json['status'] ?? false,
      streams: (data['streams'] as List? ?? [])
          .map((item) => LiveStream.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      categories: List<String>.from(data['categories'] ?? []),
      activeCategory: data['active_category']?.toString(),
    );
  }
}

class LiveStream {
  final int id;
  final String title;
  final String userId;
  final String status;
  final String streamKey;
  final String? resolution;
  final String? streamUrl;
  final String? playbackUrl;
  final String broadcastType;
  final String? location;
  final String? startTime;
  final String visibility;
  final String subscriptionRate;
  final int likeCount;
  final String? thumbnail;
  final String? coverImage;
  final String imageUrl;
  final bool isPaid;
  final int paidCoins;
  final bool isSubscribed;
  final UserModel? user;

  LiveStream({
    required this.id,
    required this.title,
    required this.userId,
    required this.status,
    required this.streamKey,
    this.resolution,
    this.streamUrl,
    this.playbackUrl,
    required this.broadcastType,
    this.location,
    this.startTime,
    required this.visibility,
    required this.subscriptionRate,
    required this.likeCount,
    this.thumbnail,
    this.coverImage,
    required this.imageUrl,
    required this.isPaid,
    required this.paidCoins,
    required this.isSubscribed,
    this.user,
  });

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    return LiveStream(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      userId: json['user_id']?.toString() ?? '',
      status: json['status'] ?? '',
      streamKey: json['stream_key'] ?? '',
      resolution: json['resolution'],
      streamUrl: json['stream_url'],
      playbackUrl: json['playback_url'],
      broadcastType: json['broadcast_type'] ?? '',
      location: json['location'],
      startTime: json['start_time'],
      visibility: json['visibility'] ?? 'public',
      subscriptionRate: json['subscription_rate']?.toString() ?? '0.00',
      likeCount: json['like_count'] ?? 0,
      thumbnail: json['thumbnail'],
      coverImage: json['cover_image'],
      imageUrl: ApiUserMapper.resolveMediaUrl(json['image_url']?.toString()),
      isPaid: json['is_paid'] == 1 || json['is_paid'] == true,
      paidCoins: json['paid_coins'] ?? 0,
      isSubscribed: json['is_subscribed'] == 1 || json['is_subscribed'] == true,
      user: json['user'] != null ? ApiUserMapper.fromApi(Map<String, dynamic>.from(json['user'])) : null,
    );
  }
}

class LiveCategoriesResponse {
  final bool status;
  final List<String> categories;

  LiveCategoriesResponse({required this.status, required this.categories});

  factory LiveCategoriesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return LiveCategoriesResponse(
      status: json['status'] ?? false,
      categories: List<String>.from(data['categories'] ?? []),
    );
  }
}
