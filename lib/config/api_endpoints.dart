/// Paths from Postman collection `linkup_apis_new.json` (linkupvibes.com).
class ApiEndpoints {
  static const String login = '/api/login';

  static const String register = '/api/regular-user/register';
  static const String wizardUpdate = '/api/regular-user/wizard-update';
  static const String sendOtp = '/api/regular-user/send-otp';
  static String verifyOtp(String token) => '/api/regular-user/verify-otp/$token';
  static String resendOtp(String token) => '/api/regular-user/resend-otp/$token';

  /// Authenticated regular-user home feed (production mobile route).
  static const String regularUserHome = '/api/regular-user/home';

  /// Wallet balance, transactions and contacts.
  static const String regularUserWallet = '/api/regular-user/user/wallet';
  static const String regularUserWalletContact = '/api/regular-user/wallet/contact';
  static const String regularUserWalletSendMoney = '/api/regular-user/wallet/send-money';
  static const String regularUserWalletRequestMoney = '/api/regular-user/wallet/request-money';
  static const String regularUserWalletActivity = '/api/regular-user/wallet/activity';
  static const String regularUserWalletStripeIntent = '/api/regular-user/wallet/add-amount';
  static const String regularUserWalletSaveData = '/api/regular-user/wallet/save-data';
  static const String regularUserWalletCoinCheckout = '/api/regular-user/wallet/coin/checkout';
  static const String regularUserWalletCoinSaveData = '/api/regular-user/wallet/coin/save-data';
  static const String regularUserWalletTransactionPin = '/api/regular-user/wallet/transaction-pin';
  static const String regularUserWalletVerifyTransactionPin = '/api/regular-user/wallet/verify-transaction-pin';
  static const String regularUserWalletAsueStore = '/api/regular-user/wallet/asues/store';
  static String regularUserWalletAsueAcceptParticipation(int asueId) =>
      '/api/regular-user/wallet/asues/$asueId/accept-participation';
  static String regularUserWalletAsueSimulateAccept(int asueId) =>
      '/api/regular-user/wallet/asues/$asueId/simulate-accept';
  static String regularUserWalletAsueSimulateWeekPayout(int asueId) =>
      '/api/regular-user/wallet/asues/$asueId/simulate-cycle';

  /// Current user profile (Postman: organizer profile → also used after login).
  static const String profile = '/api/profile';

  /// Legacy V1 fallbacks still deployed on production.
  static const String userDetail = '/api/user-detail';
  static const String matchFind = '/api/match/find';
  static String linkupUser(int id) => '/api/match/linkup-user/$id';
  static String specificUser(int id) => '/api/specific-user/$id';
  static const String updateUser = '/api/update-user';
  static const String logout = '/api/logout';
  static const String makeMatch = '/api/home/make-match';

  /// Profile actions (regular-user mobile API).
  static String profileLike(int userId) =>
      '/api/regular-user/profile/like/$userId';
  static String profileDislike(int userId) =>
      '/api/regular-user/profile/dislike/$userId';
  static const String sendGift = '/api/regular-user/send-gift';
  static const String regularUserDetail = '/api/regular-user/user/detail';
  static const String blockUser = '/api/regular-user/profile/block-user';
  static const String unblockUser = '/api/regular-user/profile/unblock-user';
  static const String reportUser = '/api/regular-user/falg-user';
  static const String mutualMatches = '/api/regular-user/matches';
  static const String whoLikesMe = '/api/regular-user/who-likes-me';
  static const String allMatches = '/api/regular-user/all-matches';
  static const String friendRequestIndex = '/api/regular-user/friend-request';
  static String friendRequest(String name, String uid) =>
      '/api/regular-user/friend-request/${Uri.encodeComponent(name)}/${Uri.encodeComponent(uid)}';

  /// Chat (regular-user mobile API).
  static const String chat = '/api/regular-user/user/chat';
  static String chatDetail(String name, String uid) =>
      '/api/regular-user/user/chat/${Uri.encodeComponent(name)}/${Uri.encodeComponent(uid)}';
  static String sendMessage(String id) => '/api/regular-user/send/$id/messages';
  
  static const String events = '/api/regular-user/events';
  static const String eventFavorites = '/api/regular-user/events/favorites';
  static const String eventBookings = '/api/regular-user/events/bookings';
  static String eventDetail(String slug) => '/api/regular-user/events/$slug';
  static String eventToggleFavorite(dynamic eventId) =>
      '/api/regular-user/events/$eventId/toggle-favorite';
  static const String eventOrganizerToggleFollow =
      '/api/regular-user/events/organizer/toggle-follow';
  static String eventReviews(dynamic eventId) => '/api/regular-user/events/$eventId/reviews';
  static String eventReviewDetail(dynamic eventId, dynamic reviewId) => '/api/regular-user/events/$eventId/reviews/$reviewId';

  static const String news = '/api/regular-user/news';
  static String newsDetail(int id) => '/api/regular-user/news/$id';
  static String newsTrending(int id) => '/api/regular-user/news/$id/trending';

  static const String allNotifications = '/api/regular-user/allnotifications';
  static const String markAllNotificationsRead =
      '/api/regular-user/allnotifications/mark-all-read';
  
  static String eventTickets(String slug) => '/api/regular-user/events/$slug/tickets';
  static String buyTicketsStripe(dynamic eventId) => '/api/regular-user/events/$eventId/tickets/buy-stripe';

  static const String likes = '/api/regular-user/likes';

  /// Dating (swipe, find matches, matches, friends, requests, likes, chats).
  static const String dating = '/api/regular-user/dating';
  static const String datingFind = '/api/regular-user/dating/find';
  static const String datingMatches = '/api/regular-user/dating/matches';
  static const String datingFriends = '/api/regular-user/dating/friends';
  static const String datingRequests = '/api/regular-user/dating/requests';
  static const String datingLikes = '/api/regular-user/dating/likes';
  static const String datingChats = '/api/regular-user/dating/chats';
  static const String datingSwipe = '/api/regular-user/dating/swipe';

  static const String friend = '/api/regular-user/friend';
  static String unfriend(int id) => '/api/regular-user/friend/$id/unfriend';
  static String acceptFriendRequest(int id) => '/api/regular-user/accept-friend-request/$id';
  static String rejectFriendRequest(int id) => '/api/regular-user/reject-friend-request/$id/reject';

  static const String liveNetwork = '/api/regular-user/live-streams/network';
  static const String liveCategories = '/api/regular-user/live-streams/categories';

  static const String nightlife = '/api/regular-user/nightlife';
  static String nightlifeDetail(String kind, String placeId) =>
      '/api/regular-user/nightlife/${kind.trim()}/${placeId.trim()}';
}
