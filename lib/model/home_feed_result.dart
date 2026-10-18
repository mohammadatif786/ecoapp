import 'package:link_up/model/home_advertisement.dart';
import 'package:link_up/model/user_model.dart';

/// Parsed page from `GET /api/regular-user/home?page=N`.
class HomeFeedResult {
  final List<UserModel> users;
  final List<HomeAdvertisement> advertisements;
  final List<Map<String, dynamic>> countries;
  final String walletAmount;
  final int coins;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  /// True when [users] came from `GET /api/match/find` (client-side paging).
  final bool usersFromMatchFind;

  const HomeFeedResult({
    required this.users,
    required this.advertisements,
    this.countries = const [],
    required this.walletAmount,
    required this.coins,
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
    this.usersFromMatchFind = false,
  });

  static const empty = HomeFeedResult(
    users: [],
    advertisements: [],
    countries: [],
    walletAmount: '0',
    coins: 0,
    currentPage: 0,
    lastPage: 0,
    hasMore: false,
  );
}
