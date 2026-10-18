import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:link_up/config/api_config.dart';
import 'package:link_up/config/api_endpoints.dart';
import 'package:link_up/mappers/api_user_mapper.dart';
import 'package:link_up/model/event_booking_model.dart';
import 'package:link_up/model/event_detail_model.dart';
import 'package:link_up/model/events_response.dart';
import 'package:link_up/model/linkup_event.dart';
import 'package:link_up/model/likes_response.dart';
import 'package:link_up/model/news_model.dart';
import 'package:link_up/model/notification_model.dart';
import 'package:link_up/model/nightlife_model.dart';
import 'package:link_up/model/home_advertisement.dart';
import 'package:link_up/model/home_feed_result.dart';
import 'package:link_up/model/wallet_result.dart';
import 'package:link_up/model/chat_list_model.dart';
import 'package:link_up/model/chatModel.dart';
import 'package:link_up/model/friend_request_model.dart';
import 'package:link_up/model/recent_chat.dart';
import 'package:link_up/model/chat_detail_result.dart';
import 'package:link_up/model/regular_user_detail_result.dart';
import 'package:link_up/model/user_model.dart';
import 'package:link_up/model/live_stream_model.dart';
import 'package:link_up/utils/interest_api_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LinkupApiException implements Exception {
  final String message;
  final int? statusCode;

  LinkupApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// HTTP client aligned with Postman `linkup_apis_new.json` (multipart + `/api/regular-user/*`).
class LinkupApiService {
  static const _tokenKey = 'linkup_api_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Map<String, String> _headers({String? token, bool json = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  static Never _throwFromResponse(http.Response response) {
    final body = _decodeBody(response);
    String message = 'Request failed (${response.statusCode})';
    if (body is Map) {
      message = body['message']?.toString() ??
          body['error']?.toString() ??
          body['msg']?.toString() ??
          message;
    } else if (body is String) {
      final trimmed = body.trim();
      if (trimmed.startsWith('<')) {
        message =
            'Server error (${response.statusCode}). Please try again later.';
      } else if (trimmed.isNotEmpty) {
        message = trimmed.length > 120 ? trimmed.substring(0, 120) : trimmed;
      }
    }
    throw LinkupApiException(message, statusCode: response.statusCode);
  }

  static String _formatLinkupId(String linkupId) {
    final trimmed = linkupId.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  static Future<http.Response> _sendMultipart(
    String method,
    String path, {
    String? token,
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
  }) async {
    final request = http.MultipartRequest(method, _uri(path));
    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll(fields);
    request.files.addAll(files);
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  static Map<String, dynamic>? _extractUserMap(dynamic body) {
    if (body is! Map) return null;
    final root = Map<String, dynamic>.from(body);

    if (root['organizer_detail'] is Map) {
      final organizer = Map<String, dynamic>.from(
        root['organizer_detail'] as Map,
      );
      if (organizer['user'] is Map) {
        return Map<String, dynamic>.from(organizer['user'] as Map);
      }
    }

    dynamic data = root['data'] ?? root['user'] ?? root;
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    if (map['user'] is Map) {
      return Map<String, dynamic>.from(map['user'] as Map);
    }
    if (map['profile'] is Map) {
      return Map<String, dynamic>.from(map['profile'] as Map);
    }
    if (map.containsKey('id') ||
        map.containsKey('uid') ||
        map.containsKey('email')) {
      return map;
    }
    return null;
  }

  static UserModel? _userFromBody(dynamic body) {
    final map = _extractUserMap(body);
    if (map == null) return null;
    return ApiUserMapper.tryFromApi(map);
  }

  static List<UserModel> _usersFromDynamic(dynamic data) {
    if (data is List) return ApiUserMapper.listFromDatingApi(data);
    if (data is Map) {
      for (final key in const [
        'discover_users',
        'users',
        'data',
        'profiles',
        'matches',
        'friends',
        'likes',
        'chats',
        'people',
        'cards',
      ]) {
        final nested = data[key];
        if (nested == null) continue;
        if (nested is List || nested is Map) {
          final parsed = ApiUserMapper.listFromDatingApi(nested);
          if (parsed.isNotEmpty) return parsed;
        }
      }
      final looksLikeUser = data['name'] != null ||
          data['first_name'] != null ||
          data['firstname'] != null ||
          data['avatar'] != null;
      if (looksLikeUser) {
        final user = ApiUserMapper.tryFromApi(Map<String, dynamic>.from(data));
        return user == null ? const [] : [user];
      }
    }
    return [];
  }

  static void _logDatingShape(String path, dynamic body) {
    if (body is! Map) {
      debugPrint('[Dating] $path body=${body.runtimeType}');
      return;
    }
    final map = Map<String, dynamic>.from(body);
    debugPrint('[Dating] $path keys=${map.keys.toList()}');
    final data = map['data'];
    if (data is Map) {
      debugPrint(
        '[Dating] $path dataKeys=${data.keys.toList()} '
        'users=${data['users']?.runtimeType} '
        'discover_users=${data['discover_users']?.runtimeType} '
        'matches=${data['matches']?.runtimeType} '
        'friends=${data['friends']?.runtimeType} '
        'likes=${data['likes']?.runtimeType} '
        'chats=${data['chats']?.runtimeType}',
      );
    } else if (data is List) {
      debugPrint('[Dating] $path data=List(${data.length})');
      if (data.isNotEmpty && data.first is Map) {
        debugPrint('[Dating] $path data[0] keys=${data.first.keys.toList()}');
      }
    }
    for (final key in const ['users', 'matches', 'friends', 'likes', 'chats', 'profiles']) {
      final value = map[key];
      if (value is List) {
        debugPrint('[Dating] $path $key=List(${value.length})');
        if (value.isNotEmpty && value.first is Map) {
          debugPrint('[Dating] $path $key[0] keys=${value.first.keys.toList()}');
        }
      }
    }
  }

  static int? _idFromUserMap(dynamic raw) {
    if (raw is! Map) return null;
    return (raw['id'] as num?)?.toInt() ??
        int.tryParse(raw['id']?.toString() ?? '') ??
        int.tryParse(raw['user_id']?.toString() ?? '');
  }

  static int? _currentUserIdFromBody(dynamic body) {
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    return _idFromUserMap(map['currentUser']) ??
        _idFromUserMap(map['current_user']) ??
        (data is Map ? _idFromUserMap(data['currentUser']) : null) ??
        (data is Map ? _idFromUserMap(data['current_user']) : null);
  }

  static List<UserModel> _excludeCurrentUser(
    List<UserModel> users,
    dynamic body,
  ) {
    final currentId = _currentUserIdFromBody(body);
    if (currentId == null) return users;
    return users.where((user) => user.laravelId != currentId).toList();
  }

  static List<UserModel> _usersFromDatingBody(dynamic body) {
    if (body is List) return ApiUserMapper.listFromDatingApi(body);
    if (body is! Map) return [];
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    final candidates = <dynamic>[
      map['discover_users'],
      map['users'],
      map['profiles'],
      map['discover'],
      map['swipe'],
      map['results'],
      map['people'],
      map['cards'],
      map['suggested'],
      map['suggested_users'],
      if (data is List) data,
      if (data is Map) data['discover_users'],
      if (data is Map) data['users'],
      if (data is Map) data['data'],
      if (data is Map) data['profiles'],
      if (data is Map) data['discover'],
      if (data is Map) data['swipe'],
      if (data is Map) data['results'],
      if (data is Map) data['people'],
      if (data is Map) data['cards'],
      if (data is Map) data['suggested'],
      if (data is Map) data['suggested_users'],
      if (data is Map) data['responseUsers'] is Map
          ? data['responseUsers']['data']
          : null,
      map['responseUsers'] is Map ? map['responseUsers']['data'] : null,
      map['matches'],
      map['likes'],
      map['friends'],
      map['chats'],
      map['who_likes_me'],
      map['liked_you'],
      map['friend_list'],
      map['who-likes-me'],
      if (data is Map) data['matches'],
      if (data is Map) data['likes'],
      if (data is Map) data['friends'],
      if (data is Map) data['chats'],
      if (data is Map) data['who_likes_me'],
      if (data is Map) data['liked_you'],
      if (data is Map) data['friend_list'],
    ];
    for (final candidate in candidates) {
      if (candidate == null) continue;
      final users = ApiUserMapper.listFromDatingApi(candidate);
      if (users.isNotEmpty) return users;
    }
    return [];
  }

  static HomeFeedResult _parseDatingPage(dynamic body, int requestedPage) {
    final homeShaped = _parseHomeFeedPage(body, requestedPage);
    var users = _discoverUsersFromDating(body);
    if (users.isEmpty) {
      users = _usersFromDatingBody(body);
    }
    if (users.isEmpty) {
      users = homeShaped.users;
    }
    users = _excludeCurrentUser(users, body);
    debugPrint('[Dating] swipe discover count=${users.length}');
    for (final user in users.take(5)) {
      debugPrint(
        '[Dating] swipe user id=${user.laravelId} uid=${user.uid} '
        'name=${user.firstName} age=${user.age}',
      );
    }

    var currentPage = requestedPage;
    var lastPage = 1;
    var hasMore = false;
    const fromFullList = false;

    final coins = _coinsFromDatingBody(body) ?? homeShaped.coins;

    return HomeFeedResult(
      users: users,
      advertisements: homeShaped.advertisements,
      countries: homeShaped.countries,
      walletAmount: homeShaped.walletAmount,
      coins: coins,
      currentPage: currentPage,
      lastPage: lastPage,
      hasMore: hasMore,
      usersFromMatchFind: fromFullList,
    );
  }

  static List<UserModel> _discoverUsersFromDating(dynamic body) {
    if (body is! Map) return [];
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    final raw = map['discover_users'] ??
        (data is Map ? data['discover_users'] : null);
    if (raw == null) return [];
    return ApiUserMapper.listFromDatingApi(raw);
  }

  static int? _coinsFromDatingBody(dynamic body) {
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    final current = map['current_user'] ??
        map['currentUser'] ??
        (data is Map ? data['current_user'] : null) ??
        (data is Map ? data['currentUser'] : null);
    if (current is! Map) return null;
    final coins = current['coins'];
    if (coins is int) return coins;
    return int.tryParse(coins?.toString() ?? '');
  }

  static Future<dynamic> _datingGet(String path) async {
    final token = await getToken();
    final response = await http.get(
      _uri(path),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    debugPrint(
      '[Dating] GET $path status=${response.statusCode} type=${body.runtimeType}',
    );
    _logDatingShape(path, body);
    if (response.statusCode >= 400) _throwFromResponse(response);
    return body;
  }

  /// `GET /api/regular-user/dating` — swipe feed.
  static Future<HomeFeedResult> fetchDatingPage({int page = 1}) async {
    final body = await _datingGet('${ApiEndpoints.dating}?page=$page');
    return _parseDatingPage(body, page);
  }

  /// `GET /api/regular-user/dating/find` — find-matches cards.
  static Future<List<UserModel>> fetchDatingFind() async {
    final body = await _datingGet(ApiEndpoints.datingFind);
    final users = _excludeCurrentUser(_usersFromDatingBody(body), body);
    for (final user in users.take(5)) {
      debugPrint(
        '[Dating] find user id=${user.laravelId} name=${user.firstName} age=${user.age}',
      );
    }
    return users;
  }

  /// `GET /api/regular-user/dating/matches`
  static Future<List<UserModel>> fetchDatingMatches() async {
    final body = await _datingGet(ApiEndpoints.datingMatches);
    final users = _excludeCurrentUser(_usersFromDatingBody(body), body);
    debugPrint('[Dating] matches parsed=${users.length}');
    return users;
  }

  /// `GET /api/regular-user/dating/friends`
  static Future<FriendListResponse> fetchDatingFriends() async {
    final body = await _datingGet(ApiEndpoints.datingFriends);
    if (body is Map) {
      final parsed =
          FriendListResponse.fromJson(Map<String, dynamic>.from(body));
      if (parsed.users.isNotEmpty) {
        return FriendListResponse(
          status: parsed.status,
          users: _excludeCurrentUser(parsed.users, body),
          currentUser: parsed.currentUser,
          balance: parsed.balance,
          googleApiKey: parsed.googleApiKey,
        );
      }
    }
    return FriendListResponse(
      status: true,
      users: _excludeCurrentUser(_usersFromDatingBody(body), body),
      balance: 0,
    );
  }

  /// `GET /api/regular-user/dating/requests`
  static Future<FriendRequestResponse> fetchDatingRequests() async {
    final body = await _datingGet(ApiEndpoints.datingRequests);
    if (body is Map) {
      return FriendRequestResponse.fromJson(Map<String, dynamic>.from(body));
    }
    return FriendRequestResponse(
      status: false,
      friendRequests: [],
      sentRequests: [],
    );
  }

  /// `GET /api/regular-user/dating/likes`
  static Future<LikesResponse> fetchDatingLikes() async {
    final body = await _datingGet(ApiEndpoints.datingLikes);
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final users = _excludeCurrentUser(_usersFromDatingBody(map), map);
      final current = map['currentUser'] ??
          (map['data'] is Map ? map['data']['currentUser'] : null);
      return LikesResponse(
        status: map['status'] ?? true,
        users: users,
        currentUser: current is Map
            ? ApiUserMapper.tryFromApi(Map<String, dynamic>.from(current))
            : null,
        balance: int.tryParse(map['balance']?.toString() ?? '0') ?? 0,
      );
    }
    return LikesResponse(
      status: true,
      users: _usersFromDatingBody(body),
      balance: 0,
    );
  }

  /// `GET /api/regular-user/dating/chats`
  static Future<List<RecentChatModel>> fetchDatingChats({
    int? currentUserId,
  }) async {
    final body = await _datingGet(ApiEndpoints.datingChats);
    return _parseRecentChats(body, currentUserId: currentUserId);
  }

  /// `POST /api/regular-user/dating/swipe`
  /// Body: `{ "target_id": 123, "action": "like"|"dislike"|"love" }`
  static Future<bool> datingSwipe({
    required int targetId,
    required String action,
  }) async {
    final token = await getToken();
    debugPrint('[Dating] POST swipe target_id=$targetId action=$action');
    final response = await http.post(
      _uri(ApiEndpoints.datingSwipe),
      headers: _headers(token: token),
      body: jsonEncode({
        'target_id': targetId,
        'action': action,
      }),
    );
    final body = _decodeBody(response);
    debugPrint(
      '[Dating] swipe status=${response.statusCode} body=$body',
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) return false;
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    final matchFlag = map['is_match'] ??
        map['matched'] ??
        map['match'] ??
        (data is Map ? data['is_match'] : null) ??
        (data is Map ? data['matched'] : null);
    if (matchFlag == true || matchFlag == 1 || matchFlag == '1') return true;
    return false;
  }

  static List<UserModel> _usersFromBody(dynamic body) {
    if (body is List) return ApiUserMapper.listFromApi(body);
    if (body is Map) {
      final data = body['data'] ??
          body['users'] ??
          body['profiles'] ??
          body['results'] ??
          body['matches'] ??
          body['who-likes-me'] ??
          body['responseUsers']?['data'];
      return _usersFromDynamic(data);
    }
    return [];
  }

  /// Postman: `POST /api/login` (multipart: username, password).
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    var response = await _sendMultipart(
      'POST',
      ApiEndpoints.login,
      fields: {
        'username': username,
        'password': password,
      },
    );
    if (response.statusCode >= 500) {
      response = await http.post(
        _uri(ApiEndpoints.login),
        headers: _headers(),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
    }
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map<String, dynamic>) {
      throw LinkupApiException('Unexpected login response');
    }
    final token = body['token']?.toString();
    if (token == null || token.isEmpty) {
      throw LinkupApiException(
        body['error']?.toString() ?? 'Login token missing from server',
      );
    }
    await saveToken(token);
    return body;
  }

  /// Postman: `GET /api/user-detail` → fallback `GET /api/profile`.
  static Future<UserModel> fetchUserDetail() async {
    final token = await getToken();
    LinkupApiException? lastError;
    for (final path in [ApiEndpoints.userDetail, ApiEndpoints.profile]) {
      try {
        final response = await http.get(
          _uri(path),
          headers: _headers(token: token, json: false),
        );
        final body = _decodeBody(response);
        if (response.statusCode >= 400) {
          lastError = LinkupApiException(
            'Profile request failed (${response.statusCode}) for $path',
            statusCode: response.statusCode,
          );
          continue;
        }
        final user = _userFromBody(body);
        if (user != null) return user;
      } catch (e) {
        debugPrint('fetchUserDetail $path error: $e');
      }
    }
    throw lastError ??
        LinkupApiException('User profile missing from server response');
  }

  /// Production mobile home feed: `GET /api/regular-user/home?page=N`.
  static Future<HomeFeedResult> fetchRegularUserHomePage({int page = 1}) async {
    final token = await getToken();
    final response = await http.get(
      _uri('${ApiEndpoints.regularUserHome}?page=$page'),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    return _parseHomeFeedPage(body, page);
  }

  static HomeFeedResult _parseHomeFeedPage(dynamic body, int requestedPage) {
    if (body is! Map) return HomeFeedResult.empty;

    final root = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : Map<String, dynamic>.from(body);

    final responseUsers = root['responseUsers'];
    final users = <UserModel>[];
    var currentPage = requestedPage;
    var lastPage = requestedPage;
    var hasMore = false;

    if (responseUsers is Map) {
      currentPage = responseUsers['current_page'] is int
          ? responseUsers['current_page'] as int
          : int.tryParse(responseUsers['current_page']?.toString() ?? '') ??
              requestedPage;
      lastPage = responseUsers['last_page'] is int
          ? responseUsers['last_page'] as int
          : int.tryParse(responseUsers['last_page']?.toString() ?? '') ??
              currentPage;
      final nextUrl = responseUsers['next_page_url'];
      hasMore = nextUrl != null && nextUrl.toString().isNotEmpty;
      final total = responseUsers['total'];
      final perPage = responseUsers['per_page'];
      if (total is num && perPage is num && perPage > 0) {
        final computedLast = (total / perPage).ceil();
        if (computedLast > 0) {
          lastPage = computedLast;
          hasMore = hasMore || currentPage < lastPage;
        }
      }
      final pageData = responseUsers['data'];
      if (pageData is List) {
        users.addAll(ApiUserMapper.listFromApi(pageData));
      }
    } else {
      users.addAll(_usersFromBody(body));
    }

    final adsRaw = root['advertisementList'];
    final ads = <HomeAdvertisement>[];
    if (adsRaw is List) {
      for (final item in adsRaw) {
        if (item is Map) {
          ads.add(HomeAdvertisement.fromJson(
            Map<String, dynamic>.from(item),
          ));
        }
      }
    }

    final countriesRaw = root['caribbeanCountry'];
    final countries = <Map<String, dynamic>>[];
    if (countriesRaw is List) {
      for (final item in countriesRaw) {
        if (item is Map) {
          countries.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final wallet = root['logiUserWalletAmount']?.toString() ?? '0';
    final coins = root['logiUserCoins'] is int
        ? root['logiUserCoins'] as int
        : int.tryParse(root['logiUserCoins']?.toString() ?? '') ?? 0;

    return HomeFeedResult(
      users: users,
      advertisements: ads,
      countries: countries,
      walletAmount: wallet,
      coins: coins,
      currentPage: currentPage,
      lastPage: lastPage,
      hasMore: hasMore || currentPage < lastPage,
    );
  }

  /// Legacy — first page users only.
  static Future<List<UserModel>> fetchRegularUserHome() async {
    final page = await fetchRegularUserHomePage(page: 1);
    return page.users;
  }

  /// Legacy fallback: `GET /api/match/find`.
  static Future<List<UserModel>> fetchFindMatches() async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.matchFind),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    return _usersFromBody(body);
  }

  /// `GET /api/regular-user/all-matches` — prefers dating/matches.
  static Future<List<UserModel>> fetchAllMatches() async {
    try {
      final users = await fetchDatingMatches();
      debugPrint('[Dating] matches count=${users.length}');
      return users;
    } catch (e) {
      debugPrint('[Dating] matches fallback all-matches: $e');
    }
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.allMatches),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    
    if (body is Map) {
      return _usersFromDatingBody(body);
    }
    return [];
  }

  /// `GET /api/regular-user/matches` - Mutual matches (I like them, they like me).
  static Future<List<UserModel>> fetchMutualMatches() async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.mutualMatches),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    return _usersFromBody(body);
  }

  /// `GET /api/regular-user/dating` for swipe; keeps ads/wallet from home.
  static Future<HomeFeedResult> fetchExploreHomePage({int page = 1}) async {
    try {
      final dating = await fetchDatingPage(page: page);
      // ignore: avoid_print
      print(
        'SWIPE_CONSOLE|API|regular-user/dating|page=$page|users=${dating.users.length}|ads=${dating.advertisements.length}|hasMore=${dating.hasMore}',
      );

      if (page == 1 &&
          (dating.advertisements.isEmpty || dating.walletAmount == '0')) {
        try {
          final home = await fetchRegularUserHomePage(page: 1);
          return HomeFeedResult(
            users: dating.users,
            advertisements: dating.advertisements.isNotEmpty
                ? dating.advertisements
                : home.advertisements,
            countries: dating.countries.isNotEmpty
                ? dating.countries
                : home.countries,
            walletAmount: dating.walletAmount != '0'
                ? dating.walletAmount
                : home.walletAmount,
            coins: dating.coins != 0 ? dating.coins : home.coins,
            currentPage: dating.currentPage,
            lastPage: dating.lastPage,
            hasMore: dating.hasMore,
            usersFromMatchFind: dating.usersFromMatchFind,
          );
        } catch (e) {
          debugPrint('[Dating] home extras error: $e');
        }
      }
      return dating;
    } catch (e) {
      // ignore: avoid_print
      print('SWIPE_CONSOLE|API|regular-user/dating|error|$e');
      if (page > 1) rethrow;
    }

    try {
      final home = await fetchRegularUserHomePage(page: page);
      print(
        'SWIPE_CONSOLE|API|regular-user/home|fallback|page=$page|users=${home.users.length}',
      );
      if (home.users.isNotEmpty || page > 1) return home;
    } catch (e) {
      print('SWIPE_CONSOLE|API|regular-user/home|error|$e');
      if (page > 1) rethrow;
    }

    final matches = await fetchFindMatches();
    print('SWIPE_CONSOLE|API|match/find|error-fallback|count=${matches.length}');
    return HomeFeedResult(
      users: matches,
      advertisements: const [],
      walletAmount: '0',
      coins: 0,
      currentPage: 1,
      lastPage: 1,
      hasMore: false,
    );
  }

  /// `GET /api/regular-user/events`
  static Future<EventsResponse> fetchEvents() async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.events),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) return EventsResponse.empty;
    final map = Map<String, dynamic>.from(body);
    if (kDebugMode) {
      final data = map['data'];
      if (data is Map) {
        for (final entry in data.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            debugPrint(
              '[Events] sample section=${entry.key} keys=${first is Map ? first.keys.toList() : first.runtimeType}',
            );
            if (first is Map) {
              for (final key in const [
                'image_url',
                'image',
                'cover_image',
                'thumbnail',
                'banner',
                'image_gallery',
                'images',
                'is_favourite',
                'is_favorite',
              ]) {
                if (first.containsKey(key)) {
                  debugPrint(
                    '[Events] sample $key (${first[key].runtimeType})=${first[key]}',
                  );
                }
              }
            }
            break;
          }
        }
      }
    }
    return EventsResponse.fromJson(map);
  }

  /// `GET /api/regular-user/events/favorites`
  static Future<List<LinkupEvent>> fetchEventFavorites() async {
    final token = await getToken();
    debugPrint('[Events] GET ${ApiEndpoints.eventFavorites}');
    final response = await http.get(
      _uri(ApiEndpoints.eventFavorites),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    debugPrint('[Events] favorites status=${response.statusCode}');
    if (response.statusCode >= 400) _throwFromResponse(response);
    final events = _parseEventList(body);
    debugPrint('[Events] favorites parsed=${events.length}');
    return events
        .map((event) => event.copyWith(isFavourite: true))
        .toList();
  }

  /// `GET /api/regular-user/events/bookings`
  /// Optional `status=cancelled` for the Canceled tab.
  static Future<List<EventBooking>> fetchEventBookings({String? status}) async {
    final token = await getToken();
    final normalized = (status ?? '').trim();
    final uri = normalized.isEmpty
        ? _uri(ApiEndpoints.eventBookings)
        : _uri(ApiEndpoints.eventBookings).replace(
            queryParameters: {'status': normalized},
          );
    debugPrint('[Events] GET $uri');
    final response = await http.get(
      uri,
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    debugPrint('[Events] bookings status=${response.statusCode}');
    if (response.statusCode >= 400) _throwFromResponse(response);
    final items = _parseEventBookings(body);
    debugPrint('[Events] bookings parsed=${items.length}');
    return items;
  }

  static List<EventBooking> _parseEventBookings(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((item) => EventBooking.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    if (body is! Map) return const [];
    final map = Map<String, dynamic>.from(body);
    final data = map['data'] ?? map['bookings'] ?? map['tickets'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => EventBooking.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    if (data is Map) {
      final nested = data['data'] ?? data['bookings'] ?? data['tickets'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((item) =>
                EventBooking.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }
    return const [];
  }

  static List<LinkupEvent> _parseEventList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((item) => LinkupEvent.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    if (body is! Map) return const [];
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => LinkupEvent.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    if (data is Map) {
      final nested = data['events'] ??
          data['favorites'] ??
          data['favourites'] ??
          data['data'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((item) => LinkupEvent.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      final collected = <LinkupEvent>[];
      final seen = <int>{};
      for (final value in data.values) {
        if (value is! List) continue;
        for (final item in value.whereType<Map>()) {
          final event = LinkupEvent.fromJson(Map<String, dynamic>.from(item));
          if (seen.add(event.id)) collected.add(event);
        }
      }
      return collected;
    }
    return const [];
  }

  /// `GET /api/regular-user/events/{slug}`
  static Future<EventDetailModel> fetchEventDetail(String slug) async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.eventDetail(slug)),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) throw LinkupApiException('Invalid event detail response');
    return EventDetailModel.fromJson(Map<String, dynamic>.from(body));
  }

  /// `POST /api/regular-user/events/{eventId}/toggle-favorite`
  static Future<bool> toggleEventFavorite(int eventId, {required bool currentlyFavourite}) async {
    final token = await getToken();
    debugPrint('[Events] toggle-favorite id=$eventId currently=$currentlyFavourite');
    final response = await http.post(
      _uri(ApiEndpoints.eventToggleFavorite(eventId)),
      headers: _headers(token: token),
      body: jsonEncode({'event_id': eventId}),
    );
    final body = _decodeBody(response);
    debugPrint('[Events] toggle-favorite status=${response.statusCode} body=$body');
    if (response.statusCode >= 400) _throwFromResponse(response);
    return _parseFavouriteFlag(body, fallback: !currentlyFavourite);
  }

  /// `POST /api/regular-user/events/organizer/toggle-follow`
  static Future<OrganizerFollowResult> toggleOrganizerFollow(
    int organizerId, {
    required bool currentlyFollowing,
  }) async {
    final token = await getToken();
    debugPrint(
      '[Events] organizer toggle-follow id=$organizerId currently=$currentlyFollowing',
    );
    final response = await http.post(
      _uri(ApiEndpoints.eventOrganizerToggleFollow),
      headers: _headers(token: token),
      body: jsonEncode({'organizer_id': organizerId}),
    );
    final body = _decodeBody(response);
    debugPrint(
      '[Events] organizer toggle-follow status=${response.statusCode} body=$body',
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
    return _parseOrganizerFollow(body, fallbackFollowing: !currentlyFollowing);
  }

  static OrganizerFollowResult _parseOrganizerFollow(
    dynamic body, {
    required bool fallbackFollowing,
  }) {
    if (body is! Map) {
      return OrganizerFollowResult(isFollowing: fallbackFollowing);
    }
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    final nestedStats = data is Map ? data['organizer_stats'] : null;
    // Only explicit follow flags — a generic `data: true` success must not
    // be treated as still following (that broke unfollow on the toggle API).
    final followingCandidates = <dynamic>[
      map['is_following'],
      if (data is Map) data['is_following'],
      if (nestedStats is Map) nestedStats['is_following'],
    ];
    bool? parsedFollowing;
    for (final value in followingCandidates) {
      if (value == null) continue;
      parsedFollowing =
          ApiUserMapper.parseBool(value, fallback: fallbackFollowing);
      break;
    }
    if (parsedFollowing == null) {
      final message = (map['message'] ?? (data is Map ? data['message'] : null))
          ?.toString()
          .toLowerCase();
      if (message != null && message.contains('unfollow')) {
        parsedFollowing = false;
      } else if (message != null && message.contains('follow')) {
        parsedFollowing = true;
      }
    }
    final countCandidates = <dynamic>[
      map['followers_count'],
      if (data is Map) data['followers_count'],
      if (nestedStats is Map) nestedStats['followers_count'],
    ];
    int? followersCount;
    for (final value in countCandidates) {
      if (value == null) continue;
      if (value is int) {
        followersCount = value;
        break;
      }
      followersCount = int.tryParse(value.toString());
      if (followersCount != null) break;
    }
    return OrganizerFollowResult(
      isFollowing: parsedFollowing ?? fallbackFollowing,
      followersCount: followersCount,
    );
  }

  static bool _parseFavouriteFlag(dynamic body, {required bool fallback}) {
    if (body is! Map) return fallback;
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    final nestedEvent = data is Map ? data['event'] : null;
    final candidates = <dynamic>[
      map['is_favourite'],
      map['is_favorite'],
      map['favourite'],
      map['favorite'],
      if (data is Map) data['is_favourite'],
      if (data is Map) data['is_favorite'],
      if (data is Map) data['favourite'],
      if (data is Map) data['favorite'],
      if (nestedEvent is Map) nestedEvent['is_favourite'],
      if (nestedEvent is Map) nestedEvent['is_favorite'],
      if (data is bool) data,
    ];
    for (final value in candidates) {
      if (value == null) continue;
      return ApiUserMapper.parseBool(value, fallback: fallback);
    }
    return fallback;
  }

  /// `GET /api/regular-user/events/{id}/reviews`
  static Future<List<Review>> fetchEventReviews(int eventId) async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.eventReviews(eventId)),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) throw LinkupApiException('Invalid reviews response');
    final data = body['data'] as List? ?? [];
    return data
        .map((item) => Review.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// `POST /api/regular-user/events/{id}/reviews`
  static Future<bool> postEventReview(int eventId,
      {required int rating, required String text, required String reviewerName}) async {
    final token = await getToken();
    final response = await http.post(
      _uri(ApiEndpoints.eventReviews(eventId)),
      headers: _headers(token: token),
      body: jsonEncode({
        'rating': rating,
        'review_text': text,
        'reviewer_name': reviewerName,
      }),
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
    return true;
  }

  /// `PUT /api/regular-user/events/{eventId}/reviews/{reviewId}`
  static Future<bool> updateEventReview(int eventId, int reviewId,
      {required int rating, required String text, required String reviewerName}) async {
    final token = await getToken();
    final response = await http.put(
      _uri(ApiEndpoints.eventReviewDetail(eventId, reviewId)),
      headers: _headers(token: token),
      body: jsonEncode({
        'rating': rating,
        'review_text': text,
        'reviewer_name': reviewerName,
      }),
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
    return true;
  }

  /// `DELETE /api/regular-user/events/{eventId}/reviews/{reviewId}`
  static Future<bool> deleteEventReview(int eventId, int reviewId) async {
    final token = await getToken();
    final response = await http.delete(
      _uri(ApiEndpoints.eventReviewDetail(eventId, reviewId)),
      headers: _headers(token: token),
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
    return true;
  }

  /// `POST /api/regular-user/events/{eventId}/tickets/buy-stripe`
  static Future<String?> buyTicketsStripe(dynamic eventId,
      {required List<Map<String, dynamic>> tickets}) async {
    final token = await getToken();
    final response = await http.post(
      _uri(ApiEndpoints.buyTicketsStripe(eventId)),
      headers: _headers(token: token),
      body: jsonEncode({
        'tickets': tickets,
      }),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is Map && body['status'] == true) {
      return body['data']['checkout_url']?.toString();
    }
    return null;
  }

  /// `GET /api/regular-user/allnotifications?type=`
  static Future<NotificationsResult> fetchAllNotifications({
    String type = 'all',
  }) async {
    final token = await getToken();
    final normalized = type.trim().isEmpty ? 'all' : type.trim();
    final uri = _uri(ApiEndpoints.allNotifications).replace(
      queryParameters: {'type': normalized},
    );
    debugPrint('[Notifications] GET $uri');
    final response = await http.get(
      uri,
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) {
      throw LinkupApiException('Invalid notifications response');
    }
    return NotificationsResult.fromJson(Map<String, dynamic>.from(body));
  }

  /// `POST /api/regular-user/allnotifications/mark-all-read`
  static Future<void> markAllNotificationsRead() async {
    final token = await getToken();
    final uri = _uri(ApiEndpoints.markAllNotificationsRead);
    debugPrint('[Notifications] POST $uri');
    final response = await http.post(
      uri,
      headers: _headers(token: token, json: false),
    );
    debugPrint(
      '[Notifications] mark-all-read status=${response.statusCode}',
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `GET /api/regular-user/nightlife`
  static Future<NightlifeResult> fetchNightlife() async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.nightlife),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) {
      throw LinkupApiException('Invalid nightlife response');
    }
    return NightlifeResult.fromJson(Map<String, dynamic>.from(body));
  }

  /// `GET /api/regular-user/nightlife/:kind/:placeId`
  static Future<NightlifePlaceDetail> fetchNightlifeDetail({
    required String kind,
    required String placeId,
  }) async {
    final token = await getToken();
    final normalizedKind = kind.trim().toLowerCase();
    final normalizedId = placeId.trim();
    final kindsToTry = <String>[
      if (normalizedKind.isNotEmpty) normalizedKind,
      if (normalizedKind == 'clubs') 'club',
      if (normalizedKind == 'restaurants') 'restaurant',
      if (normalizedKind == 'club') 'clubs',
      if (normalizedKind == 'restaurant') 'restaurants',
    ];

    http.Response? lastResponse;
    Object? lastParseError;

    Future<NightlifePlaceDetail?> tryGet(Uri uri) async {
      debugPrint('[Nightlife] GET $uri');
      final response = await http.get(
        uri,
        headers: _headers(token: token, json: false),
      );
      lastResponse = response;
      debugPrint(
        '[Nightlife] detail status=${response.statusCode} body=${response.body.length > 400 ? response.body.substring(0, 400) : response.body}',
      );
      if (response.statusCode >= 400) return null;
      final body = _decodeBody(response);
      if (body is! Map) {
        lastParseError = LinkupApiException('Invalid nightlife detail response');
        return null;
      }
      try {
        return NightlifePlaceDetail.fromJson(Map<String, dynamic>.from(body));
      } catch (e) {
        lastParseError = e;
        debugPrint('[Nightlife] parse error=$e');
        return null;
      }
    }

    for (final tryKind in kindsToTry) {
      final parsed = await tryGet(_uri(ApiEndpoints.nightlifeDetail(tryKind, normalizedId)));
      if (parsed != null) return parsed;
    }

    for (final tryKind in kindsToTry) {
      for (final param in const ['place_id', 'placeId']) {
        final uri = _uri('/api/regular-user/nightlife/$tryKind').replace(
          queryParameters: {param: normalizedId},
        );
        final parsed = await tryGet(uri);
        if (parsed != null) return parsed;
      }
    }

    if (lastParseError != null) {
      throw LinkupApiException(lastParseError.toString());
    }
    final failedResponse = lastResponse;
    if (failedResponse != null) _throwFromResponse(failedResponse);
    throw LinkupApiException('Invalid nightlife detail response');
  }

  /// `GET /api/regular-user/news`
  static Future<NewsResponse> fetchNews() async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.news),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) throw LinkupApiException('Invalid news response');
    return NewsResponse.fromJson(Map<String, dynamic>.from(body));
  }

  /// `GET /api/regular-user/news/{id}`
  static Future<NewsItem> fetchNewsDetail(int newsId) async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.newsDetail(newsId)),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    final item = _parseNewsDetailItem(body);
    if (item == null) {
      throw LinkupApiException('Invalid news detail response');
    }
    return item;
  }

  static NewsItem? _parseNewsDetailItem(dynamic body) {
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];

    Map<String, dynamic>? item;
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      if (dataMap.containsKey('id') &&
          (dataMap.containsKey('title') || dataMap.containsKey('body'))) {
        item = dataMap;
      } else if (dataMap['news'] is Map) {
        item = Map<String, dynamic>.from(dataMap['news'] as Map);
      } else if (dataMap['news'] is List && (dataMap['news'] as List).isNotEmpty) {
        final first = (dataMap['news'] as List).first;
        if (first is Map) item = Map<String, dynamic>.from(first);
      }
    }
    if (item == null && map['news'] is Map) {
      item = Map<String, dynamic>.from(map['news'] as Map);
    }
    if (item == null && map.containsKey('id') && map.containsKey('title')) {
      item = map;
    }
    if (item == null) return null;
    return NewsItem.fromJson(item);
  }

  /// `GET /api/regular-user/dating/likes` (fallback: `/likes`).
  static Future<LikesResponse> fetchLikes() async {
    try {
      return await fetchDatingLikes();
    } catch (e) {
      debugPrint('[Dating] likes fallback: $e');
    }
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.likes),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) throw LinkupApiException('Invalid likes response');
    
    final map = Map<String, dynamic>.from(body);
    final users = _usersFromDatingBody(map);
    
    return LikesResponse(
      status: map['status'] ?? false,
      users: users,
      currentUser: map['currentUser'] != null ? ApiUserMapper.fromApi(Map<String, dynamic>.from(map['currentUser'])) : null,
      balance: int.tryParse(map['balance']?.toString() ?? '0') ?? 0,
    );
  }

  /// `GET /api/regular-user/all-matches`
  // static Future<List<UserModel>> fetchAllMatches() async {
  //   final token = await getToken();
  //   final response = await http.get(
  //     _uri(ApiEndpoints.allMatches),
  //     headers: _headers(token: token, json: false),
  //   );
  //   final body = _decodeBody(response);
  //   if (response.statusCode >= 400) _throwFromResponse(response);
    
  //   if (body is Map) {
  //     return _usersFromDynamic(body['users']);
  //   }
  //   return [];
  // }

  /// `GET /api/regular-user/dating/friends` (fallback: `/friend`).
  static Future<FriendListResponse> fetchFriends() async {
    try {
      return await fetchDatingFriends();
    } catch (e) {
      debugPrint('[Dating] friends fallback: $e');
    }
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.friend),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    
    if (body is Map) {
      return FriendListResponse.fromJson(Map<String, dynamic>.from(body));
    }
    return FriendListResponse(status: false, users: [], balance: 0);
  }

  /// `POST /api/regular-user/friend/{id}/unfriend`
  static Future<void> unfriend(int userId) async {
    final token = await getToken();
    final response = await http.post(
      _uri(ApiEndpoints.unfriend(userId)),
      headers: _headers(token: token, json: false),
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/regular-user/news/{id}/trending`
  static Future<Map<String, dynamic>> hitNewsTrending(int newsId) async {
    final token = await getToken();
    final response = await http.post(
      _uri(ApiEndpoints.newsTrending(newsId)),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map<String, dynamic>) {
      throw LinkupApiException('Unexpected trending response');
    }
    return body;
  }

  /// `GET /api/regular-user/events/{slug}/tickets`
  static Future<List<Ticket>> fetchEventTickets(String slug) async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.eventTickets(slug)),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    
    // ignore: avoid_print
    print('DEBUG: fetchEventTickets response body type: ${body.runtimeType}');
    
    if (body is Map) {
      final data = body['data'];
      if (data is Map && data['tickets'] is List) {
        return (data['tickets'] as List)
            .map((item) => Ticket.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }
    return [];
  }

  /// `GET /api/regular-user/live-streams/network`
  static Future<LiveStreamResponse> fetchLiveStreams({String? category}) async {
    final token = await getToken();
    final query = category != null && category != 'All' ? '?category=${Uri.encodeComponent(category)}' : '';
    final response = await http.get(
      _uri('${ApiEndpoints.liveNetwork}$query'),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) throw LinkupApiException('Invalid live streams response');
    return LiveStreamResponse.fromJson(Map<String, dynamic>.from(body));
  }

  /// `GET /api/regular-user/live-streams/categories`
  static Future<List<String>> fetchLiveCategories() async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.liveCategories),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) throw LinkupApiException('Invalid categories response');
    return LiveCategoriesResponse.fromJson(Map<String, dynamic>.from(body)).categories;
  }

  /// `POST /api/update-user` (multipart) — sync lat/long for home filters.
  static Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final token = await getToken();
    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.updateUser,
      token: token,
      fields: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/home/make-match` (multipart) — legacy fallback.
  static Future<void> makeMatch({
    required int targetUserId,
    required String status,
  }) async {
    final token = await getToken();
    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.makeMatch,
      token: token,
      fields: {
        'id': targetUserId.toString(),
        'status': status,
      },
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/regular-user/profile/like/{id}`
  static Future<void> profileLike(int userId) async {
    final token = await getToken();
    final response = await http.post(
      _uri(ApiEndpoints.profileLike(userId)),
      headers: _headers(token: token, json: false),
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/regular-user/profile/dislike/{id}`
  static Future<void> profileDislike(int userId) async {
    final token = await getToken();
    final response = await http.post(
      _uri(ApiEndpoints.profileDislike(userId)),
      headers: _headers(token: token, json: false),
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  static bool isFirebaseUid(String? uid) {
    if (uid == null || uid.isEmpty) return false;
    return !RegExp(r'^\d+$').hasMatch(uid);
  }

  static RegularUserDetailResult _parseProfileDetailBody(
    Map<String, dynamic> body,
  ) {
    final userdata = body['userdata'] ?? body['data'] ?? body['user'];
    if (userdata is! Map) {
      throw LinkupApiException('Profile detail missing user payload');
    }
    final map = Map<String, dynamic>.from(userdata);
    final user = ApiUserMapper.fromApi(map);
    final distance = (map['distance'] as num?)?.toInt() ??
        int.tryParse(map['distance']?.toString() ?? '');
    return RegularUserDetailResult(
      user: user,
      isFriends: body['isFriends'] == true,
      isFriendRequestSent: body['isFriendRequestSent'] == true,
      isHiddenByProfileOwner: body['isHiddenByProfileOwner'] == true,
      distance: distance,
      linkupId: map['linkup_id']?.toString(),
      popularityLevel: map['popularity_level']?.toString(),
    );
  }

  /// `GET /api/regular-user/user/detail/{name}/{uid}`
  static Future<RegularUserDetailResult> fetchRegularUserProfileDetail({
    required String name,
    required String uid,
  }) async {
    final token = await getToken();
    final path =
        '${ApiEndpoints.regularUserDetail}/${Uri.encodeComponent(name)}/${Uri.encodeComponent(uid)}';
    final response = await http.get(
      _uri(path),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) {
      throw LinkupApiException('Invalid profile detail response');
    }
    return _parseProfileDetailBody(Map<String, dynamic>.from(body));
  }

  /// Full profile by Laravel id — used when swipe cards only have numeric ids.
  static Future<RegularUserDetailResult> fetchUserProfileByLaravelId(
    int userId,
  ) async {
    final token = await getToken();
    LinkupApiException? lastError;
    for (final path in [
      ApiEndpoints.linkupUser(userId),
      ApiEndpoints.specificUser(userId),
    ]) {
      try {
        final response = await http.get(
          _uri(path),
          headers: _headers(token: token, json: false),
        );
        final body = _decodeBody(response);
        if (response.statusCode >= 400) {
          lastError = LinkupApiException(
            'Profile request failed (${response.statusCode}) for $path',
            statusCode: response.statusCode,
          );
          continue;
        }
        if (body is Map) {
          return _parseProfileDetailBody(Map<String, dynamic>.from(body));
        }
      } catch (e) {
        if (e is LinkupApiException) {
          lastError = e;
        } else {
          debugPrint('fetchUserProfileByLaravelId $path error: $e');
        }
      }
    }
    throw lastError ??
        LinkupApiException('Could not load profile for user $userId');
  }

  /// `POST /api/regular-user/send-gift`
  /// Body: `receiver_id`, `gift_name`, `coins`.
  static Future<int?> sendGift({
    required int receiverId,
    required String giftName,
    required int coins,
  }) async {
    final token = await getToken();
    debugPrint(
      '[Gift] POST send-gift receiver_id=$receiverId gift_name=$giftName coins=$coins',
    );
    var response = await http.post(
      _uri(ApiEndpoints.sendGift),
      headers: _headers(token: token),
      body: jsonEncode({
        'receiver_id': receiverId,
        'gift_name': giftName,
        'coins': coins,
      }),
    );
    if (response.statusCode >= 400) {
      response = await _sendMultipart(
        'POST',
        ApiEndpoints.sendGift,
        token: token,
        fields: {
          'receiver_id': receiverId.toString(),
          'gift_name': giftName,
          'coins': coins.toString(),
        },
      );
    }
    final body = _decodeBody(response);
    debugPrint('[Gift] send-gift status=${response.statusCode} body=$body');
    if (response.statusCode >= 400) _throwFromResponse(response);
    return _coinsFromGiftResponse(body);
  }

  static int? _coinsFromGiftResponse(dynamic body) {
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    final current = map['current_user'] ??
        map['currentUser'] ??
        (data is Map ? data['current_user'] : null) ??
        (data is Map ? data['currentUser'] : null);
    final candidates = <dynamic>[
      map['coins'],
      map['balance'],
      map['remaining_coins'],
      if (current is Map) current['coins'],
      if (data is Map) data['coins'],
      if (data is Map) data['balance'],
    ];
    for (final value in candidates) {
      if (value is int) return value;
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// `GET /api/regular-user/dating/requests` (fallback: `/friend-request`).
  static Future<FriendRequestResponse> fetchFriendRequests() async {
    try {
      return await fetchDatingRequests();
    } catch (e) {
      debugPrint('[Dating] requests fallback: $e');
    }
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.friendRequestIndex),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) {
      return FriendRequestResponse(
        status: false,
        friendRequests: [],
        sentRequests: [],
      );
    }
    return FriendRequestResponse.fromJson(Map<String, dynamic>.from(body));
  }

  /// `POST /api/regular-user/accept-friend-request/{id}`
  static Future<void> acceptFriendRequest(int requestId) async {
    final token = await getToken();
    final response = await http.post(
      _uri(ApiEndpoints.acceptFriendRequest(requestId)),
      headers: _headers(token: token, json: false),
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/regular-user/reject-friend-request/{id}/reject`
  static Future<void> rejectFriendRequest(int requestId) async {
    final token = await getToken();
    final response = await http.post(
      _uri(ApiEndpoints.rejectFriendRequest(requestId)),
      headers: _headers(token: token, json: false),
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/regular-user/friend-request/{name}/{uid}`
  static Future<void> sendFriendRequest({
    required String name,
    required String uid,
  }) async {
    final token = await getToken();
    final response = await http.post(
      _uri(ApiEndpoints.friendRequest(name, uid)),
      headers: _headers(token: token, json: false),
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/regular-user/profile/block-user`
  static Future<void> blockUser({
    required int blockedUserId,
    String reason = '',
    String note = '',
  }) async {
    final token = await getToken();
    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.blockUser,
      token: token,
      fields: {
        'blocked_user_id': blockedUserId.toString(),
        if (reason.isNotEmpty) 'reason': reason,
        if (note.isNotEmpty) 'note': note,
      },
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/regular-user/profile/unblock-user`
  static Future<void> unblockUser({required int blockedUserId}) async {
    final token = await getToken();
    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.unblockUser,
      token: token,
      fields: {'blocked_user_id': blockedUserId.toString()},
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/regular-user/falg-user` (report abuse).
  static Future<void> reportUser({
    required int reportedUserId,
    required String message,
    required String reason,
    List<String> selectedReason = const [],
  }) async {
    final token = await getToken();
    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.reportUser,
      token: token,
      fields: {
        'reported_user_id': reportedUserId.toString(),
        'message': message,
        'reason': reason,
        'selected_reason': selectedReason.isEmpty
            ? '["$reason"]'
            : selectedReason.toString(),
      },
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `GET /api/logout`
  static Future<void> logout() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      await clearToken();
      return;
    }
    try {
      await http.get(
        _uri(ApiEndpoints.logout),
        headers: _headers(token: token, json: false),
      );
    } catch (_) {}
    await clearToken();
  }

  /// Postman: `POST /api/regular-user/register`
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String linkupId,
    required String password,
  }) async {
    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.register,
      fields: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'linkup_id': _formatLinkupId(linkupId),
      'password': password,
      'password_confirmation': password,
      },
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map<String, dynamic>) {
      throw LinkupApiException('Unexpected register response');
    }
    final token = body['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await saveToken(token);
    }
    return body;
  }

  /// Legacy alias — prefer [registerUser].
  static Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return registerUser(
      firstName: '',
      lastName: '',
      email: email,
      linkupId: '',
      password: password,
    );
  }

  /// Postman: `POST /api/regular-user/send-otp`
  static Future<String> requestPhoneOtp(String phoneNumber) async {
    final token = await getToken();
    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.sendOtp,
      token: token,
      fields: {'phone_number': phoneNumber},
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is Map && body['token'] != null) {
      return body['token'].toString();
    }
    throw LinkupApiException('OTP token missing from server response');
  }

  /// Postman: `POST /api/regular-user/verify-otp/{token}`
  static Future<void> verifyOtp({
    required String otpToken,
    required String otp,
  }) async {
    final token = await getToken();
    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.verifyOtp(otpToken),
      token: token,
      fields: {'otp': otp},
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// Postman: `POST /api/regular-user/resend-otp/{token}`
  static Future<void> resendOtp(String otpToken) async {
    final token = await getToken();
    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.resendOtp(otpToken),
      token: token,
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// Postman: `POST /api/regular-user/wizard-update`
  static Future<Map<String, dynamic>> submitWizard({
    required Map<String, String> fields,
    List<String> interestLabels = const [],
    List<int> ageFilter = const [18, 50],
    List<int> distanceFilter = const [0, 40],
    required List<File> photoFiles,
  }) async {
    final token = await getToken();
    final wizardFields = Map<String, String>.from(fields);
    final interestSlugs = InterestApiMapper.labelsToSlugs(interestLabels);
    for (var i = 0; i < interestSlugs.length; i++) {
      wizardFields['interests[$i]'] = interestSlugs[i];
    }
    wizardFields['age_filter[min]'] = ageFilter[0].toString();
    wizardFields['age_filter[max]'] = ageFilter[1].toString();
    wizardFields['distance_filter[min]'] = distanceFilter[0].toString();
    wizardFields['distance_filter[max]'] = distanceFilter[1].toString();

    final files = <http.MultipartFile>[];
    for (final file in photoFiles) {
      files.add(await http.MultipartFile.fromPath('more_photos[]', file.path));
    }

    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.wizardUpdate,
      token: token,
      fields: wizardFields,
      files: files,
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is Map<String, dynamic>) return body;
    return {'status': true};
  }

  /// `GET /proxy/countries`
  static Future<List<Map<String, String>>> fetchCountries() async {
    final response = await http.get(
      _uri('/proxy/countries'),
      headers: _headers(json: false),
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
    final body = _decodeBody(response);
    final data = body is Map ? (body['data'] ?? body) : body;
    if (data is! List) return [];
    return data
        .map((item) {
          final map = item as Map;
          final name = (map['country'] ?? map['name'] ?? '').toString();
          final iso2 = (map['iso2'] ?? map['value'] ?? '').toString();
          if (name.isEmpty) return null;
          return {'label': name, 'value': iso2.isNotEmpty ? iso2 : name};
        })
        .whereType<Map<String, String>>()
        .toList();
  }

  /// `POST /proxy/states`
  static Future<List<String>> fetchStates(String countryName) async {
    final response = await http.post(
      _uri('/proxy/states'),
      headers: _headers(),
      body: jsonEncode({'country': countryName}),
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
    final body = _decodeBody(response);
    final data = body is Map ? (body['data']?['states'] ?? body['data']) : null;
    if (data is! List) return [];
    return data
        .map((s) {
          if (s is Map) return (s['name'] ?? s['state'] ?? '').toString();
          return s.toString();
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// `POST /proxy/cities`
  static Future<List<String>> fetchCities({
    required String countryName,
    required String stateName,
  }) async {
    final response = await http.post(
      _uri('/proxy/cities'),
      headers: _headers(),
      body: jsonEncode({'country': countryName, 'state': stateName}),
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
    final body = _decodeBody(response);
    final data = body is Map ? (body['data'] ?? body) : null;
    if (data is! List) return [];
    return data.map((c) => c.toString()).where((c) => c.isNotEmpty).toList();
  }

  /// `GET /api/regular-user/user/chat`
  static Future<List<ChatUser>> fetchAllChats() async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.chat),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    
    if (body is Map) {
      return ChatListResponse.fromJson(Map<String, dynamic>.from(body)).users;
    }
    return [];
  }

  /// `GET /api/regular-user/dating/chats` (fallback: `/user/chat`).
  static Future<List<RecentChatModel>> fetchChatList({int? currentUserId}) async {
    try {
      final chats = await fetchDatingChats(currentUserId: currentUserId);
      print('[Chat] dating/chats count=${chats.length}');
      return chats;
    } catch (e) {
      print('[Chat] dating/chats fallback: $e');
    }
    final token = await getToken();
    print('[Chat] GET ${ApiEndpoints.chat} token=${token != null && token.isNotEmpty}');
    final response = await http.get(
      _uri(ApiEndpoints.chat),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    print('[Chat] status=${response.statusCode} type=${body.runtimeType}');
    if (response.statusCode >= 400) _throwFromResponse(response);
    return _parseRecentChats(body, currentUserId: currentUserId);
  }

  static List<RecentChatModel> _parseRecentChats(
    dynamic body, {
    int? currentUserId,
  }) {
    dynamic rawUsers;
    if (body is List) {
      rawUsers = body;
    } else if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'];
      rawUsers = map['users'] ??
          map['chats'] ??
          map['conversations'] ??
          (data is List ? data : null) ??
          (data is Map
              ? (data['users'] ?? data['chats'] ?? data['conversations'] ?? data['data'])
              : null);
    }
    if (rawUsers is! List) {
      print('[Chat] users missing runtime=${rawUsers.runtimeType}');
      return [];
    }

    final chats = <RecentChatModel>[];
    for (final item in rawUsers) {
      if (item is! Map) continue;
      final raw = Map<String, dynamic>.from(item);
      final person = ApiUserMapper.unwrapPersonMap(raw);
      Map<String, dynamic>? last;
      final lastRaw = raw['last_message'] ??
          raw['latest_message'] ??
          person['last_message'];
      if (lastRaw is Map) {
        last = Map<String, dynamic>.from(lastRaw);
      } else if (lastRaw is List && lastRaw.isNotEmpty && lastRaw.first is Map) {
        last = Map<String, dynamic>.from(lastRaw.first);
      }

      final fromId = RecentChatModel.parseInt(last?['from_user_id']);
      final name = (person['name'] ??
              person['first_name'] ??
              person['firstname'] ??
              '')
          .toString()
          .trim();
      chats.add(
        RecentChatModel(
          lastText: RecentChatModel.previewFromContent(
            last?['content']?.toString() ?? last?['message']?.toString(),
            last?['type']?.toString() ?? 'text',
          ),
          withAvatar: ApiUserMapper.extractMediaUrl(
            person['avatar'] ?? person['image'] ?? person['photo'],
          ),
          withName: name,
          withId: (person['uid'] ?? raw['uid'] ?? '').toString(),
          chatId: (raw['id'] ?? person['id'] ?? '').toString(),
          timestamp: DateTime.tryParse(
                      last?['created_at']?.toString() ?? '')
                  ?.millisecondsSinceEpoch ??
              0,
          pinned: raw['pinned'] == true ||
              raw['pinned'] == 1 ||
              raw['pinned'] == '1',
          isUnread: last != null &&
              last['is_read'] != 1 &&
              last['is_read'] != true &&
              (currentUserId == null || fromId != currentUserId),
        ),
      );
    }
    print('[Chat] parsed ${chats.length} users');
    return chats;
  }

  /// `GET /api/regular-user/user/chat/{name}/{uid}`
  static Future<ChatDetailResult> fetchChatDetail({
    required String name,
    required String uid,
  }) async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.chatDetail(name, uid)),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);

    UserModel? otherUser;
    if (body is Map && body.containsKey('receiver')) {
      otherUser = _userFromBody(body['receiver']);
    }

    dynamic data;
    if (body is Map) {
      data = body['chatmessages'] ?? body['data'] ?? body['messages'] ?? body;
    } else {
      data = body;
    }

    List<dynamic> items = [];
    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = data.values.toList();
    }

    final List<MessageModel> messages = items.map((item) {
      final typeStr = item['type']?.toString().toLowerCase() ?? 'text';
      int typeInt = 0;
      String content = item['message'] ?? item['content'] ?? '';
      String? attachmentUrl;

      final meta = item['meta'];
      if (meta is Map) {
        attachmentUrl = meta['url']?.toString();
      }

      if (content.startsWith('__CALL_INVITE_AUDIO__')) {
        typeInt = 4;
      } else if (content.startsWith('__CALL_INVITE__')) {
        typeInt = 3;
      } else if (content.startsWith('__CALL_END__')) {
        typeInt = 5;
      } else if (typeStr == 'sticker') {
        typeInt = 6;
      } else if (typeStr == 'pdf') {
        typeInt = 7;
      } else if (typeStr == 'gif') {
        typeInt = 8;
      } else if (typeStr == 'image' || typeStr == 'photo') {
        typeInt = 1;
      } else if (typeStr == 'text') {
        typeInt = 0;
      } else {
        typeInt = int.tryParse(typeStr) ?? 0;
      }

      return MessageModel(
        content: content,
        attachmentUrl: attachmentUrl,
        senderID: item['from_user_id']?.toString() ??
            item['sender_id']?.toString() ??
            item['senderID'] ??
            '',
        time: item['created_at'] != null
            ? DateTime.tryParse(item['created_at'])
            : (item['time'] is int
                ? DateTime.fromMillisecondsSinceEpoch(item['time'])
                : null),
        id: item['id']?.toString(),
        type: typeInt,
      );
    }).toList();

    if (body is Map && body['tickets'] is List) {
      final List<dynamic> ticketList = body['tickets'];
      for (var t in ticketList) {
        messages.add(MessageModel(
          type: 2,
          ticket: Map<String, dynamic>.from(t),
          time: t['created_at'] != null
              ? DateTime.tryParse(t['created_at'])
              : null,
          senderID: t['user_id']?.toString(),
          content: 'Ticket: ${t['event']?['title'] ?? ''}',
          id: 'ticket_${t['id']}',
        ));
      }
    }

    messages.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return b.time!.compareTo(a.time!);
    });

    return ChatDetailResult(messages: messages, otherUser: otherUser);
  }

  /// `POST /api/regular-user/send/{id}/messages`
  static Future<void> sendChatMessage({
    required String receiverId,
    String? content,
    File? file,
    String? fileType,
    String? fileName,
  }) async {
    final token = await getToken();
    
    final fields = <String, String>{};
    if (content != null) fields['content'] = content;
    if (fileType != null) fields['attachments[0][type]'] = fileType;
    if (fileName != null) fields['attachments[0][name]'] = fileName;

    final files = <http.MultipartFile>[];
    if (file != null) {
      files.add(await http.MultipartFile.fromPath(
        'attachments[0][file]',
        file.path,
        filename: fileName,
      ));
    }

    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.sendMessage(receiverId),
      token: token,
      fields: fields,
      files: files,
    );

    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `GET /api/regular-user/user/wallet`
  static Future<WalletResult> fetchUserWallet() async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.regularUserWallet),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      if (map['data'] is Map) {
        return WalletResult.fromJson(Map<String, dynamic>.from(map['data'] as Map));
      }
      return WalletResult.fromJson(map);
    }
    return WalletResult.empty;
  }

  /// `POST /api/regular-user/wallet/contact` (multipart `contact_user_id`).
  static Future<void> addWalletContact({required int contactUserId}) async {
    final token = await getToken();
    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.regularUserWalletContact,
      token: token,
      fields: {'contact_user_id': contactUserId.toString()},
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/regular-user/wallet/send-money` (multipart `amount`, `recipientId`).
  static Future<void> sendWalletMoney({
    required double amount,
    required int recipientId,
  }) async {
    final token = await getToken();
    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.regularUserWalletSendMoney,
      token: token,
      fields: {
        'amount': amount.round().toString(),
        'recipientId': recipientId.toString(),
      },
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/regular-user/wallet/request-money` (multipart `amount`, `recipientId`).
  static Future<void> requestWalletMoney({
    required double amount,
    required int recipientId,
  }) async {
    final token = await getToken();
    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.regularUserWalletRequestMoney,
      token: token,
      fields: {
        'amount': amount.round().toString(),
        'recipientId': recipientId.toString(),
      },
    );
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `GET /api/regular-user/wallet/activity`
  static Future<List<WalletActivityItem>> fetchWalletActivity() async {
    final token = await getToken();
    final response = await http.get(
      _uri(ApiEndpoints.regularUserWalletActivity),
      headers: _headers(token: token, json: false),
    );
    final body = _decodeBody(response);
    if (response.statusCode >= 400) _throwFromResponse(response);
    if (body is! Map) return const [];
    final map = Map<String, dynamic>.from(body);
    final raw = map['activity'] ?? (map['data'] is Map ? (map['data'] as Map)['activity'] : null);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => WalletActivityItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// `POST /api/regular-user/wallet/asues/store`
  static Future<void> createWalletAsue({
    required String name,
    required String frequency,
    required double handAmount,
    required int maxMembers,
    required String startDate,
    required bool disclaimerAgreed,
    required List<int> userIds,
  }) async {
    final token = await getToken();
    final fields = <String, String>{
      'name': name,
      'frequency': frequency,
      'hand_amount': handAmount.round().toString(),
      'max_members': maxMembers.toString(),
      'start_date': startDate,
      'disclaimerAgreed': disclaimerAgreed ? '1' : '0',
    };
    for (var i = 0; i < userIds.length; i++) {
      fields['user_ids[$i]'] = userIds[i].toString();
    }

    debugPrint('[Asue] POST ${ApiConfig.baseUrl}${ApiEndpoints.regularUserWalletAsueStore}');
    debugPrint('[Asue] fields=$fields token=${token == null || token.isEmpty ? 'missing' : 'present'}');

    final response = await _sendMultipart(
      'POST',
      ApiEndpoints.regularUserWalletAsueStore,
      token: token,
      fields: fields,
    );

    debugPrint('[Asue] status=${response.statusCode} body=${response.body}');
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/regular-user/wallet/asues/:asue/accept-participation`
  static Future<void> acceptWalletAsueParticipation({required int asueId}) async {
    final token = await getToken();
    final path = ApiEndpoints.regularUserWalletAsueAcceptParticipation(asueId);
    debugPrint('[Asue] POST ${ApiConfig.baseUrl}$path');
    debugPrint('[Asue] accept-participation asue_id=$asueId token=${token == null || token.isEmpty ? 'missing' : 'present'}');
    final response = await _sendMultipart(
      'POST',
      path,
      token: token,
    );
    debugPrint('[Asue] accept-participation status=${response.statusCode} body=${response.body}');
    if (response.statusCode >= 400) _throwFromResponse(response);
  }

  /// `POST /api/regular-user/wallet/asues/:asue/simulate-accept`
  static Future<void> simulateWalletAsueAccept({required int asueId}) async {
    await _postAsueAction(
      path: ApiEndpoints.regularUserWalletAsueSimulateAccept(asueId),
      asueId: asueId,
      label: 'simulate-accept',
    );
  }

  /// `POST /api/regular-user/wallet/asues/:asue/simulate-cycle`
  static Future<void> simulateWalletAsueWeekPayout({required int asueId}) async {
    await _postAsueAction(
      path: ApiEndpoints.regularUserWalletAsueSimulateWeekPayout(asueId),
      asueId: asueId,
      label: 'simulate-cycle',
    );
  }

  static Future<void> _postAsueAction({
    required String path,
    required int asueId,
    required String label,
  }) async {
    final token = await getToken();
    debugPrint('[Asue] POST ${ApiConfig.baseUrl}$path');
    debugPrint('[Asue] $label asue_id=$asueId token=${token == null || token.isEmpty ? 'missing' : 'present'}');
    final response = await _sendMultipart('POST', path, token: token);
    debugPrint('[Asue] $label status=${response.statusCode} body=${response.body}');
    if (response.statusCode >= 400) _throwFromResponse(response);
  }
}
