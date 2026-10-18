import 'package:link_up/model/user_model.dart';
import 'package:link_up/mappers/api_user_mapper.dart';

class LikesResponse {
  final bool status;
  final List<UserModel> users;
  final UserModel? currentUser;
  final int balance;

  LikesResponse({
    required this.status,
    required this.users,
    this.currentUser,
    required this.balance,
  });

  factory LikesResponse.fromJson(Map<String, dynamic> json) {
    dynamic usersData = json['users'];
    List<dynamic> usersList = [];
    if (usersData is List) {
      usersList = usersData;
    } else if (usersData is Map) {
      final keys = usersData.keys.toList()..sort((a, b) => a.toString().compareTo(b.toString()));
      for (final key in keys) {
        usersList.add(usersData[key]);
      }
    }

    return LikesResponse(
      status: json['status'] ?? false,
      users: usersList
          .map((u) => ApiUserMapper.fromApi(Map<String, dynamic>.from(u)))
          .toList(),
      currentUser: json['currentUser'] != null 
          ? ApiUserMapper.fromApi(Map<String, dynamic>.from(json['currentUser'])) 
          : null,
      balance: json['balance'] is int 
          ? json['balance'] 
          : int.tryParse(json['balance']?.toString() ?? '0') ?? 0,
    );
  }
}
