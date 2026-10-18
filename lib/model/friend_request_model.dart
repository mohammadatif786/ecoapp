import 'package:link_up/mappers/api_user_mapper.dart';
import 'package:link_up/model/user_model.dart';

class FriendRequestModel {
  final int id;
  final String? uid;
  final int receiverId;
  final int userId;
  final int status;
  final int type;
  final String createdAt;
  final String updatedAt;
  /// Details of the other person (sender if incoming, receiver if outgoing).
  final UserModel? otherUser;

  FriendRequestModel({
    required this.id,
    this.uid,
    required this.receiverId,
    required this.userId,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.otherUser,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    // API uses 'user' for incoming and 'receiver' for outgoing.
    final other = json['user'] ??
        json['receiver'] ??
        json['sender'] ??
        json['friend'] ??
        json['other_user'] ??
        json['profile'];
    UserModel? otherUser;
    if (other is Map) {
      otherUser = ApiUserMapper.tryFromApi(Map<String, dynamic>.from(other));
    } else if (json['name'] != null || json['firstname'] != null || json['avatar'] != null) {
      otherUser = ApiUserMapper.tryFromApi(json);
    }
    return FriendRequestModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      uid: json['uid']?.toString(),
      receiverId: json['receiver_id'] is int
          ? json['receiver_id'] as int
          : int.tryParse(json['receiver_id']?.toString() ?? '') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      status: json['status'] is int
          ? json['status'] as int
          : int.tryParse(json['status']?.toString() ?? '') ?? 0,
      type: json['type'] is int
          ? json['type'] as int
          : int.tryParse(json['type']?.toString() ?? '') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      otherUser: otherUser,
    );
  }
}

class FriendRequestResponse {
  final bool status;
  final List<FriendRequestModel> friendRequests;
  final List<FriendRequestModel> sentRequests;

  FriendRequestResponse({
    required this.status,
    required this.friendRequests,
    required this.sentRequests,
  });

  factory FriendRequestResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final incoming = data['friendRequests'] ??
        data['requests'] ??
        data['incoming'] ??
        data['received'] ??
        data['received_requests'] ??
        data['friend_requests'];
    final outgoing = data['sentRequests'] ??
        data['sent'] ??
        data['outgoing'] ??
        data['sent_requests'];
    List<FriendRequestModel> parseList(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((item) =>
              FriendRequestModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    var incomingList = parseList(incoming);
    var outgoingList = parseList(outgoing);
    if (incomingList.isEmpty && outgoingList.isEmpty) {
      final single = data['data'] ?? json['data'];
      if (single is List) incomingList = parseList(single);
    }
    return FriendRequestResponse(
      status: json['status'] ?? data['status'] ?? false,
      friendRequests: incomingList,
      sentRequests: outgoingList,
    );
  }
}

class FriendListResponse {
  final bool status;
  final List<UserModel> users;
  final UserModel? currentUser;
  final int balance;
  final String? googleApiKey;

  FriendListResponse({
    required this.status,
    required this.users,
    this.currentUser,
    required this.balance,
    this.googleApiKey,
  });

  factory FriendListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final usersRaw = data['users'] ??
        data['friends'] ??
        json['users'] ??
        json['friends'] ??
        (json['data'] is List ? json['data'] : null);
    final List<UserModel> usersList = ApiUserMapper.listFromDatingApi(usersRaw);

    final currentRaw = data['currentUser'] ?? json['currentUser'];
    return FriendListResponse(
      status: json['status'] ?? data['status'] ?? false,
      users: usersList,
      currentUser: currentRaw is Map
          ? ApiUserMapper.tryFromApi(Map<String, dynamic>.from(currentRaw))
          : null,
      balance: int.tryParse(
              (data['balance'] ?? json['balance'])?.toString() ?? '0') ??
          0,
      googleApiKey: (data['google_api_key'] ?? json['google_api_key'])
          ?.toString(),
    );
  }
}
