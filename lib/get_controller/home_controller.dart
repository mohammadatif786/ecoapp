import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/get_controller/base_controller.dart';
import 'package:link_up/model/home_advertisement.dart';
import 'package:link_up/model/user_model.dart';
import 'package:link_up/services/linkup_api_service.dart';
import 'package:link_up/utils/swipe_console_log.dart';

enum SwipeAction { like, dislike, love }

class HomeController extends BaseController {
  static const int usersPerAd = 5;
  static const int usersPerPage = 10;
  static const double prefetchDragProgress = 40;

  AuthController authController = Get.find(tag: AuthController().toString());

  RxList swipeCards = [].obs;
  RxList<UserModel> exploreList = <UserModel>[].obs;
  RxList<UserModel> findMatchCards = <UserModel>[].obs;
  RxBool findMatchesLoaded = false.obs;
  RxBool isLoadingFindMatches = false.obs;
  RxInt missedMessageLength = 0.obs;
  RxBool loadingMore = false.obs;
  Rx? timer;

  final List<HomeAdvertisement> advertisements = [];
  final List<Map<String, dynamic>> countries = [];
  String walletAmount = '0';
  int coins = 0;

  int _currentPage = 0;
  int _lastPage = 1;
  bool _hasMorePages = true;

  bool get hasMorePages => _hasMorePages;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  bool _prefetchRequested = false;
  int _usersSinceLastAd = 0;
  int _adRotationIndex = 0;
  int _usersSwipedInCurrentPage = 0;
  int _totalProfileSwipes = 0;
  RxBool feedLoaded = false.obs;
  RxBool feedEmpty = false.obs;

  /// Remaining profiles when loaded via `match/find` (paginated 10 at a time).
  final List<UserModel> _matchFindBuffer = [];
  bool _usingMatchFindBuffer = false;

  Future<void> sendVibeGift(
    UserModel target, {
    required String giftName,
    required int cost,
  }) async {
    final receiverId = target.laravelId ?? int.tryParse(target.uid ?? '');
    if (receiverId == null) {
      throw LinkupApiException('Missing receiver id');
    }
    final remaining = await LinkupApiService.sendGift(
      receiverId: receiverId,
      giftName: giftName,
      coins: cost,
    );
    if (remaining != null) {
      coins = remaining;
    } else {
      coins = (coins - cost).clamp(0, 1 << 30);
    }
    update();
  }

  Future<void> recordSwipe(UserModel target, SwipeAction action) async {
    final targetId =
        target.laravelId ?? int.tryParse(target.uid ?? '');
    if (targetId == null) {
      debugPrint('recordSwipe skipped — no target_id for ${target.firstName}');
      return;
    }
    final actionName = action == SwipeAction.dislike
        ? 'dislike'
        : (action == SwipeAction.love ? 'love' : 'like');
    try {
      final isMatch = await LinkupApiService.datingSwipe(
        targetId: targetId,
        action: actionName,
      );
      debugPrint(
        '[Dating] swipe ok target_id=$targetId action=$actionName match=$isMatch',
      );
    } catch (e) {
      debugPrint('recordSwipe dating/swipe failed: $e');
      try {
        if (action == SwipeAction.dislike) {
          await LinkupApiService.profileDislike(targetId);
        } else {
          await LinkupApiService.profileLike(targetId);
        }
      } catch (e2) {
        debugPrint('recordSwipe fallback failed: $e2');
      }
    }
  }

  void _resetFeedState() {
    swipeCards.clear();
    exploreList.clear();
    advertisements.clear();
    countries.clear();
    walletAmount = '0';
    coins = 0;
    _currentPage = 0;
    _lastPage = 1;
    _hasMorePages = true;
    loadingMore.value = false;
    _prefetchRequested = false;
    _usersSinceLastAd = 0;
    _adRotationIndex = 0;
    _usersSwipedInCurrentPage = 0;
    _totalProfileSwipes = 0;
    feedLoaded.value = false;
    feedEmpty.value = false;
    _matchFindBuffer.clear();
    _usingMatchFindBuffer = false;
  }

  List<UserModel> _withoutSelf(List<UserModel> users) {
    final currentUid = authController.user?.value.uid;
    final currentApiId =
        authController.user?.value.laravelId?.toString() ?? '';
    return users.where((profile) {
      final profileUid = profile.uid ?? '';
      final profileId = profile.laravelId?.toString() ?? '';
      if (profileId.isEmpty && profileUid.isEmpty) return false;
      final isSelf = (profileUid.isNotEmpty && profileUid == currentUid) ||
          (profileId.isNotEmpty &&
              (profileId == currentUid || profileId == currentApiId));
      return !isSelf;
    }).toList();
  }

  Future<void> fetchFindMatchCards() async {
    if (isLoadingFindMatches.value) return;
    isLoadingFindMatches.value = true;
    try {
      final users = await LinkupApiService.fetchDatingFind();
      findMatchCards.assignAll(_withoutSelf(users));
      debugPrint('[Dating] find cards=${findMatchCards.length}');
    } catch (e) {
      debugPrint('[Dating] find cards error: $e');
      if (findMatchCards.isEmpty && exploreList.isNotEmpty) {
        findMatchCards.assignAll(exploreList.toList());
      }
    } finally {
      isLoadingFindMatches.value = false;
      findMatchesLoaded.value = true;
      update();
    }
  }

  void _applyWalletFromResult({required String amount, required int coinCount}) {
    walletAmount = amount;
    coins = coinCount;
  }

  void applyWallet({required String amount, required int coinCount}) {
    _applyWalletFromResult(amount: amount, coinCount: coinCount);
  }

  void _mergeAdvertisements(List<HomeAdvertisement> incoming) {
    for (final ad in incoming) {
      if (!advertisements.any((existing) => existing.id == ad.id)) {
        advertisements.add(ad);
      }
    }
    debugPrint(
      'HOME_FEED|ads pool=${advertisements.length} '
      '(${advertisements.map((a) => a.headline).join(', ')})',
    );
  }

  void _appendUsersToFeed(List<UserModel> users) {
    final currentUid = authController.user?.value.uid;
    final currentApiId =
        authController.user?.value.laravelId?.toString() ?? '';
    var added = 0;
    for (final profile in users) {
      final profileUid = profile.uid ?? '';
      final profileId = profile.laravelId?.toString() ?? '';
      if (profileId.isEmpty && profileUid.isEmpty) {
        debugPrint(
          'HOME_FEED|skip empty ids name=${profile.firstName}',
        );
        continue;
      }

      final isSelf = (profileUid.isNotEmpty && profileUid == currentUid) ||
          (profileId.isNotEmpty &&
              currentApiId.isNotEmpty &&
              (profileId == currentUid || profileId == currentApiId));
      if (isSelf) {
        debugPrint(
          'HOME_FEED|skip self id=$profileId uid=$profileUid current=$currentUid api=$currentApiId',
        );
        continue;
      }
      exploreList.add(profile);
      swipeCards.add(profile);
      added++;
    }
    debugPrint('HOME_FEED|appended $added/${users.length} profiles');
  }

  void _takeFirstPageFromMatchFind(List<UserModel> allUsers) {
    _matchFindBuffer.clear();
    _usingMatchFindBuffer = true;
    if (allUsers.length <= usersPerPage) {
      _appendUsersToFeed(allUsers);
      _hasMorePages = false;
      return;
    }
    _appendUsersToFeed(allUsers.take(usersPerPage).toList());
    _matchFindBuffer.addAll(allUsers.skip(usersPerPage));
    _hasMorePages = _matchFindBuffer.isNotEmpty;
    _currentPage = 1;
    _lastPage = (allUsers.length / usersPerPage).ceil();
  }

  void _appendNextMatchFindPage() {
    if (_matchFindBuffer.isEmpty) {
      _hasMorePages = false;
      return;
    }
    final chunk = _matchFindBuffer.take(usersPerPage).toList();
    _matchFindBuffer.removeRange(0, chunk.length);
    _currentPage++;
    _hasMorePages = _matchFindBuffer.isNotEmpty;
    _appendUsersToFeed(chunk);
  }

  /// After every 5 profile swipes, queue an ad as the next card.
  void _maybeInjectAdCard() {
    if (_usersSinceLastAd < usersPerAd || advertisements.isEmpty) return;
    final ad = advertisements[_adRotationIndex % advertisements.length];
    _adRotationIndex++;
    _usersSinceLastAd = 0;
    swipeCards.add(ad);
    debugPrint('HOME_FEED|injected ad id=${ad.id} headline=${ad.headline}');
  }

  Future<void> _loadPage(int page, {required bool reset}) async {
    if (_usingMatchFindBuffer && page > 1 && !reset) {
      _appendNextMatchFindPage();
      feedLoaded.value = true;
      feedEmpty.value = swipeCards.isEmpty;
      debugPrint(
        'HOME_FEED|match/find buffer page=$_currentPage '
        'remaining=${_matchFindBuffer.length} cards=${swipeCards.length}',
      );
      return;
    }

    final result = await LinkupApiService.fetchExploreHomePage(page: page);
    _applyWalletFromResult(
      amount: result.walletAmount,
      coinCount: result.coins,
    );
    _mergeAdvertisements(result.advertisements);
    if (result.countries.isNotEmpty) {
      countries.clear();
      countries.addAll(result.countries);
    }
    if (reset) {
      _usersSinceLastAd = 0;
      _usersSwipedInCurrentPage = 0;
      _matchFindBuffer.clear();
      _usingMatchFindBuffer = false;
    }

    if (result.usersFromMatchFind && result.users.isNotEmpty) {
      _takeFirstPageFromMatchFind(result.users);
    } else {
      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _hasMorePages = result.hasMore;
      _appendUsersToFeed(result.users);
    }

    feedLoaded.value = true;
    feedEmpty.value = swipeCards.isEmpty;
    if (reset) {
      _prefetchRequested = false;
    }
    debugPrint(
      'HOME_FEED|page=$_currentPage last=$_lastPage hasMore=$_hasMorePages '
      'cards=${swipeCards.length} users=${exploreList.length}',
    );
  }

  Future<void> fetchExploreList({
    required String nationality,
    required String userID,
    required String linkMeWith,
  }) async {
    _resetFeedState();

    final apiToken = await LinkupApiService.getToken();
    print(
      '${SwipeConsoleLog.tag}|fetchExploreList|start|hasToken=${apiToken != null && apiToken.isNotEmpty}',
    );
    if (apiToken == null || apiToken.isEmpty) {
      SwipeConsoleLog.printCards(const [], source: 'No API session');
      update();
      return;
    }

    try {
      await _loadPage(1, reset: true);
      SwipeConsoleLog.printCards(
        swipeCards,
        source: 'API · page 1 · ${exploreList.length} users · ${advertisements.length} ads',
      );
      update();
    } catch (e) {
      print('${SwipeConsoleLog.tag}|API_ERROR|$e');
      SwipeConsoleLog.printCards(const [], source: 'API error');
      update();
    }
  }

  /// Half-drag on card 6+ of the current batch (after 5 profile swipes).
  void maybePrefetchNextPage(double progress) {
    if (!_hasMorePages || loadingMore.value || _prefetchRequested) return;
    if (_usersSwipedInCurrentPage < (usersPerPage ~/ 2)) return;
    if (progress < prefetchDragProgress) return;
    _startLoadNextPage(reason: 'half-drag');
  }

  void _startLoadNextPage({required String reason}) {
    if (!_hasMorePages || loadingMore.value || _prefetchRequested) return;
    _prefetchRequested = true;
    debugPrint('HOME_FEED|loadNextPage triggered ($reason)');
    loadNextPage();
  }

  Future<void> loadNextPage() async {
    if (!_hasMorePages || loadingMore.value) return;
    loadingMore.value = true;
    update();
    final started = DateTime.now();
    try {
      await _loadPage(_currentPage + 1, reset: false);
      _usersSwipedInCurrentPage = 0;
      _prefetchRequested = false;
      SwipeConsoleLog.printCards(
        swipeCards,
        source: 'API · page $_currentPage · ${swipeCards.length} cards',
      );
    } catch (e) {
      debugPrint('loadNextPage failed: $e');
      _prefetchRequested = false;
    } finally {
      final elapsed = DateTime.now().difference(started);
      const minLoader = Duration(milliseconds: 500);
      if (elapsed < minLoader) {
        await Future.delayed(minLoader - elapsed);
      }
      loadingMore.value = false;
      update();
    }
  }

  /// Called when a card leaves the stack (sync [swipeCards] + ads + pagination).
  void onCardSwiped(dynamic item) {
    if (swipeCards.isNotEmpty) {
      swipeCards.removeLast();
    }

    if (item is UserModel) {
      _usersSwipedInCurrentPage++;
      _usersSinceLastAd++;
      _totalProfileSwipes++;

      _maybeInjectAdCard();

      // After 10 profile swipes in this batch → fetch next page.
      if (_usersSwipedInCurrentPage >= usersPerPage) {
        _startLoadNextPage(reason: 'batch-complete');
      }
    }

    update();
  }

  Future<void> missedMessage() async {
    final apiToken = await LinkupApiService.getToken();
    if (apiToken != null && apiToken.isNotEmpty) {
      missedMessageLength.value = 0;
      return;
    }
  }
}
