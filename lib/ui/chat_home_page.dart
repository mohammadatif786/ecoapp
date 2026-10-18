import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:link_up/ui/profile/profile_page.dart';
import 'package:link_up/widgets/linkup_location_sheet.dart';
import '../widgets/linkup_current_user.dart';
import 'package:get/get.dart';
import 'package:link_up/ui/wallet_page.dart';
import 'package:link_up/get_controller/ChatController.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/get_controller/home_controller.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/model/user_model.dart';
import 'package:link_up/model/recent_chat.dart';
import 'package:link_up/model/friend_request_model.dart';
import 'package:link_up/model/chatModel.dart';
import 'package:link_up/ui/widgets/linkup_match_popup.dart';
import 'package:link_up/ui/widgets/linkup_spark_sheet.dart';
import 'package:link_up/utils/country_flag.dart';
import 'package:link_up/package/swipe_card_stack.dart';
import 'package:link_up/ui/profile/linkup_profile_view.dart';
import 'package:link_up/introscreens/screensix.dart';
import 'package:link_up/introscreens/screensone.dart';
import 'package:link_up/ui/notification_page.dart';
import 'package:link_up/ui/chat/chat_composer_actions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'DrawerScreen.dart';
import 'home_page.dart';
import 'package:link_up/ui/vibes_page.dart';
import 'package:link_up/model/home_advertisement.dart';

import 'package:link_up/get_controller/social_controller.dart';

class ChatHomePage extends StatefulWidget {
  @override
  _ChatHomePageState createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> with SingleTickerProviderStateMixin {
  AuthController authController = Get.find(tag: AuthController().toString());
  ChatController chatController = Get.find(tag: ChatController().toString());
  HomeController homeController = Get.find(tag: HomeController().toString());
  SocialController socialController = Get.find<SocialController>();
  late TabController _tabController;
  int _currentTab = 0; // Web default: Swipe tab selected first
  final GlobalKey<SwipeCardStackState> _swipeKey =
      GlobalKey<SwipeCardStackState>();
  SwipeAction _pendingSwipeAction = SwipeAction.like;
  int _localSwipeSeed = 0;
  bool _isDiscoverable = true;
  String _selectedCountryFilter = 'All';
  RangeValues _ageRange = const RangeValues(18, 60);
  RangeValues _distanceRange = const RangeValues(0, 5000);
  String _searchPreference = 'Both';
  final Set<String> _selectedInterests = <String>{};
  bool _chatThreadOpen = false;
  String _activeChatName = 'Aaliyah';
  String _activeChatAvatar = 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&q=70';
  int _chatWallpaperIndex = 0;
  bool _showReceivedRequests = true;
  final TextEditingController _msgController = TextEditingController();
  String _activeChatId = '';
  String _activeLaravelId = '';
  String _activeApiName = '';
  bool _sendingChat = false;

  @override
  void initState() {
    _tabController = TabController(length: 7, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {
        _currentTab = _tabController.index;
      });
      if (!_tabController.indexIsChanging && _tabController.index == 6) {
        chatController.getMessageList();
      }
    });

    // Ensure all data is fresh whenever entering the chat home page
    _refreshPageData();
    super.initState();
  }

  Future<void> _refreshPageData() async {
    chatController.getMatchList();
    chatController.getMessageList();
    socialController.refreshAll();

    if (authController.user != null) {
      homeController.fetchExploreList(
        linkMeWith: authController.user!.value.linkMeWith,
        nationality: authController.user!.value.countryCode,
        userID: authController.user!.value.uid ?? '',
      );
      homeController.fetchFindMatchCards();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) {
    return _ui(context, value * 0.86);
  }

  double _icon(BuildContext context, double value) {
    return _ui(context, value * 0.82);
  }

  String _flagFor(UserModel user) {
    final country = user.country.trim();
    final hardcoded = _flagForCountryName(country);
    if (hardcoded.isNotEmpty) return hardcoded;

    final apiFlag = (user.countryFlag ?? '').trim();
    if (apiFlag.isNotEmpty && apiFlag != '🇧🇸') return apiFlag;

    return countryFlagEmoji(user.countryCode.trim());
  }

  void _openProfile(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LinkUpWebProfilePage(
          user: user,
          ui: _ui,
          font: _font,
          icon: _icon,
          countryText: _countryText(user),
        ),
      ),
    );
  }

  void _openChatForUser(UserModel user) {
    Navigator.pushNamed(
      context,
      RoutePath.chat_message_page,
      arguments: {
        'endUserID': user.uid ?? user.laravelId?.toString() ?? '',
        'endUserName': user.firstName,
        'chatID': '',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAll(() => HomePage());
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffeaf4fc),
        body: Column(
          children: [
            _buildTopBar(context),
            // Location bar removed from main column to save space in Swipe tab.
            // It will be added to specific views if needed.
            _buildTabBar(context),
            Expanded(
              child: GetBuilder<ChatController>(
                tag: ChatController().toString(),
                builder: (_) {
                  return TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildSwibeView(context),
                      _buildFindMatchesView(context),
                      _buildMatchesView(context),
                      _buildFriendsView(context),
                      _buildRequestsView(context),
                      _buildLikesView(context),
                      _buildChatsView(context),
                    ],
                  );
                },
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + _ui(context, 8),
        left: _ui(context, 20),
        right: _ui(context, 18),
        bottom: _ui(context, 12),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff2f9bef), Color(0xff2487e0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.offAll(() => HomePage()),
            child: Image.asset(
              'assets/Vector Smart Object 2.png',
              height: _ui(context, 34),
              width: _ui(context, 112),
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.to(() => const WalletPage()),
            child: Container(
              height: _ui(context, 32),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(_ui(context, 22)),
              ),
              child: Row(
                children: [
                  Icon(Icons.monetization_on_outlined,
                      color: Colors.white, size: _icon(context, 17)),
                  SizedBox(width: _ui(context, 7)),
                  Text(
                    '${homeController.coins}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: _font(context, 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: _ui(context, 14)),
          LinkUpNotificationBell(
            iconSize: _icon(context, 32),
            badgeSize: _ui(context, 26),
            badgeFontSize: _font(context, 14),
          ),
          SizedBox(width: _ui(context, 16)),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage())),
            child: CircleAvatar(
              radius: _ui(context, 18),
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: _ui(context, 15),
                backgroundImage: _avatarProvider(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBar(BuildContext context) {
    return LinkupLocationBar(
      height: _ui(context, 50),
      horizontalPadding: _ui(context, 18),
      iconSize: _icon(context, 24),
      fontSize: _font(context, 18),
      changeFontSize: _font(context, 16),
      textColor: const Color(0xff45536a),
      changeColor: const Color(0xff2589df),
      iconColor: const Color(0xff3198df),
      fontWeight: FontWeight.w800,
      dense: false,
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final tabs = [
      'Swipe',
      'Find Matches',
      'Matches',
      'Friends',
      'Requests',
      'Likes',
      'Chats'
    ];
    return Container(
      height: _ui(context, 54),
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xff4d5b73),
        indicatorColor: Colors.transparent,
        isScrollable: true,
        padding: EdgeInsets.symmetric(vertical: _ui(context, 8)),
        labelPadding: EdgeInsets.symmetric(horizontal: _ui(context, 8)),
        tabs: tabs.asMap().entries.map((entry) {
          final isSelected = _currentTab == entry.key;
          return Tab(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 22)),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xff2f9bef) : Colors.white,
                borderRadius: BorderRadius.circular(_ui(context, 25)),
                border: Border.all(
                  color: isSelected ? const Color(0xff2f9bef) : const Color(0xffe1e8f2),
                  width: 1.8,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xff2f9bef).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ] : [],
              ),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xff4d5b73),
                    fontWeight: FontWeight.w900,
                    fontSize: _font(context, 15),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSwibeView(BuildContext context) {
    if (!_isDiscoverable) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(_ui(context, 16)),
        child: _hiddenProfileCard(context),
      );
    }

    return Obx(() {
      if (!homeController.feedLoaded.value && homeController.exploreList.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final displayItems = homeController.swipeCards.where((item) {
        if (item is UserModel) {
          // Re-use filter logic
          if (item.age >= 18 &&
              item.age <= 99 &&
              (item.age < _ageRange.start.round() ||
                  item.age > _ageRange.end.round())) {
            return false;
          }
          if (_searchPreference != 'Both' &&
              item.gender.trim().isNotEmpty &&
              item.gender.toLowerCase() != _searchPreference.toLowerCase()) {
            return false;
          }
          if (_selectedInterests.isNotEmpty && !item.interests.any(_selectedInterests.contains)) return false;
          if (_selectedCountryFilter != 'All') {
            final sel = _selectedCountryFilter.toLowerCase().trim();
            final c = item.country.toLowerCase().trim();
            final code = item.countryCode.toLowerCase().trim();
            if (!(c == sel || c.contains(sel) || sel.contains(c) || code == sel)) return false;
          }
        }
        return true;
      }).toList();

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              _ui(context, 16),
              _ui(context, 10),
              _ui(context, 16),
              0,
            ),
            child: Row(
              children: [
                _smallChip(
                  context,
                  'Filters',
                  Icons.tune,
                  onTap: () => _showFiltersSheet(context),
                ),
                const Spacer(),
                _smallChip(
                  context,
                  'Hide Profile',
                  Icons.visibility_off_outlined,
                  onTap: _toggleDiscoverable,
                ),
              ],
            ),
          ),
          Expanded(
            child: SwipeCardStack(
              key: _swipeKey,
              padding: EdgeInsets.zero,
              visibleCount: 3,
              threshold: 25,
              scaleInterval: 0.03,
              translationInterval: 0,
              children: [
                SwiperItem(builder: (pos, prog) => _buildGoHomeCard(context, usersFiltered: displayItems.isEmpty && homeController.swipeCards.isNotEmpty)), // Index 0 (Bottom)
                ...displayItems.map((item) { // Index 1+
                  if (item is UserModel) {
                    return SwiperItem(
                      builder: (position, progress) {
                        return _buildProfileCard(context, item, position, progress);
                      },
                    );
                  } else if (item is HomeAdvertisement) {
                    return SwiperItem(
                      builder: (position, progress) {
                        return _buildAdCard(context, item);
                      },
                    );
                  }
                  return SwiperItem(builder: (_, __) => const SizedBox.shrink());
                }).toList(),
              ],
              onSwipe: (index, position) {
                if (index == 0) {
                  Get.offAll(() => HomePage());
                  return;
                }

                final itemIndex = index - 1;
                if (itemIndex < 0 || itemIndex >= displayItems.length) {
                  return;
                }

                final item = displayItems[itemIndex];
                if (item is UserModel) {
                  final action = position == SwiperPosition.Left
                      ? SwipeAction.dislike
                      : _pendingSwipeAction;
                  homeController.recordSwipe(item, action);

                  if (action == SwipeAction.like || action == SwipeAction.love) {
                    _showLoveBurst(item, isPriority: action == SwipeAction.love);
                    if (_shouldShowMatch(item, action)) {
                      Future.delayed(const Duration(milliseconds: 280), () {
                        if (mounted) _showMatchPopup(item);
                      });
                    }
                  }
                }
                homeController.onCardSwiped(item);
                _pendingSwipeAction = SwipeAction.like;
              },
              onRewind: (index, position) {},
              onEnd: () {
                if (homeController.hasMorePages) {
                  homeController.loadNextPage();
                }
              },
            ),
          ),
          if (homeController.loadingMore.value)
             const Padding(
               padding: EdgeInsets.only(bottom: 10),
               child: CircularProgressIndicator(),
             ),
          SizedBox(height: _ui(context, 10)),
          _swipeActionButtons(context),
          SizedBox(height: _ui(context, 20)),
        ],
      );
    });
  }

  Widget _buildFindMatchesView(BuildContext context) {
    if (!_isDiscoverable) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(_ui(context, 16)),
              child: _hiddenProfileCard(context),
            ),
          ),
        ],
      );
    }

    return Obx(() {
      if (!homeController.findMatchesLoaded.value &&
          homeController.findMatchCards.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final matches = _filteredExploreUsers();
      return RefreshIndicator(
        onRefresh: _refreshPageData,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(_ui(context, 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _smallChip(
                          context,
                          'Apply Filters',
                          Icons.tune,
                          onTap: () => _showFiltersSheet(context),
                        ),
                        const Spacer(),
                        _smallChip(
                          context,
                          'Hide Profile',
                          Icons.visibility_off_outlined,
                          onTap: _toggleDiscoverable,
                        ),
                      ],
                    ),
                    SizedBox(height: _ui(context, 16)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Find Matches',
                          style: TextStyle(
                            color: const Color(0xff10182b),
                            fontSize: _font(context, 26),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: _ui(context, 12)),
                        Padding(
                          padding: EdgeInsets.only(bottom: _ui(context, 4)),
                          child: Text(
                            _selectedCountryFilter == 'All'
                                ? '${matches.length} nearby'
                                : '${matches.length} in $_selectedCountryFilter',
                            style: TextStyle(
                              color: const Color(0xff8b99b2),
                              fontSize: _font(context, 15),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _ui(context, 16)),
                    if (matches.isEmpty && !homeController.isLoadingFindMatches.value)
                      Padding(
                        padding: EdgeInsets.only(top: _ui(context, 80)),
                        child: Center(
                          child: Text(
                            'No matches found',
                            style: TextStyle(
                              fontSize: _font(context, 18),
                              color: const Color(0xff627085),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else if (matches.isEmpty && homeController.isLoadingFindMatches.value)
                      Padding(
                        padding: EdgeInsets.only(top: _ui(context, 80)),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    else
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: _ui(context, 12),
                        mainAxisSpacing: _ui(context, 12),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.72,
                        children: matches.map((user) {
                          return _buildMatchCard(context, user);
                        }).toList(),
                      ),
                    if (homeController.isLoadingFindMatches.value && matches.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: _ui(context, 20)),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _smallChip(BuildContext context, String label, IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_ui(context, 14)),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: _ui(context, 10), vertical: _ui(context, 6)),
          decoration: BoxDecoration(
            color: const Color(0xfff0f4f9),
            borderRadius: BorderRadius.circular(_ui(context, 8)),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xff4d5b73),
                  fontSize: _font(context, 13),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: _ui(context, 4)),
              Icon(icon, color: const Color(0xff4d5b73), size: _icon(context, 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countryFilters(BuildContext context) {
    final List<List<String>> countries = [['All', '🌎']];
    if (homeController.countries.isNotEmpty) {
      for (final c in homeController.countries) {
        countries.add([c['name'].toString(), '📍']);
      }
    } else {
      countries.addAll([
        ['Trinidad & Tobago', '🇹🇹'],
        ['Jamaica', '🇯🇲'],
        ['Brazil', '🇧🇷'],
      ]);
    }
    return SizedBox(
      height: _ui(context, 38),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: countries.length,
        separatorBuilder: (_, __) => SizedBox(width: _ui(context, 10)),
        itemBuilder: (context, index) {
          final name = countries[index][0];
          final isSelected = _selectedCountryFilter == name;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_ui(context, 20)),
              onTap: () {
                setState(() => _selectedCountryFilter = name);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xff2f9bef) : Colors.white,
                  borderRadius: BorderRadius.circular(_ui(context, 20)),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xff2f9bef)
                        : const Color(0xffe1e8f2),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xff2f9bef).withOpacity(0.20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(countries[index][1], style: TextStyle(fontSize: _ui(context, 16))),
                    SizedBox(width: _ui(context, 6)),
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xff4d5b73),
                        fontWeight: FontWeight.w800,
                        fontSize: _font(context, 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  List<UserModel> _filteredExploreUsers() {
    final users = homeController.findMatchCards.toList();
    return users.where((user) {
      final age = user.age;
      if (age >= 18 &&
          age <= 99 &&
          (age < _ageRange.start.round() || age > _ageRange.end.round())) {
        return false;
      }

      final gender = user.gender.trim();
      if (_searchPreference != 'Both' &&
          gender.isNotEmpty &&
          gender.toLowerCase() != _searchPreference.toLowerCase()) {
        return false;
      }

      if (_selectedInterests.isNotEmpty &&
          !user.interests.any(_selectedInterests.contains)) {
        return false;
      }

      if (_selectedCountryFilter == 'All') return true;

      final selected = _selectedCountryFilter.toLowerCase().trim();
      final country = user.country.toLowerCase().trim();
      final code = user.countryCode.toLowerCase().trim();
      return country == selected ||
          country.contains(selected) ||
          selected.contains(country) ||
          code == selected;
    }).toList();
  }

  void _toggleDiscoverable() {
    setState(() => _isDiscoverable = !_isDiscoverable);
    final message = _isDiscoverable
        ? 'Your profile is visible on LinkUp'
        : 'Your profile is hidden from LinkUp';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Widget _hiddenProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: _ui(context, 18)),
      padding: EdgeInsets.symmetric(
        horizontal: _ui(context, 22),
        vertical: _ui(context, 28),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: _ui(context, 54),
            width: _ui(context, 54),
            decoration: BoxDecoration(
              color: const Color(0xfff0f4f9),
              borderRadius: BorderRadius.circular(_ui(context, 16)),
            ),
            child: Icon(Icons.visibility_off_outlined,
                color: const Color(0xff8b99b2), size: _icon(context, 30)),
          ),
          SizedBox(height: _ui(context, 14)),
          Text(
            "You're hidden from LinkUp",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xff10182b),
              fontSize: _font(context, 17),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: _ui(context, 6)),
          Text(
            "Your profile won't appear in matching or swipe. Turn discovery on to start linking up.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xff8b99b2),
              fontSize: _font(context, 13),
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          SizedBox(height: _ui(context, 18)),
          SizedBox(
            width: double.infinity,
            height: _ui(context, 48),
            child: ElevatedButton(
              onPressed: _toggleDiscoverable,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2f9bef),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_ui(context, 16)),
                ),
                elevation: 0,
              ),
              child: Text(
                'Show me on LinkUp',
                style: TextStyle(
                  fontSize: _font(context, 15),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _flagForCountryName(String countryName) {
    final country = countryName.toLowerCase().trim();
    if (country == 'united states' || country == 'usa') return '🇺🇸';
    if (country == 'canada') return '🇨🇦';
    if (country == 'united kingdom' || country == 'uk') return '🇬🇧';
    if (country == 'bahamas') return '🇧🇸';
    if (country == 'anguilla') return '🇦🇮';
    if (country == 'barbados') return '🇧🇧';
    if (country == 'jamaica') return '🇯🇲';
    if (country == 'trinidad' || country.contains('trinidad')) return '🇹🇹';
    if (country == 'brazil') return '🇧🇷';
    if (country == 'bahrain') return '🇧🇭';
    return '';
  }

  void _showFiltersSheet(BuildContext context) {
    RangeValues age = _ageRange;
    RangeValues distance = _distanceRange;
    String preference = _searchPreference;
    String countryChoice = _selectedCountryFilter;
    final selected = Set<String>.from(_selectedInterests);
    final interests = [
      'Music Festivals',
      'Travel',
      'Cooking',
      'Books',
      'Yoga',
      'Movies',
      'Wine',
      'Church Events',
      'Liming',
      'Carnival / Mas',
      'Junkanoo',
      'Soca Fêtes',
      'Reggae & Dancehall',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.86,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 28))),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      _ui(context, 18),
                      _ui(context, 16),
                      _ui(context, 14),
                      _ui(context, 14),
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff2f9bef), Color(0xff2487e0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Apply Filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: _font(context, 22),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: Icon(Icons.close, color: Colors.white, size: _icon(context, 24)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(_ui(context, 18)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _filterTitle(context, 'Age Range'),
                          RangeSlider(
                            values: age,
                            min: 18,
                            max: 60,
                            divisions: 42,
                            activeColor: const Color(0xff2f9bef),
                            inactiveColor: const Color(0xffcfe2f7),
                            onChanged: (v) => setSheetState(() => age = v),
                          ),
                          _rangeCaps(context, age.start.round().toString(), age.end.round().toString()),
                          SizedBox(height: _ui(context, 18)),
                          _filterTitle(context, 'Distance Range (km)'),
                          RangeSlider(
                            values: distance,
                            min: 0,
                            max: 5000,
                            divisions: 50,
                            activeColor: const Color(0xff2f9bef),
                            inactiveColor: const Color(0xffcfe2f7),
                            onChanged: (v) => setSheetState(() => distance = v),
                          ),
                          _rangeCaps(context, distance.start.round().toString(), distance.end.round().toString()),
                          SizedBox(height: _ui(context, 18)),
                          _filterTitle(context, 'Search Preferences'),
                          Wrap(
                            spacing: _ui(context, 10),
                            runSpacing: _ui(context, 8),
                            children: ['Male', 'Female', 'Both'].map((value) {
                              final active = preference == value;
                              return ChoiceChip(
                                selected: active,
                                label: Text(value),
                                onSelected: (_) => setSheetState(() => preference = value),
                                selectedColor: const Color(0xff2f9bef),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xffd7e5f5)),
                                labelStyle: TextStyle(
                                  color: active ? Colors.white : const Color(0xff4d5b73),
                                  fontWeight: FontWeight.w900,
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: _ui(context, 18)),
                          _filterTitle(context, 'Country'),
                          SizedBox(height: _ui(context, 8)),
                          DropdownButtonFormField<String>(
                            value: countryChoice,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xfff8fbff),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: _ui(context, 14),
                                vertical: _ui(context, 12),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(_ui(context, 14)),
                                borderSide: const BorderSide(color: Color(0xffd7e5f5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(_ui(context, 14)),
                                borderSide: const BorderSide(color: Color(0xffd7e5f5)),
                              ),
                            ),
                            items: <String>{
                              'All',
                              countryChoice,
                              ...homeController.countries
                                  .map((country) => country['name']?.toString() ?? '')
                                  .where((name) => name.isNotEmpty),
                              ...homeController.exploreList
                                  .map((user) => user.country.trim())
                                  .where((name) => name.isNotEmpty),
                              ...homeController.findMatchCards
                                  .map((user) => user.country.trim())
                                  .where((name) => name.isNotEmpty),
                            }.map((name) {
                              final flag = _flagForCountryName(name);
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(flag.isEmpty ? name : '$flag  $name'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setSheetState(() => countryChoice = value);
                              }
                            },
                          ),
                          SizedBox(height: _ui(context, 12)),
                          _filterTitle(context, 'Interests'),
                          Wrap(
                            spacing: _ui(context, 8),
                            runSpacing: _ui(context, 8),
                            children: interests.map((interest) {
                              final active = selected.contains(interest);
                              return FilterChip(
                                selected: active,
                                label: Text(interest),
                                onSelected: (v) {
                                  setSheetState(() {
                                    if (v) {
                                      selected.add(interest);
                                    } else {
                                      selected.remove(interest);
                                    }
                                  });
                                },
                                selectedColor: const Color(0xffeaf4fe),
                                backgroundColor: Colors.white,
                                checkmarkColor: const Color(0xff2f9bef),
                                side: const BorderSide(color: Color(0xffd7e5f5)),
                                labelStyle: const TextStyle(
                                  color: Color(0xff4d5b73),
                                  fontWeight: FontWeight.w800,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(_ui(context, 14)),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xffe8eef7))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _ageRange = const RangeValues(18, 60);
                                _distanceRange = const RangeValues(0, 5000);
                                _searchPreference = 'Both';
                                _selectedInterests.clear();
                                _selectedCountryFilter = 'All';
                              });
                              Navigator.pop(sheetContext);
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(0, _ui(context, 48)),
                              side: const BorderSide(color: Color(0xffd7e5f5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_ui(context, 16))),
                            ),
                            child: Text('Reset', style: TextStyle(color: const Color(0xff4d5b73), fontWeight: FontWeight.w900, fontSize: _font(context, 15))),
                          ),
                        ),
                        SizedBox(width: _ui(context, 12)),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _ageRange = age;
                                _distanceRange = distance;
                                _searchPreference = preference;
                                _selectedCountryFilter = countryChoice;
                                _selectedInterests
                                  ..clear()
                                  ..addAll(selected);
                              });
                              Navigator.pop(sheetContext);
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(0, _ui(context, 48)),
                              backgroundColor: const Color(0xff2f9bef),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_ui(context, 16))),
                            ),
                            child: Text('Show Results', style: TextStyle(fontWeight: FontWeight.w900, fontSize: _font(context, 15))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterTitle(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: const Color(0xff10182b),
        fontSize: _font(context, 15),
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _rangeCaps(BuildContext context, String left, String right) {
    Widget cap(String value) => Container(
          padding: EdgeInsets.symmetric(horizontal: _ui(context, 14), vertical: _ui(context, 8)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_ui(context, 12)),
            border: Border.all(color: const Color(0xffd7e5f5)),
          ),
          child: Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [cap(left), cap(right)],
    );
  }

  Widget _buildMatchesView(BuildContext context) {
    return Obx(() {
      final users = socialController.matchesList;

      return Column(
        children: [
          _buildLocationBar(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPageData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  _ui(context, 12),
                  _ui(context, 12),
                  _ui(context, 12),
                  _ui(context, 24),
                ),
                children: [
                  Text(
                    'Your Matches',
                    style: TextStyle(
                      color: const Color(0xff10182b),
                      fontSize: _font(context, 25),
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: _ui(context, 6)),
                  Text(
                    'You both liked each other 💜',
                    style: TextStyle(
                      color: const Color(0xff8798b2),
                      fontSize: _font(context, 13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: _ui(context, 12)),
                  if (socialController.isLoadingMatches.value)
                    const Center(child: CircularProgressIndicator())
                  else if (users.isEmpty)
                    Container(
                      margin: EdgeInsets.only(top: _ui(context, 12)),
                      padding: EdgeInsets.all(_ui(context, 24)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_ui(context, 20)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.favorite_border,
                              color: const Color(0xffa8b6c9), size: _icon(context, 38)),
                          SizedBox(height: _ui(context, 10)),
                          Text(
                            'No matches yet',
                            style: TextStyle(
                              fontSize: _font(context, 16),
                              color: const Color(0xff627085),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...users
                        .map((user) =>
                            _buildMatchListItem(context, user, action: 'Message'))
                        .toList(),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFriendsView(BuildContext context) {
    return Obx(() {
      final users = socialController.friendsList;

      return Column(
        children: [
          _buildLocationBar(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPageData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(_ui(context, 16)),
                children: [
                  Text(
                    'Friends',
                    style: TextStyle(
                      color: const Color(0xff10182b),
                      fontSize: _font(context, 26),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: _ui(context, 20)),
                  if (socialController.isLoadingFriends.value)
                    const Center(child: CircularProgressIndicator())
                  else if (users.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: _ui(context, 40)),
                        child: Text('No friends yet',
                            style: TextStyle(
                              fontSize: _font(context, 18),
                              color: const Color(0xff627085),
                            )),
                      ),
                    )
                  else
                    ...users
                        .map((user) =>
                            _buildMatchListItem(context, user, action: 'Message'))
                        .toList(),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildRequestsView(BuildContext context) {
    return Obx(() {
      final requests = _showReceivedRequests
          ? socialController.friendRequests
          : socialController.sentRequests;

      return Column(
        children: [
          _buildLocationBar(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPageData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(_ui(context, 16)),
                children: [
                  Text(
                    'Friend Requests',
                    style: TextStyle(
                      color: const Color(0xff10182b),
                      fontSize: _font(context, 26),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: _ui(context, 10)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _showReceivedRequests = true),
                        child: _buildTogglePill(
                            context, 'Received', _showReceivedRequests),
                      ),
                      SizedBox(width: _ui(context, 8)),
                      GestureDetector(
                        onTap: () => setState(() => _showReceivedRequests = false),
                        child: _buildTogglePill(
                            context, 'Sent', !_showReceivedRequests),
                      ),
                    ],
                  ),
                  SizedBox(height: _ui(context, 20)),
                  if (socialController.isLoadingRequests.value)
                    const Center(child: CircularProgressIndicator())
                  else if (requests.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: _ui(context, 40)),
                        child: Text('No requests yet',
                            style: TextStyle(
                              fontSize: _font(context, 18),
                              color: const Color(0xff627085),
                            )),
                      ),
                    )
                  else
                    ...requests
                        .map((req) => _buildRequestListItem(context, req))
                        .toList(),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLikesView(BuildContext context) {
    return Obx(() {
      final users = socialController.likesList;

      return Column(
        children: [
          _buildLocationBar(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPageData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(_ui(context, 16)),
                children: [
                  Text(
                    'Likes You',
                    style: TextStyle(
                      color: const Color(0xff10182b),
                      fontSize: _font(context, 26),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'People who liked your profile 💛',
                    style: TextStyle(
                      color: const Color(0xff8b99b2),
                      fontSize: _font(context, 15),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: _ui(context, 20)),
                  if (socialController.isLoadingLikes.value)
                    const Center(child: CircularProgressIndicator())
                  else if (users.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: _ui(context, 40)),
                        child: Text('No likes yet',
                            style: TextStyle(
                              fontSize: _font(context, 18),
                              color: const Color(0xff627085),
                            )),
                      ),
                    )
                  else
                    ...users
                        .map((user) =>
                            _buildMatchListItem(context, user, action: 'Like Back'))
                        .toList(),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildChatsView(BuildContext context) {
    if (_chatThreadOpen) {
      return _buildChatThreadView(context);
    }

    return Obx(() {
      final chats = chatController.recentChatList.toList();
      final loading = chatController.isLoadingChats.value;
      final error = chatController.chatsError.value;

      return Column(
        children: [
          _buildLocationBar(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPageData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(_ui(context, 12)),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _ui(context, 4),
                      vertical: _ui(context, 8),
                    ),
                    child: Text(
                      'Chats',
                      style: TextStyle(
                        color: const Color(0xff10182b),
                        fontSize: _font(context, 26),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (loading && chats.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (error != null && chats.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: _ui(context, 40)),
                      child: Center(
                        child: Text(
                          'Could not load chats',
                          style: TextStyle(
                            fontSize: _font(context, 16),
                            color: const Color(0xff627085),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else if (chats.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: _ui(context, 40)),
                        child: Text(
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: _font(context, 18),
                            color: const Color(0xff627085),
                          ),
                        ),
                      ),
                    )
                  else
                    ...chats.map((chat) => _buildChatListItem(context, chat)),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDummyChatListItem(BuildContext context, Map<String, String> chat) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeChatName = chat['name'] ?? 'Aaliyah';
          _activeChatAvatar = chat['avatar'] ?? '';
          _chatThreadOpen = true;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: _ui(context, 12)),
        padding: EdgeInsets.all(_ui(context, 13)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 18)),
        ),
        child: Row(
          children: [
            _chatAvatar(context, chat['avatar'] ?? '', _ui(context, 27)),
            SizedBox(width: _ui(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat['name'] ?? '',
                    style: TextStyle(
                      color: const Color(0xff142035),
                      fontSize: _font(context, 17),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: _ui(context, 2)),
                  Text(
                    chat['message'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xff63718a),
                      fontSize: _font(context, 12.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              chat['time'] ?? '10:45',
              style: TextStyle(
                color: const Color(0xff8b99b2),
                fontSize: _font(context, 12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatThreadView(BuildContext context) {
    return Obx(() {
      final messages = chatController.chatMessages.toList();
      return ListView(
      padding: EdgeInsets.all(_ui(context, 12)),
      children: [
        _chatThreadHeader(context),
        SizedBox(height: _ui(context, 12)),
        Container(
          padding: EdgeInsets.fromLTRB(
            _ui(context, 10),
            _ui(context, 20),
            _ui(context, 10),
            _ui(context, 12),
          ),
          decoration: BoxDecoration(
            color: _chatWallpaperColor(),
            borderRadius: BorderRadius.circular(_ui(context, 16)),
            image: _chatWallpaperIndex == 0
                ? const DecorationImage(
                    image: NetworkImage('https://www.transparenttextures.com/patterns/subtle-dots.png'),
                    repeat: ImageRepeat.repeat,
                    opacity: 0.08,
                  )
                : null,
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: _ui(context, 12), vertical: _ui(context, 5)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(_ui(context, 99)),
                ),
                child: Text(
                  'Today',
                  style: TextStyle(
                    color: const Color(0xff63718a),
                    fontSize: _font(context, 12),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: _ui(context, 14)),
              if (messages.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: _ui(context, 24)),
                  child: Text(
                    'No messages yet',
                    style: TextStyle(color: const Color(0xff8b99b2), fontSize: _font(context, 13), fontWeight: FontWeight.w700),
                  ),
                ),
              ...messages.reversed.map((msg) {
                final isMe = msg.senderID == authController.user?.value.uid ||
                             msg.senderID == authController.user?.value.laravelId?.toString();
                return Padding(
                  padding: EdgeInsets.only(bottom: _ui(context, 8)),
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: _messageBubble(context, msg, isMe),
                  ),
                );
              }),
            ],
          ),
        ),
        SizedBox(height: _ui(context, 12)),
        _chatComposer(context),
      ],
    );
    });
  }

  Widget _chatThreadHeader(BuildContext context) {
    final user = chatController.endUser;
    final name = user?.firstName ?? _activeChatName;
    final avatar = user?.avatar ?? _activeChatAvatar;

    return Container(
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 18)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _chatThreadOpen = false),
            child: Icon(Icons.arrow_back, size: _icon(context, 22), color: Colors.black),
          ),
          SizedBox(width: _ui(context, 12)),
          _chatAvatar(context, avatar, _ui(context, 23)),
          SizedBox(width: _ui(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: const Color(0xff142035),
                    fontSize: _font(context, 17),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'online',
                  style: TextStyle(
                    color: const Color(0xff18b970),
                    fontSize: _font(context, 11),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _roundChatIcon(context, Icons.visibility_outlined, () {
            if (user != null) _openProfile(user);
          }),
          SizedBox(width: _ui(context, 8)),
          _roundChatIcon(context, Icons.call_outlined, () => _showSubscriptionSheet(context)),
          SizedBox(width: _ui(context, 8)),
          _roundChatIcon(context, Icons.videocam_outlined, () => _showSubscriptionSheet(context)),
        ],
      ),
    );
  }

  Widget _chatComposer(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _composerChip(context, '😊 Emojis', _openEmojiPicker),
                _composerChip(context, '🎞️ GIF', _sendGif),
                _composerChip(context, '🖼️ Photo', _sendPhoto),
                _composerChip(context, '📎 PDF', _sendPdf),
                _composerChip(context, '📍 Location', _sendLocation),
                _composerChip(context, '🎟️ Ticket', () => _showTicketSheet(context)),
              ],
            ),
          ),
          SizedBox(height: _ui(context, 8)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  style: TextStyle(
                    fontSize: _font(context, 15),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(color: Color(0xff9aa8bc)),
                    contentPadding: EdgeInsets.symmetric(horizontal: _ui(context, 14), vertical: _ui(context, 10)),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_ui(context, 24)),
                      borderSide: const BorderSide(color: Color(0xffdce6f2), width: 1.4),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_ui(context, 24)),
                      borderSide: const BorderSide(color: Color(0xffdce6f2), width: 1.4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_ui(context, 24)),
                      borderSide: const BorderSide(color: Color(0xff2f9bef), width: 1.4),
                    ),
                  ),
                  onSubmitted: (_) => _sendTypedMessage(),
                ),
              ),
              SizedBox(width: _ui(context, 8)),
              GestureDetector(
                onTap: _sendTypedMessage,
                child: Container(
                  width: _ui(context, 44),
                  height: _ui(context, 44),
                  decoration: const BoxDecoration(
                    color: Color(0xff2f9bef),
                    shape: BoxShape.circle,
                  ),
                  child: _sendingChat
                      ? Padding(
                          padding: EdgeInsets.all(_ui(context, 12)),
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.send, color: Colors.white, size: _icon(context, 22)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _threadApiName {
    if (_activeApiName.isNotEmpty) return _activeApiName;
    final parts = _activeChatName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? _activeChatName : parts.first;
  }

  Future<void> _sendChatPayload({String? text, File? file, String? fileType, String? fileName}) async {
    final targetId = _activeLaravelId.isNotEmpty ? _activeLaravelId : _activeChatId;
    if (targetId.isEmpty || _sendingChat) return;
    setState(() => _sendingChat = true);
    try {
      await chatController.sendMessage(
        targetId,
        text,
        file: file,
        fileType: fileType,
        fileName: fileName,
        historyName: _threadApiName,
        historyUid: _activeChatId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _sendingChat = false);
    }
  }

  Future<void> _sendTypedMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    await _sendChatPayload(text: text);
  }

  Future<void> _openEmojiPicker() async {
    await ChatComposerActions.showEmojiPicker(
      context: context,
      controller: _msgController,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _sendGif() async {
    final url = await ChatComposerActions.showGifPicker(context);
    if (url == null || !mounted) return;
    await _sendChatPayload(text: url);
  }

  Future<void> _sendPhoto() async {
    try {
      final picked = await ChatComposerActions.pickPhoto();
      if (picked == null || !mounted) return;
      await _sendChatPayload(file: picked.file, fileType: picked.type, fileName: picked.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick photo'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _sendPdf() async {
    try {
      final picked = await ChatComposerActions.pickPdf();
      if (picked == null || !mounted) return;
      await _sendChatPayload(file: picked.file, fileType: picked.type, fileName: picked.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick PDF'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _sendLocation() async {
    try {
      final content = await ChatComposerActions.currentLocationContent();
      if (!mounted) return;
      if (content == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is needed to share your location.'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      await _sendChatPayload(text: content);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share location'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Widget _messageBubble(BuildContext context, MessageModel msg, bool mine) {
    final text = msg.content ?? '';
    final media = (msg.attachmentUrl != null && msg.attachmentUrl!.isNotEmpty) ? msg.attachmentUrl! : text;
    final time = msg.time != null
        ? '${msg.time!.hour.toString().padLeft(2, '0')}:${msg.time!.minute.toString().padLeft(2, '0')}'
        : '';
    final lower = media.toLowerCase();
    final isGif = msg.type == 8 || lower.contains('giphy.com') || lower.endsWith('.gif');
    final isPhoto = msg.type == 1 ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
    final isPdf = msg.type == 7 || lower.endsWith('.pdf');
    final isLocation = text.startsWith('📍') || lower.contains('maps.google.com') || lower.contains('maps.apple.com');

    Widget body;
    if ((isGif || isPhoto) && media.isNotEmpty) {
      body = ClipRRect(
        borderRadius: BorderRadius.circular(_ui(context, 10)),
        child: media.startsWith('http')
            ? Image.network(media, height: _ui(context, 160), width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _bubbleHint(context, isGif ? 'GIF' : 'Photo', mine))
            : Image.file(File(media), height: _ui(context, 160), width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _bubbleHint(context, 'Photo', mine)),
      );
    } else if (isPdf) {
      body = _bubbleHint(context, '📎 PDF', mine);
    } else if (isLocation) {
      body = GestureDetector(
        onTap: () {
          final match = RegExp(r'https?://[^\s]+').firstMatch(text);
          if (match != null) {
            launchUrl(Uri.parse(match.group(0)!), mode: LaunchMode.externalApplication);
          }
        },
        child: _bubbleHint(context, '📍 Location', mine),
      );
    } else {
      body = Text(
        text,
        style: TextStyle(
          color: mine ? Colors.white : const Color(0xff142035),
          fontSize: _font(context, 14),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
      padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 10), _ui(context, 12), _ui(context, 7)),
      decoration: BoxDecoration(
        color: mine ? const Color(0xff2f9bef) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_ui(context, 14)),
          topRight: Radius.circular(_ui(context, 14)),
          bottomLeft: Radius.circular(_ui(context, mine ? 14 : 4)),
          bottomRight: Radius.circular(_ui(context, mine ? 4 : 14)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          body,
          SizedBox(height: _ui(context, 2)),
          Text(
            time,
            style: TextStyle(
              color: mine ? Colors.white.withOpacity(0.8) : const Color(0xff8b99b2),
              fontSize: _font(context, 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubbleHint(BuildContext context, String label, bool mine) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: mine ? Colors.white : const Color(0xff142035),
            fontSize: _font(context, 14),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _composerChip(BuildContext context, String label, VoidCallback onTap, {bool selected = false}) {
    return Padding(
      padding: EdgeInsets.only(right: _ui(context, 6)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: _ui(context, 11), vertical: _ui(context, 7)),
          decoration: BoxDecoration(
            color: selected ? const Color(0xff2f9bef) : const Color(0xfff2f6fb),
            borderRadius: BorderRadius.circular(_ui(context, 99)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xff142035),
              fontSize: _font(context, 12),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundChatIcon(BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _ui(context, 34),
        height: _ui(context, 34),
        decoration: const BoxDecoration(
          color: Color(0xffeef6ff),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xff2f9bef), size: _icon(context, 18)),
      ),
    );
  }

  Widget _chatAvatar(BuildContext context, String avatar, double radius) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar.isEmpty
              ? Text(_activeChatName.isNotEmpty ? _activeChatName[0].toUpperCase() : '?')
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: _ui(context, 10),
            height: _ui(context, 10),
            decoration: BoxDecoration(
              color: const Color(0xff19b970),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Color _chatWallpaperColor() {
    final colors = <Color>[
      const Color(0xfffff7ec),
      const Color(0xffd7f1ff),
      const Color(0xffffcf81),
      const Color(0xffbcf0cd),
      const Color(0xff10182b),
      const Color(0xffe3d7ff),
      const Color(0xffff69a3),
      const Color(0xfff8fbff),
    ];
    return colors[_chatWallpaperIndex.clamp(0, colors.length - 1)];
  }

  void _showWallpaperSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final colors = <Color>[
              const Color(0xfffff7ec),
              const Color(0xff79d6ff),
              const Color(0xffffa650),
              const Color(0xff69dd91),
              const Color(0xff10182b),
              const Color(0xffd8c9ff),
              const Color(0xffff4aa0),
              const Color(0xfff8fbff),
            ];
            return Container(
              margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + _ui(context, 80)),
              padding: EdgeInsets.all(_ui(context, 16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Chat Wallpaper',
                          style: TextStyle(fontSize: _font(context, 20), fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  Divider(color: Colors.grey.shade200),
                  SizedBox(height: _ui(context, 12)),
                  Text(
                    'Choose a theme for this chat, or bring in your own photo.',
                    style: TextStyle(color: const Color(0xff8b99b2), fontSize: _font(context, 12), fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: _ui(context, 12)),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: _ui(context, 8),
                      mainAxisSpacing: _ui(context, 8),
                      childAspectRatio: 1.45,
                    ),
                    itemCount: colors.length,
                    itemBuilder: (_, index) {
                      final selected = _chatWallpaperIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _chatWallpaperIndex = index);
                          modalSetState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors[index],
                            borderRadius: BorderRadius.circular(_ui(context, 12)),
                            border: Border.all(
                              color: selected ? const Color(0xff2f9bef) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? const Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.check_circle, color: Colors.white, size: 18),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: _ui(context, 12)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: _ui(context, 18)),
                    decoration: BoxDecoration(
                      color: const Color(0xfff8fbff),
                      borderRadius: BorderRadius.circular(_ui(context, 14)),
                      border: Border.all(color: const Color(0xffe5edf7)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.file_upload_outlined, color: Color(0xff5b53ff)),
                        Text('Upload from Device', style: TextStyle(fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSubscriptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.86,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24))),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(_ui(context, 16), _ui(context, 16), _ui(context, 10), _ui(context, 14)),
              decoration: const BoxDecoration(
                color: Color(0xff2f9bef),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LinkUp Subscription', style: TextStyle(color: Colors.white, fontSize: _font(context, 20), fontWeight: FontWeight.w900)),
                        Text('Unlock more across the platform', style: TextStyle(color: Colors.white, fontSize: _font(context, 12))),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(_ui(context, 14)),
                children: [
                  _subscriptionNote(context),
                  _subscriptionFree(context),
                  _subscriptionPlan(context, '☀️ Calor', 'The heat — go social', r'$4.99/mo', ['Everything in Brisa', 'Go Live & earn 🎥', 'Video & voice calls 📞', 'Clubs & Restaurants near you 🍸', 'Reduced ads'], 'Choose Calor'),
                  _subscriptionPlan(context, '🥁 Ritmo', 'Find your rhythm — sell & grow', r'$9.99/mo', ['Everything in Calor', 'Sell on Marketplace 🛍️', 'Boost store listings', 'Priority feed placement'], 'Choose Ritmo', popular: true),
                  _subscriptionPlan(context, '🏆 El Dorado', 'Premium — unlock it all', r'$19.99/mo', ['Everything in Ritmo', 'Boost events platform-wide', 'Verified badge', 'Advanced analytics'], 'Choose El Dorado'),
                  _subscriptionPlan(context, '🎉 Carnaval', 'The ultimate celebration', r'$39.99/mo', ['Everything in El Dorado', 'Dedicated manager', 'Lowest payout fees', 'VIP event access'], 'Choose Carnaval'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subscriptionNote(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: _ui(context, 12)),
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(
        color: const Color(0xffeef6ff),
        borderRadius: BorderRadius.circular(_ui(context, 14)),
        border: Border.all(color: const Color(0xffd8e7fb)),
      ),
      child: Row(
        children: [
          Container(
            width: _ui(context, 38),
            height: _ui(context, 38),
            decoration: BoxDecoration(color: const Color(0xff2f9bef), borderRadius: BorderRadius.circular(_ui(context, 10))),
            child: const Icon(Icons.videocam, color: Colors.white),
          ),
          SizedBox(width: _ui(context, 12)),
          Expanded(
            child: Text('Video & Voice Calls is a subscriber feature\nChatting is free — but video & voice calls need a subscription (Calor and up).', style: TextStyle(fontSize: _font(context, 12), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _subscriptionFree(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: _ui(context, 12)),
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(
        color: const Color(0xffeafbf2),
        borderRadius: BorderRadius.circular(_ui(context, 14)),
      ),
      child: Text('✅ Always free: chatting, digital wallet, buying tickets & shopping.', style: TextStyle(color: const Color(0xff047857), fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
    );
  }

  Widget _subscriptionPlan(BuildContext context, String title, String subtitle, String price, List<String> features, String button, {bool popular = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: _ui(context, 12)),
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 14)),
        border: Border.all(color: popular ? const Color(0xffff4aa0) : const Color(0xff2f9bef), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(title, style: TextStyle(fontSize: _font(context, 17), fontWeight: FontWeight.w900))), if (popular) Container(padding: EdgeInsets.symmetric(horizontal: _ui(context, 8), vertical: _ui(context, 3)), decoration: BoxDecoration(color: const Color(0xffffe7f1), borderRadius: BorderRadius.circular(99)), child: Text('Popular', style: TextStyle(color: const Color(0xffe94086), fontSize: _font(context, 10), fontWeight: FontWeight.w900)))]),
          Text(subtitle, style: TextStyle(color: const Color(0xff8b99b2), fontSize: _font(context, 12))),
          SizedBox(height: _ui(context, 8)),
          Text(price, style: TextStyle(fontSize: _font(context, 24), fontWeight: FontWeight.w900)),
          SizedBox(height: _ui(context, 8)),
          ...features.map((f) => Padding(padding: EdgeInsets.only(bottom: _ui(context, 4)), child: Text('✔️ $f', style: TextStyle(color: const Color(0xff45536a), fontSize: _font(context, 12), fontWeight: FontWeight.w600)))).toList(),
          SizedBox(height: _ui(context, 10)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: _ui(context, 11)),
            decoration: BoxDecoration(color: const Color(0xff2f9bef), borderRadius: BorderRadius.circular(_ui(context, 10))),
            alignment: Alignment.center,
            child: Text(button, style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showTicketSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.all(_ui(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Share a Ticket', style: TextStyle(fontSize: _font(context, 20), fontWeight: FontWeight.w900))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            Text('Send a QR ticket from your events — they can use it to enter.', style: TextStyle(color: const Color(0xff63718a), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
            SizedBox(height: _ui(context, 12)),
            _ticketRow(context, '🎟️ Wax Moi', 'Wellness and Spa · Nassau · 30/12/2025'),
            _ticketRow(context, '🎟️ Carnival Fete 2026', 'Party/Fete · Nassau · 14/06/2026'),
            _ticketRow(context, '🎟️ Fred\'s Medical Fund Cookout', 'Cookouts/Food · Freeport · 22/06/2026'),
          ],
        ),
      ),
    );
  }

  Widget _ticketRow(BuildContext context, String title, String subtitle) {
    return Container(
      margin: EdgeInsets.only(bottom: _ui(context, 8)),
      padding: EdgeInsets.all(_ui(context, 10)),
      decoration: BoxDecoration(
        color: const Color(0xfff8fbff),
        borderRadius: BorderRadius.circular(_ui(context, 14)),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_2, size: _icon(context, 42), color: Colors.black),
          SizedBox(width: _ui(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
                Text(subtitle, style: TextStyle(color: const Color(0xff63718a), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.send_outlined, color: Color(0xff276bff)),
        ],
      ),
    );
  }

  Widget _buildTogglePill(BuildContext context, String label, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 14), vertical: _ui(context, 6)),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xff2f9bef) : Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 18)),
        border: Border.all(color: const Color(0xff2f9bef).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xff2f9bef),
          fontSize: _font(context, 14),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildAdCard(BuildContext context, HomeAdvertisement ad) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _ui(context, 16),
        vertical: _ui(context, 10),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ad.displayImageUrl.isNotEmpty)
              Image.network(ad.displayImageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(_ui(context, 24)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: _ui(context, 8), vertical: _ui(context, 4)),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                    child: Text('AD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _font(context, 10))),
                  ),
                  SizedBox(height: 8),
                  Text(ad.headline, style: TextStyle(color: Colors.white, fontSize: _font(context, 24), fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text(ad.description, style: TextStyle(color: Colors.white70, fontSize: _font(context, 14))),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {}, // Link to website
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2f9bef), foregroundColor: Colors.white),
                    child: Text(ad.ctaText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoHomeCard(BuildContext context, {bool usersFiltered = false}) {
    return GestureDetector(
      onTap: () => Get.offAll(() => HomePage()),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _ui(context, 16),
          vertical: _ui(context, 10),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xff2f9bef), Color(0xff2487e0)]),
            borderRadius: BorderRadius.circular(_ui(context, 35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(usersFiltered ? Icons.tune : Icons.home_rounded, color: Colors.white, size: _ui(context, 80)),
              SizedBox(height: 20),
              Text(
                usersFiltered ? 'No matches for filters' : 'You\'ve reached the end!',
                style: TextStyle(color: Colors.white, fontSize: _font(context, 22), fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  usersFiltered ? 'Try changing your filters or swipe right to go home' : 'Swipe right or tap here to go back home',
                  style: TextStyle(color: Colors.white70, fontSize: _font(context, 16)),
                  textAlign: TextAlign.center,
                ),
              ),
              if (usersFiltered)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: () => _showFiltersSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xff2f9bef),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Change Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(
      BuildContext context, UserModel user, SwiperPosition position, double progress) {
    return Container(
      // The outer container fills the stack area, making the whole area swipable
      padding: EdgeInsets.symmetric(
        horizontal: _ui(context, 16),
        vertical: _ui(context, 10),
      ),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_ui(context, 35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_ui(context, 35)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: Blurred background image for "cool" depth
              if (user.avatar.isNotEmpty)
                Image.network(
                  user.avatar,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.3),
                  colorBlendMode: BlendMode.darken,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.black54),
                ),
              // Layer 2: Softening overlay
              Container(color: Colors.white.withOpacity(0.05)),
              // Layer 3: Main image with "Overlay" styling
              if (user.avatar.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: _ui(context, 80)),
                  child: Image.network(
                    user.avatar,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 80),
                  ),
                ),
              // Layer 4: Deep vibrant gradient overlay (Gabriela style)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      const Color(0xff8757df).withOpacity(0.4),
                      const Color(0xffef2d74).withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
              // Layer 5: Feedback Stamps (LIKE / NOPE)
              if (position == SwiperPosition.Right && progress > 5)
                Positioned(
                  top: 40,
                  left: 20,
                  child: Transform.rotate(
                    angle: -0.5,
                    child: _stamp(context, 'LIKE', Colors.green, progress),
                  ),
                ),
              if (position == SwiperPosition.Left && progress > 5)
                Positioned(
                  top: 40,
                  right: 20,
                  child: Transform.rotate(
                    angle: 0.5,
                    child: _stamp(context, 'NOPE', Colors.red, progress),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(_ui(context, 26)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_flagFor(user)}  ${user.firstName}, ${user.age ?? 25}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _font(context, 32),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: _ui(context, 10)),
                        Icon(Icons.verified,
                            color: const Color(0xff2f9bef), size: _icon(context, 26)),
                        const Spacer(),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openProfile(user),
                          child: Container(
                            width: _ui(context, 50),
                            height: _ui(context, 50),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.55)),
                            ),
                            child: Icon(Icons.visibility_outlined,
                                color: Colors.white, size: _icon(context, 28)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _ui(context, 10)),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: const Color(0xffff3f67), size: _icon(context, 20)),
                        SizedBox(width: _ui(context, 6)),
                        Text(
                          '${user.distance ?? '1451km'} away · ${_flagFor(user)} ${user.country}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: _font(context, 17),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _ui(context, 4)),
                    Text(
                      'Here to casual chat',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: _font(context, 17),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: _ui(context, 20)),
                  ],
                ),
              ),
              Positioned(
                top: _ui(context, 24),
                right: _ui(context, 24),
                child: _onlineBadge(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stamp(BuildContext context, String text, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity((progress / 100).clamp(0.0, 1.0).toDouble()), width: 4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.withOpacity((progress / 100).clamp(0.0, 1.0).toDouble()),
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _onlineBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 10), vertical: _ui(context, 5)),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(_ui(context, 12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Online',
            style: TextStyle(
              color: Colors.white,
              fontSize: _font(context, 12),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: _ui(context, 6)),
          Container(
            width: _ui(context, 8),
            height: _ui(context, 8),
            decoration: const BoxDecoration(
              color: Color(0xff19b970),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _swipeActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _circleAction(
            context,
            icon: Icons.replay,
            color: const Color(0xff3fa9f5),
            label: 'Backup',
            labelColor: const Color(0xff8e9fb2),
          ),
          _circleAction(
            context,
            icon: Icons.thumb_down_alt_outlined,
            color: const Color(0xffff4d67),
            label: 'NAH',
            labelColor: const Color(0xffff4d67),
            glowColor: const Color(0xffff4d67).withOpacity(0.3),
          ),
          _circleAction(
            context,
            icon: Icons.thumb_up_alt_outlined,
            gradient: const [Color(0xff4ade80), Color(0xff06b6d4)],
            label: 'Yes Sir!',
            labelColor: const Color(0xff2589df),
            iconColor: Colors.white,
            size: 72,
            glowColor: const Color(0xff06b6d4).withOpacity(0.4),
          ),
          _circleAction(
            context,
            icon: Icons.card_giftcard,
            gradient: const [Color(0xfffb923c), Color(0xffef4444)],
            label: 'Send Vibe',
            labelColor: const Color(0xffff3f67),
            iconColor: Colors.white,
            glowColor: const Color(0xffef4444).withOpacity(0.4),
          ),
          _circleAction(
            context,
            icon: Icons.unfold_more,
            color: const Color(0xff22c55e),
            label: 'Link Up',
            labelColor: const Color(0xff22c55e),
            isCustomLogo: true,
          ),
          _circleAction(
            context,
            icon: Icons.star,
            color: const Color(0xfffbbf24),
            label: 'Top Shelf',
            labelColor: const Color(0xfffbbf24),
          ),
        ],
      ),
    );
  }

  Widget _circleAction(
    BuildContext context, {
    required IconData icon,
    Color? color,
    List<Color>? gradient,
    required String label,
    required Color labelColor,
    Color? iconColor,
    bool isCustomLogo = false,
    double size = 58,
    Color? glowColor,
  }) {
    final effectiveColor = color ?? gradient?.last ?? Colors.blue;
    return InkWell(
      borderRadius: BorderRadius.circular(_ui(context, 40)),
      onTap: () => _handleActionButton(label),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: _ui(context, size),
            height: _ui(context, size),
            decoration: BoxDecoration(
              color: gradient == null ? Colors.white : null,
              gradient: gradient != null
                  ? LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor ?? effectiveColor.withOpacity(0.2),
                  blurRadius: size == 72 ? 18 : 12,
                  spreadRadius: size == 72 ? 2 : 0,
                  offset: const Offset(0, 6),
                ),
              ],
              border: gradient == null
                  ? Border.all(color: effectiveColor.withOpacity(0.35), width: 1.8)
                  : null,
            ),
            child: Center(
              child: isCustomLogo
                  ? _customUiLogo(context)
                  : Icon(
                      icon,
                      color: iconColor ?? effectiveColor,
                      size: _icon(context, size * (28 / 58)),
                    ),
            ),
          ),
          SizedBox(height: _ui(context, 10)),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: _font(context, 11),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _customUiLogo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ü',
          style: TextStyle(
            color: const Color(0xff06b6d4),
            fontSize: _font(context, 26),
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            height: 1.0,
          ),
        ),
        Text(
          'i',
          style: TextStyle(
            color: const Color(0xff22c55e),
            fontSize: _font(context, 26),
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  UserModel? _currentSwipeUser() {
    final list = homeController.exploreList;
    if (list.isEmpty) return null;
    return list.last;
  }

  void _handleActionButton(String label) {
    final user = _currentSwipeUser();
    if (label == 'Backup') {
      _swipeKey.currentState?.rewind();
      return;
    }
    if (user == null) return;

    if (label == 'NAH') {
      _pendingSwipeAction = SwipeAction.dislike;
      _swipeKey.currentState?.swipeLeft();
      return;
    }
    if (label == 'Yes Sir!') {
      _pendingSwipeAction = SwipeAction.like;
      _swipeKey.currentState?.swipeRight();
      return;
    }
    if (label == 'Link Up') {
      _pendingSwipeAction = SwipeAction.love;
      _swipeKey.currentState?.swipeRight();
      return;
    }
    if (label == 'Top Shelf') {
      _pendingSwipeAction = SwipeAction.love;
      _showLoveBurst(user, isPriority: true);
      _swipeKey.currentState?.swipeRight();
      return;
    }
    if (label == 'Send Vibe') {
      _showSparkSheet(user);
    }
  }

  bool _shouldShowMatch(UserModel user, SwipeAction action) {
    if (action == SwipeAction.love) return true;

    // If user is in whoLikesMeList, it's definitely a match
    final likedMe = socialController.likesList.any((u) => u.uid == user.uid || (u.laravelId != null && u.laravelId == user.laravelId));
    if (likedMe) return true;

    final source = '${user.laravelId ?? user.uid ?? user.firstName}${_localSwipeSeed++}';
    final hash = source.codeUnits.fold<int>(0, (value, code) => value + code);
    return hash % 3 == 0;
  }

  ImageProvider _avatarProviderFor(UserModel user) {
    if (user.avatar.trim().isNotEmpty) return NetworkImage(user.avatar);
    return const NetworkImage('https://i.pravatar.cc/160?img=20');
  }

  void _showLoveBurst(UserModel user, {bool isPriority = false}) {
    final overlay = Overlay.of(context);
    final name = user.firstName.isNotEmpty ? user.firstName : 'profile';
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _LoveBurstOverlay(
        label: isPriority ? 'LinkUp request sent to $name' : 'You liked $name',
        isPriority: isPriority,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void _showMatchPopup(UserModel user) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Match',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => LinkUpMatchPopup(
        user: user,
        currentUserAvatar: _avatarProvider(),
        onKeepSwiping: () => Get.back(),
        onMessage: () {
          Get.back();
          Navigator.pushNamed(context, RoutePath.user_detail_page, arguments: {'end_user': user});
        },
        onSendSpark: () {
          Get.back();
          Future.delayed(const Duration(milliseconds: 80), () => _showSparkSheet(user));
        },
      ),
    );
  }

  void _showSparkSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LinkUpSparkSheet(
        user: user,
        coins: homeController.coins,
        onSend: (label, emoji, cost) async {
          await homeController.sendVibeGift(
            user,
            giftName: label,
            cost: cost,
          );
          if (!mounted) return;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
              content: Text('$emoji Vibe sent — $label'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, UserModel user) {
    return GestureDetector(
      onTap: () => _openProfile(user),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_ui(context, 15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_ui(context, 15)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (user.avatar.isNotEmpty)
                Image.network(
                  user.avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade400),
                )
              else
                Container(color: Colors.grey.shade300),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              Positioned(
                top: _ui(context, 8),
                right: _ui(context, 8),
                child: GestureDetector(
                  onTap: () => _openProfile(user),
                  child: Container(
                    width: _ui(context, 34),
                    height: _ui(context, 34),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.42),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.visibility_outlined,
                      color: Colors.white,
                      size: _icon(context, 19),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_ui(context, 10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${user.firstName}, ${user.age ?? 25}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _font(context, 18),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${_flagFor(user)}  ${user.distance ?? '858km'} away · ${user.country}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: _font(context, 11),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Here to party',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: _font(context, 11),
                      ),
                    ),
                    SizedBox(height: _ui(context, 8)),
                    Row(
                      children: [
                        _circleActionSmall(
                          context,
                          Icons.visibility_outlined,
                          const Color(0xff2f9bef),
                          onTap: () => _openProfile(user),
                        ),
                        const Spacer(),
                        _circleActionSmall(
                          context,
                          Icons.close,
                          const Color(0xffff3f67),
                          onTap: () => _actOnMatchCard(user, SwipeAction.dislike),
                        ),
                        const Spacer(),
                        _circleActionSmall(
                          context,
                          Icons.favorite,
                          const Color(0xff19b970),
                          onTap: () => _actOnMatchCard(user, SwipeAction.like),
                        ),
                        const Spacer(),
                        _circleActionSmall(
                          context,
                          Icons.star,
                          const Color(0xfff2aa00),
                          onTap: () => _actOnMatchCard(user, SwipeAction.love),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: _ui(context, 8),
                right: _ui(context, 8),
                child: Container(
                  width: _ui(context, 18),
                  height: _ui(context, 18),
                  decoration: const BoxDecoration(
                      color: Color(0xff19b970), shape: BoxShape.circle),
                  child: Icon(Icons.circle, color: Colors.black26, size: _icon(context, 8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleActionSmall(
    BuildContext context,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: _ui(context, 26),
        height: _ui(context, 26),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Icon(icon, color: color, size: _icon(context, 14)),
      ),
    );
  }

  Future<void> _actOnMatchCard(UserModel user, SwipeAction action) async {
    await homeController.recordSwipe(user, action);
    homeController.findMatchCards.removeWhere((u) =>
        (u.uid != null && u.uid == user.uid) ||
        (u.laravelId != null && u.laravelId == user.laravelId));
    socialController.likesList.removeWhere((u) =>
        (u.uid != null && u.uid == user.uid) ||
        (u.laravelId != null && u.laravelId == user.laravelId));
    homeController.exploreList.removeWhere((u) =>
        (u.uid != null && u.uid == user.uid) ||
        (u.laravelId != null && u.laravelId == user.laravelId));

    socialController.fetchLikes();
    socialController.fetchMatches();

    if (!mounted) return;

    if (action == SwipeAction.like || action == SwipeAction.love) {
      _showLoveBurst(user, isPriority: action == SwipeAction.love);
      if (_shouldShowMatch(user, action)) {
        Future.delayed(const Duration(milliseconds: 220), () {
          if (mounted) _showMatchPopup(user);
        });
      }
    }
  }

  Widget _buildMatchListItem(BuildContext context, UserModel user, {String action = 'Message'}) {
    final country = _countryText(user);
    return Container(
      margin: EdgeInsets.only(bottom: _ui(context, 10)),
      padding: EdgeInsets.symmetric(
        horizontal: _ui(context, 12),
        vertical: _ui(context, 10),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: _ui(context, 25),
                backgroundColor: const Color(0xffeef3f8),
                backgroundImage:
                    user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
                child: user.avatar.isEmpty
                    ? Text(
                        user.firstName.isNotEmpty
                            ? user.firstName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: _font(context, 18),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xff4f46e5),
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -_ui(context, 1),
                bottom: _ui(context, 1),
                child: Container(
                  width: _ui(context, 10),
                  height: _ui(context, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xff31d077),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: _ui(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_flagFor(user)} ${_safeName(user)}, ${user.age ?? 25}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xff10182b),
                    fontSize: _font(context, 16),
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: _ui(context, 4)),
                Text(
                  country,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xff617087),
                    fontSize: _font(context, 12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6),
          IconButton(
            onPressed: () => _openProfile(user),
            icon: Icon(
              Icons.visibility_outlined,
              color: const Color(0xff2f9bef),
              size: _icon(context, 24),
            ),
          ),
          SizedBox(width: 6),
          TextButton(
            onPressed: () {
              if (action == 'Accept') {
                // Handle accept if needed here, though it's usually in buildRequestListItem
              } else if (action == 'Like Back') {
                _actOnMatchCard(user, SwipeAction.like);
              } else {
                _openChatForUser(user);
              }
            },
            style: TextButton.styleFrom(
              minimumSize: Size(_ui(context, 70), _ui(context, 34)),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
              backgroundColor: (action == 'Message' || action == 'Like Back')
                  ? const Color(0xff2f9bef)
                  : const Color(0xfff1f5f9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_ui(context, 18)),
              ),
            ),
            child: Text(
              action,
              style: TextStyle(
                color: (action == 'Message' || action == 'Like Back') ? Colors.white : const Color(0xff10182b),
                fontWeight: FontWeight.w900,
                fontSize: _font(context, 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _safeName(UserModel user) {
    final name = user.firstName.trim();
    return name.isEmpty ? 'LinkUp' : name;
  }

  String _countryText(UserModel user) {
    final flag = _flagFor(user);
    final country = user.country.trim();
    if (country.isEmpty) return flag;
    return flag.isEmpty ? country : '$flag $country';
  }

  void _openWebProfile(BuildContext context, UserModel user) {
    _openProfile(user);
  }

  Widget _buildRequestListItem(BuildContext context, FriendRequestModel request) {
    final user = request.otherUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: _ui(context, 16)),
      padding: EdgeInsets.all(_ui(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: _ui(context, 32),
            backgroundImage:
                user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
          ),
          SizedBox(width: _ui(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_flagFor(user)} ${user.firstName}, ${user.age ?? 25}',
                  style: TextStyle(
                    color: const Color(0xff142035),
                    fontSize: _font(context, 19),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: _ui(context, 2)),
                Row(
                  children: [
                    Text(_flagFor(user), style: TextStyle(fontSize: _ui(context, 14))),
                    SizedBox(width: 4),
                    Text(
                      user.country,
                      style: TextStyle(
                        color: const Color(0xff8b99b2),
                        fontSize: _font(context, 14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openProfile(user),
            icon: Icon(
              Icons.visibility_outlined,
              color: const Color(0xff2f9bef),
              size: _icon(context, 26),
            ),
          ),
          SizedBox(width: 4),
          if (_showReceivedRequests) ...[
            ElevatedButton(
              onPressed: () => socialController.acceptRequest(request.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2f9bef),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_ui(context, 18)),
                ),
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
              ),
              child: Text('Accept',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: _font(context, 12),
                      fontWeight: FontWeight.w900)),
            ),
            SizedBox(width: _ui(context, 6)),
            TextButton(
              onPressed: () => socialController.rejectRequest(request.id),
              child: Text('Decline',
                  style: TextStyle(
                      color: const Color(0xff142035),
                      fontWeight: FontWeight.w900,
                      fontSize: _font(context, 12))),
            ),
          ] else
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: _ui(context, 14), vertical: _ui(context, 8)),
              decoration: BoxDecoration(
                color: const Color(0xfff1f5f9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text('Pending',
                  style: TextStyle(
                      color: const Color(0xff64748b),
                      fontSize: _font(context, 12),
                      fontWeight: FontWeight.w900)),
            ),
        ],
      ),
    );
  }

  Widget _chatAvatarSimple(BuildContext context, String url, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xfff1f5f9),
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      onBackgroundImageError: url.isNotEmpty ? (e, s) => {} : null,
      child: url.isEmpty
          ? Icon(Icons.person, color: const Color(0xff94a3b8), size: radius * 1.2)
          : null,
    );
  }

  Widget _buildChatListItem(BuildContext context, RecentChatModel chat) {
    final unread = chat.isUnread;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeChatName = chat.withName.isNotEmpty ? chat.withName : 'Chat';
          _activeChatAvatar = chat.withAvatar;
          _activeChatId = chat.withId;
          _activeLaravelId = chat.chatId;
          _activeApiName = chat.apiName;
          _chatThreadOpen = true;
        });
        chatController.getChatHistory(chat.apiName, chat.withId);
      },
      child: Container(
      margin: EdgeInsets.only(bottom: _ui(context, 10)),
      padding: EdgeInsets.all(_ui(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _chatAvatarSimple(context, chat.withAvatar, _ui(context, 28)),
          SizedBox(width: _ui(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.withName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xff142035),
                          fontSize: _font(context, 18),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (chat.pinned)
                      Padding(
                        padding: EdgeInsets.only(left: _ui(context, 4)),
                        child: Icon(Icons.push_pin, size: _icon(context, 14), color: const Color(0xff8b99b2)),
                      ),
                  ],
                ),
                SizedBox(height: _ui(context, 2)),
                Text(
                  chat.lastText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unread ? const Color(0xff142035) : const Color(0xff8b99b2),
                    fontSize: _font(context, 13),
                    fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: _ui(context, 8)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chat.timestamp > 0 ? authController.timeStampToDateTime(chat.timestamp) : '',
                style: TextStyle(
                  color: unread ? const Color(0xff2f9bef) : const Color(0xff8b99b2),
                  fontSize: _font(context, 12),
                  fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              if (unread) ...[
                SizedBox(height: _ui(context, 6)),
                Container(
                  width: _ui(context, 8),
                  height: _ui(context, 8),
                  decoration: const BoxDecoration(color: Color(0xff2f9bef), shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, IconData icon, Color color) {
    return Container(
      width: _ui(context, 56),
      height: _ui(context, 56),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: _icon(context, 28)),
    );
  }

  Widget _buildSmallActionButton(
      BuildContext context, IconData icon, Color color) {
    return Container(
      width: _ui(context, 32),
      height: _ui(context, 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: _icon(context, 16)),
    );
  }

  ImageProvider _avatarProvider() => LinkUpCurrentUser.avatarProvider();

  Widget _bottomBar(BuildContext context) {
    final items = [
      [Icons.home_outlined, 'Home', false],
      [Icons.image_outlined, 'Vibes', false],
      [Icons.restaurant_outlined, 'Eats', false],
      [Icons.sensors, 'Live', false],
      [Icons.favorite_border, 'LinkUp', true],
    ];

    return Container(
      height: _ui(context, 64) + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        left: _ui(context, 12),
        right: _ui(context, 12),
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final selected = item[2] as bool;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(_ui(context, 18)),
              onTap: () {
                if (item[1] == 'Home') Get.offAll(() => HomePage());
                if (item[1] == 'Vibes') Get.to(() => const VibesPage());
                if (item[1] == 'Eats') Get.to(OnboardingScreenSix());
                if (item[1] == 'Live' &&
                    authController.user?.value.isClub != true) {
                  authController.alert1('please_subscribe'.tr);
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: selected ? _ui(context, 30) : _ui(context, 26),
                    height: selected ? _ui(context, 30) : _ui(context, 26),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xff2d98e5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(_ui(context, 11)),
                    ),
                    child: Icon(
                      item[0] as IconData,
                      color: selected ? Colors.white : const Color(0xff69768a),
                      size: _icon(context, 24),
                    ),
                  ),
                  SizedBox(height: _ui(context, 3)),
                  Text(
                    item[1] as String,
                    maxLines: 1,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xff2589df)
                          : const Color(0xff627085),
                      fontSize: _font(context, 12),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


class _LoveBurstOverlay extends StatefulWidget {
  final String label;
  final bool isPriority;
  final VoidCallback onDone;

  const _LoveBurstOverlay({
    required this.label,
    required this.isPriority,
    required this.onDone,
  });

  @override
  State<_LoveBurstOverlay> createState() => _LoveBurstOverlayState();
}

class _LoveBurstOverlayState extends State<_LoveBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 52),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);
    _scale = Tween<double>(begin: 0.78, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.18), end: const Offset(0, -0.10))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 10; i++)
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  final t = _controller.value;
                  final angle = (i * 36.0) * math.pi / 180;
                  final radius = 20 + (92 * t);
                  return Transform.translate(
                    offset: Offset(
                      radius * math.cos(angle),
                      radius * math.sin(angle) - 40 * t,
                    ),
                    child: Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0).toDouble(),
                      child: Text(
                        i.isEven ? '💙' : '💚',
                        style: TextStyle(fontSize: 18 + (10 * t)),
                      ),
                    ),
                  );
                },
              ),
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: widget.isPriority
                            ? const [Color(0xfff59e0b), Color(0xffec4899)]
                            : const [Color(0xff2f9bef), Color(0xff06b6d4)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isPriority ? const Color(0xffec4899) : const Color(0xff2f9bef)).withOpacity(0.35),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isPriority ? Icons.favorite : Icons.thumb_up_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
