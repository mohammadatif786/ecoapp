import 'package:get/get.dart';
import 'package:link_up/model/friend_request_model.dart';
import 'package:link_up/model/user_model.dart';
import 'package:link_up/services/linkup_api_service.dart';

class SocialController extends GetxController {
  var likesList = <UserModel>[].obs;
  var matchesList = <UserModel>[].obs;
  var friendsList = <UserModel>[].obs;
  var friendRequests = <FriendRequestModel>[].obs;
  var sentRequests = <FriendRequestModel>[].obs;

  var isLoadingLikes = false.obs;
  var isLoadingMatches = false.obs;
  var isLoadingFriends = false.obs;
  var isLoadingRequests = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  void clearData() {
    likesList.clear();
    matchesList.clear();
    friendsList.clear();
    friendRequests.clear();
    sentRequests.clear();
  }

  void refreshAll() {
    fetchLikes();
    fetchMatches();
    fetchFriends();
    fetchFriendRequests();
  }

  Future<void> fetchLikes() async {
    try {
      isLoadingLikes.value = true;
      final res = await LinkupApiService.fetchLikes();
      likesList.assignAll(res.users);
      print('[Dating] likes tab count=${res.users.length}');
    } catch (e) {
      print('Error fetching likes: $e');
    } finally {
      isLoadingLikes.value = false;
    }
  }

  Future<void> fetchMatches() async {
    try {
      isLoadingMatches.value = true;
      final res = await LinkupApiService.fetchAllMatches();
      matchesList.assignAll(res);
      print('[Dating] matches tab count=${res.length}');
    } catch (e) {
      print('Error fetching matches: $e');
    } finally {
      isLoadingMatches.value = false;
    }
  }

  Future<void> fetchFriends() async {
    try {
      isLoadingFriends.value = true;
      final res = await LinkupApiService.fetchFriends();
      friendsList.assignAll(res.users);
      print('[Dating] friends tab count=${res.users.length}');
    } catch (e) {
      print('Error fetching friends: $e');
    } finally {
      isLoadingFriends.value = false;
    }
  }

  Future<void> fetchFriendRequests() async {
    try {
      isLoadingRequests.value = true;
      final res = await LinkupApiService.fetchFriendRequests();
      friendRequests.assignAll(res.friendRequests);
      sentRequests.assignAll(res.sentRequests);
      print(
        '[Dating] requests received=${res.friendRequests.length} sent=${res.sentRequests.length}',
      );
    } catch (e) {
      print('Error fetching friend requests: $e');
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<void> acceptRequest(int requestId) async {
    try {
      await LinkupApiService.acceptFriendRequest(requestId);
      friendRequests.removeWhere((r) => r.id == requestId);
      fetchFriends();
      Get.snackbar('Success', 'Friend request accepted!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept request: $e');
    }
  }

  Future<void> rejectRequest(int requestId) async {
    try {
      await LinkupApiService.rejectFriendRequest(requestId);
      friendRequests.removeWhere((r) => r.id == requestId);
      Get.snackbar('Success', 'Friend request rejected.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject request: $e');
    }
  }

  Future<void> sendFriendRequest({required String name, required String uid}) async {
    try {
      await LinkupApiService.sendFriendRequest(name: name, uid: uid);
      Get.snackbar('Success', 'Friend request sent!');
      fetchFriendRequests(); // Refresh list if needed
    } catch (e) {
      Get.snackbar('Error', 'Failed to send request: $e');
    }
  }

  Future<void> unfriend(UserModel user) async {
    if (user.laravelId == null) return;
    try {
      await LinkupApiService.unfriend(user.laravelId!);
      friendsList.removeWhere((u) => u.uid == user.uid);
      Get.snackbar('Success', 'Unfriended ${user.firstName}');
    } catch (e) {
      Get.snackbar('Error', 'Failed to unfriend: $e');
    }
  }
}
