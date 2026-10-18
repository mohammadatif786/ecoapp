import 'package:link_up/mappers/api_user_mapper.dart';
import 'package:link_up/model/user_model.dart';

class ChatListResponse {
  final List<ChatUser> users;

  ChatListResponse({required this.users});

  factory ChatListResponse.fromJson(Map<String, dynamic> json) {
    final usersList = json['users'] as List? ?? [];
    final users = <ChatUser>[];
    for (final item in usersList) {
      if (item is! Map) continue;
      try {
        users.add(ChatUser.fromJson(Map<String, dynamic>.from(item)));
      } catch (e) {
        print('[Chat] skip user parse error: $e item=$item');
      }
    }
    return ChatListResponse(users: users);
  }
}

class ChatUser {
  final int id;
  final String uid;
  final String name;
  final String avatar;
  final bool pinned;
  final ChatMessage? lastMessage;
  final UserModel userModel;

  ChatUser({
    required this.id,
    required this.uid,
    required this.name,
    required this.avatar,
    required this.pinned,
    required this.userModel,
    this.lastMessage,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    ChatMessage? lastMsg;
    final lastMsgData = json['last_message'];
    if (lastMsgData is Map) {
      lastMsg = ChatMessage.fromJson(Map<String, dynamic>.from(lastMsgData));
    } else if (lastMsgData is List && lastMsgData.isNotEmpty && lastMsgData.first is Map) {
      lastMsg = ChatMessage.fromJson(Map<String, dynamic>.from(lastMsgData.first));
    }

    final name = (json['name'] ?? '').toString().trim();
    final uid = (json['uid'] ?? '').toString().trim();
    final id = (json['id'] as num?)?.toInt() ?? int.tryParse(json['id']?.toString() ?? '') ?? 0;
    final avatar = ApiUserMapper.resolveMediaUrl(json['avatar']?.toString());

    UserModel user;
    try {
      user = ApiUserMapper.fromApi({
        'id': id,
        'uid': uid,
        'name': name,
        'avatar': avatar,
      });
    } catch (_) {
      user = UserModel(
        firstName: name.split(' ').first,
        lastName: name.split(' ').skip(1).join(' '),
        avatar: avatar,
        uid: uid,
        countryCode: '',
        country: '',
        aboutMe: '',
        age: 0,
        birthday: 0,
        email: '',
        gender: 'Male',
        interests: const [],
        job: '',
        morePhotos: const [],
        linkWithMePhoneCode: '',
        phoneNumber: '',
        status: true,
        whyarewehere: '',
        university: '',
        ageFilter: const [],
        distanceFilter: const [],
        isGhost: false,
        isClub: false,
        isRestaurant: false,
        isTopShelf: false,
        isLiveStream: false,
        language: '',
        linkMeWith: '',
        linkMeWithCountryCode: '',
        whichLatinCountryYouLinkedWith: '',
        newMatchNotification: true,
        newMessageNotification: true,
        promotionNotification: true,
        lastActive: 0,
        createdAt: 0,
        updatedAt: 0,
        subscription: const [],
        stripeCustomerId: '',
        newCity1: '',
        newCountry1: '',
        newState1: '',
        phoneNumberDialCode: '',
      );
      user.laravelId = id;
    }

    return ChatUser(
      id: id,
      uid: uid,
      name: name,
      avatar: avatar,
      pinned: _parsePinned(json['pinned']),
      lastMessage: lastMsg,
      userModel: user,
    );
  }

  static bool _parsePinned(dynamic value) {
    if (value == true || value == 1) return true;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1';
    }
    return false;
  }
}

class ChatMessage {
  final int id;
  final int fromUserId;
  final int toUserId;
  final String content;
  final String type;
  final String createdAt;
  final int isRead;

  ChatMessage({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fromUserId: (json['from_user_id'] as num?)?.toInt() ?? 0,
      toUserId: (json['to_user_id'] as num?)?.toInt() ?? 0,
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      createdAt: json['created_at']?.toString() ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1 ? 1 : 0,
    );
  }

  String get preview {
    final raw = content.trim();
    if (raw.isEmpty) return 'No messages yet';
    final lower = raw.toLowerCase();
    if (raw.startsWith('__CALL_END__')) {
      return lower.contains('video') ? 'Video call ended' : 'Call ended';
    }
    if (raw.startsWith('__CALL_INVITE_AUDIO__')) return 'Voice call';
    if (raw.startsWith('__CALL_INVITE__')) return 'Video call';
    if (raw.startsWith('📍') || lower.contains('maps.google.com') || lower.contains('maps.apple.com')) {
      return '📍 Location';
    }
    if (type == 'image' || type == 'photo') return '📷 Photo';
    if (type == 'pdf') return '📎 PDF';
    if (type == 'gif') return 'GIF';
    if (type == 'sticker') return 'Sticker';
    return raw;
  }

  int get timestampMs {
    final parsed = DateTime.tryParse(createdAt);
    return parsed?.millisecondsSinceEpoch ?? 0;
  }
}
