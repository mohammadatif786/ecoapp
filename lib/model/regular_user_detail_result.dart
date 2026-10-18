import 'package:link_up/model/user_model.dart';

/// Response from profile detail APIs (`regular-user/user/detail`, `match/linkup-user`, etc.).
class RegularUserDetailResult {
  final UserModel user;
  final bool isFriends;
  final bool isFriendRequestSent;
  final bool isHiddenByProfileOwner;
  final int? distance;
  final String? linkupId;
  final String? popularityLevel;

  const RegularUserDetailResult({
    required this.user,
    this.isFriends = false,
    this.isFriendRequestSent = false,
    this.isHiddenByProfileOwner = false,
    this.distance,
    this.linkupId,
    this.popularityLevel,
  });
}
