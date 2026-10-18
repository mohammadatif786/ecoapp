// ignore_for_file: must_be_immutable

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:link_up/widgets/linkup_location_sheet.dart';
import '../widgets/linkup_current_user.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
// import 'package:link_up/events/CurrentLocation.dart';
import 'package:link_up/get_controller/ChatController.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/get_controller/home_controller.dart';
import 'package:link_up/helper/app_config.dart';
import 'package:link_up/helper/app_constant.dart';
import 'package:link_up/helper/drawer_manager.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/introscreens/screensix.dart';
import 'package:link_up/introscreens/screensone.dart';
import 'package:link_up/model/home_advertisement.dart';
import 'package:link_up/model/user_model.dart';
import 'package:link_up/package/swipe_card_stack.dart';
import 'package:link_up/ui/widgets/home_ad_card.dart';
import 'package:link_up/ui/widgets/vibes_reference_ui.dart';
import 'package:link_up/ui/DrawerScreen.dart';
import 'package:link_up/helper/app_config.dart' as config;
// import 'package:link_up/ui/chat/calling/incomingCall.dart';
import 'package:link_up/ui/notification_page.dart';
import 'package:link_up/ui/profile/profile_page.dart';
import 'package:link_up/services/linkup_api_service.dart';
import 'package:link_up/ui/why_we_are_here.dart';
import 'package:url_launcher/url_launcher.dart';

import '../events/splash_events.dart';
// import '../livestreaming/live_streams.dart';
import 'chat_home_page.dart';
import 'chat/chat_message_new.dart';
import 'package:link_up/ui/events/event_detail_screen.dart';
import 'package:link_up/get_controller/events_controller.dart';
import 'package:link_up/model/linkup_event.dart';
import 'package:link_up/ui/vibes_page.dart';
import 'package:link_up/ui/u_vibe_page.dart';
import 'package:link_up/ui/eats_page.dart';
import 'package:link_up/ui/live_page.dart';
import 'package:link_up/ui/wallet_page.dart';
import 'package:link_up/ui/news_page.dart';
import 'package:link_up/theme/linkup_text_styles.dart';
import 'package:link_up/events/AllEvents.dart';
import 'package:link_up/ui/market_page.dart';
import 'package:link_up/ui/map/place_list_page.dart';
import 'package:link_up/ui/nightlife_page.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  String? whyare;
  final String? gender;
  final String? age;
  String? distance;
  final bool isGuest;

  HomePage({this.whyare, this.gender, this.distance, this.age, this.isGuest = false});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late String? why = widget.whyare;
  AuthController authController = Get.find(tag: AuthController().toString());
  HomeController homeController = Get.find(tag: HomeController().toString());
  ChatController chatController = Get.find(tag: ChatController().toString());
  AppLifecycleState appLifecycleState = AppLifecycleState.resumed;

  AppLifecycleState get getAppLifecycleState => appLifecycleState;

  String? selectedUserID, _selectAbuse;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callsSubscription;
  final GlobalKey<SwipeCardStackState> _swipeKey =
      GlobalKey<SwipeCardStackState>();
  final ScrollController _shortcutScrollController = ScrollController();
  double _shortcutScrollOffset = 0;
  double _shortcutMaxScroll = 0;
  double _shortcutViewportExtent = 0;

  Location location = Location.Men;
  String actLocation = 'Men';
  String _homeCity = 'The Valley';
  String _homeCountry = 'Anguilla';
  String _homeFlag = 'assets/ai.png';

  Location1 location1 = Location1.twenty2;
  String actLocation1 = '22-27';

  Location2 location2 = Location2.hundred1;
  String actLocation2 = '100';

  Location3 location3 = Location3.all;
  String actLocation3 = 'all';

  var title = "Enter Your Address";
  var isLoading = false;
  FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> checkToken(BuildContext context) async {
    if (widget.isGuest) return;
    
    final apiToken = await LinkupApiService.getToken();
    if (apiToken == null || apiToken.isEmpty) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, RoutePath.login_screen);
      return;
    }

    try {
      if (!authController.hasValidApiUser()) {
        await authController.getUserFromApi(context);
      } else {
        await authController.ensureApiUserIdentity();
      }
    } catch (_) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, RoutePath.login_screen);
      return;
    }

    if (!context.mounted) return;
    if (!authController.hasValidApiUser()) {
      Navigator.pushReplacementNamed(context, RoutePath.login_screen);
    }
  }

  void _listenForIncomingCalls() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _callsSubscription?.cancel();
    _callsSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(uid)
        .snapshots()
        .listen((e) {
      if (getAppLifecycleState != AppLifecycleState.resumed) return;
      if (e.data() == null) return;

      final jsonObject = e.data()!;
      if (jsonObject['receiver'] == uid &&
          jsonObject['response'] == 'Awaiting') {
        // Incoming call handling can be wired here.
      }
    });
  }

  selectAbuse(BuildContext context, UserModel toUser) async {
    final apiToken = await LinkupApiService.getToken();
    final reportedId =
        toUser.laravelId ?? int.tryParse(toUser.uid ?? '');
    if (apiToken != null &&
        apiToken.isNotEmpty &&
        reportedId != null &&
        _selectAbuse != null) {
      try {
        await LinkupApiService.reportUser(
          reportedUserId: reportedId,
          message: _selectAbuse!,
          reason: _selectAbuse!,
          selectedReason: [_selectAbuse!],
        );
        if (context.mounted) {
          authController.alert1('Report submitted. Thank you.');
        }
        return;
      } catch (e) {
        debugPrint('reportUser API failed: $e');
      }
    }

    final currentUid = authController.user?.value.uid;
    if (currentUid == null || currentUid.isEmpty) return;

    await db.collection('flaggedUsers').doc().set({
      'fromId': currentUid,
      'fromFirstName': authController.user!.value.firstName,
      'fromLastName': authController.user!.value.lastName,
      'toId': toUser.uid,
      'toFirstName': toUser.firstName,
      'toLastName': toUser.lastName,
      'message': _selectAbuse,
      'timestamp': Timestamp.now().millisecondsSinceEpoch,
    });
  }

  _selectAbuseDialog(
      BuildContext context, UserModel data, height, width, padding) async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState2) {
            return AlertDialog(
              title: Text(
                'choose_cat'.tr,
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 360,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: config.App(context, height, width,
                          padding.vertical, padding.horizontal)
                      .abuseList
                      .length,
                  itemBuilder: (BuildContext context, int index) {
                    final label = config
                        .App(context, height, width, padding.vertical,
                            padding.horizontal)
                        .abuseList[index];
                    return RadioListTile<String>(
                      dense: false,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      title: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      value: label,
                      groupValue: _selectAbuse,
                      onChanged: (value) {
                        setState2(() {
                          _selectAbuse = value;
                        });
                      },
                    );
                  },
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: Text('yes'.tr),
                  onPressed: () async {
                    await selectAbuse(context, data);
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('no'.tr),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
        });
  }

  void gotoPlaceListPage(String title) {
    Navigator.pushNamed(context, RoutePath.place_list_screen,
        arguments: {'title': title});
  }

  void superLike(String friendId) {
    print("Love It");
  }

  void topShelf() {
    authController.alert1('Your profile set as top shelf to this user');
  }

  void _getCurrentUserLocation() async {
    await Geolocator.checkPermission().then((value) {
      if (value == LocationPermission.denied ||
          value == LocationPermission.deniedForever) {
        Geolocator.requestPermission();
      }
    });

    LocationSettings locationSettings =
        LocationSettings(accuracy: LocationAccuracy.best);
    await GeolocatorPlatform.instance
        .getCurrentPosition(locationSettings: locationSettings)
        .then((Position position) async {
      DrawerManager.shared.latitude = position.latitude.toString();
      DrawerManager.shared.longitude = position.longitude.toString();
      if (mounted) setState(() {});
      try {
        await LinkupApiService.updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        if (mounted) fetchProfiles();
      } catch (e) {
        debugPrint('Location sync failed: $e');
      }
    }).catchError((e) {
      print(e);
    });
  }

  void fetchProfiles() async {
    if (authController.user != null) {
      await homeController.fetchExploreList(
          linkMeWith: authController.user!.value.linkMeWith,
          nationality: authController.user!.value.countryCode.toString(),
          userID: authController.user!.value.uid!);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    setState(() {
      appLifecycleState = state;
    });
    print(appLifecycleState);
  }

  void _syncHomeLocationFromGlobal() {
    final location = LinkupLocationService.selected.value;
    if (!mounted) return;
    if (_homeCity == location.city && _homeCountry == location.country && _homeFlag == location.flag) return;
    setState(() {
      _homeCity = location.city;
      _homeCountry = location.country;
      _homeFlag = location.flag;
    });
  }

  @override
  void initState() {
    print('WElcome Home');
    WidgetsBinding.instance.addObserver(this);
    LinkupLocationService.selected.addListener(_syncHomeLocationFromGlobal);
    checkToken(context).then((_) {
      if (!mounted || !authController.hasValidApiUser()) return;
      fetchProfiles();
      homeController.missedMessage();
    });
    _getCurrentUserLocation();
    super.initState();
  }

  @override
  void dispose() {
    _callsSubscription?.cancel();
    _shortcutScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    LinkupLocationService.selected.removeListener(_syncHomeLocationFromGlobal);
    homeController.timer?.value.cancel();
    super.dispose();
  }

  String? replaceagerange;
  String? agerange;
  String? result;
  String? replacedistancerange;
  String? distancerange;
  String? result2;

  @override
  Widget build(BuildContext context) {
    return _buildReferenceHome(context);
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

  ImageProvider _avatarProvider() => LinkUpCurrentUser.avatarProvider();

  String get _firstName => LinkUpCurrentUser.firstName();

  Widget _buildReferenceHome(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return GetBuilder(
      init: authController,
      builder: (_) {
        return GetBuilder(
          init: homeController,
          builder: (_) {
            return WillPopScope(
              onWillPop: () async => false,
              child: Scaffold(
                backgroundColor: const Color(0xffeaf4fc),
                body: Column(
                  children: [
                    _topChrome(context, topPadding),
                    _locationStrip(context),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: _ui(context, 12)),
                            _greetingBand(context),
                            SizedBox(height: _ui(context, 14)),
                            _breakingPill(context),
                            SizedBox(height: _ui(context, 14)),
                            _walletCard(context),
                            SizedBox(height: _ui(context, 16)),
                            _askAiCard(context),
                            SizedBox(height: _ui(context, 18)),
                            _shortcutRail(context),
                            SizedBox(height: _ui(context, 22)),
                            _sectionHeader(
                              context,
                              title: 'Featured',
                              action: 'Swipe',
                              icon: Icons.arrow_forward,
                            ),
                            SizedBox(height: _ui(context, 10)),
                            _featuredRail(context),
                            SizedBox(height: _ui(context, 20)),
                            _sectionHeader(
                              context,
                              title: 'Vibes',
                              action: 'See all',
                              icon: Icons.arrow_forward,
                              actionColor: const Color(0xff2589df),
                              onTap: () => _openHomeDestination('Vibes'),
                            ),
                            SizedBox(height: _ui(context, 10)),
                            _vibesRail(context),
                            SizedBox(height: _ui(context, 22)),
                            _liveNowSection(context),
                            SizedBox(height: _ui(context, 22)),
                            _earnCoinsSection(context),
                            SizedBox(height: _ui(context, 22)),
                            _nearYouSection(context),
                            SizedBox(height: _ui(context, 22)),
                            _happeningNowSection(context),
                            SizedBox(height: _ui(context, 18)),
                          ],
                        ),
                      ),
                    ),
                    _bottomBar(context),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _topChrome(BuildContext context, double topPadding) {
    return Container(
      height: topPadding + _ui(context, 60),
      padding: EdgeInsets.only(
        top: topPadding + _ui(context, 8),
        left: _ui(context, 20),
        right: _ui(context, 18),
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
          Image.asset(
            'assets/Vector Smart Object 2.png',
            height: _ui(context, 34),
            width: _ui(context, 112),
            fit: BoxFit.contain,
          ),
          const Spacer(),
          _coinPill(context),
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
              radius: _ui(context, 24),
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: _ui(context, 21),
                backgroundImage: _avatarProvider(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coinPill(BuildContext context) {
    return GestureDetector(
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
    );
  }

  Widget _locationStrip(BuildContext context) {
    return LinkupLocationBar(
      height: _ui(context, 32),
      horizontalPadding: _ui(context, 18),
      iconSize: _icon(context, 24),
      fontSize: _font(context, 15),
      changeFontSize: _font(context, 14),
      textColor: const Color(0xff45536a),
      changeColor: const Color(0xff2589df),
      iconColor: const Color(0xff3198df),
    );
  }

  Widget _greetingBand(BuildContext context) {
    return Container(
      height: _ui(context, 92),
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 20)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff0b2942), Color(0xff2f9bef), Color(0xff7c3aed)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: _ui(context, 24),
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: _ui(context, 21),
              backgroundImage: _avatarProvider(),
            ),
          ),
          SizedBox(width: _ui(context, 18)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good evening',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: _font(context, 17),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _font(context, 30),
                    fontWeight: FontWeight.w900,
                    height: 1.06,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showWeatherSheet(context),
            child: _softPill(context, '28°C', _ui(context, 64), icon: Icons.cloud_outlined),
          ),
          SizedBox(width: _ui(context, 10)),
          GestureDetector(
            onTap: () => _showLocationPicker(context),
            child: _softPill(context, _homeCity, _ui(context, 100), icon: Icons.location_on_outlined),
          ),
        ],
      ),
    );
  }

  Widget _softPill(BuildContext context, String label, double width, {IconData? icon}) {
    return Container(
      width: width,
      height: _ui(context, 34),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 8)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(_ui(context, 22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: _icon(context, 16)),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: _font(context, 14),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakingPill(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.to(() => const NewsPage()),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
        height: _ui(context, 38),
        padding: EdgeInsets.only(left: _ui(context, 6), right: _ui(context, 10)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: _ui(context, 27),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xffff3f67),
                borderRadius: BorderRadius.circular(_ui(context, 18)),
              ),
              child: Text(
                '• BREAKING',
                style: LinkUpTextStyles.openSansStyle(
                  color: Colors.white,
                  fontSize: _font(context, 12),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(width: _ui(context, 10)),
            Expanded(
              child: ClipRect(
                child: _HomeNewsTicker(
                  text: 'Global Energy Crisis  •  Bahamas Tourism Booms  •  Carnival Tickets Selling Fast  •  Jamaica Music Festival This Weekend  •  Anguilla beach events tonight  •  ',
                  style: TextStyle(color: const Color(0xff142035), fontSize: _font(context, 15), fontWeight: FontWeight.w900),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: const Color(0xff94a3b8), size: _icon(context, 20)),
          ],
        ),
      ),
    );
  }

  Widget _walletCard(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.to(() => const WalletPage()),
      child: Container(
        height: _ui(context, 64),
        margin: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 18)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 25)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            _moneyBlock(context, icon: Icons.account_balance_wallet_outlined, color: const Color(0xff08a9c7), label: 'Wallet', value: '\$${homeController.walletAmount}'),
            Container(width: 1, height: _ui(context, 36), color: const Color(0xffe8eef7), margin: EdgeInsets.symmetric(horizontal: _ui(context, 14))),
            _moneyBlock(context, icon: Icons.diamond_outlined, color: const Color(0xfff2aa00), label: 'Coins', value: '${homeController.coins}'),
          ],
        ),
      ),
    );
  }

  Widget _moneyBlock(BuildContext context,
      {required IconData icon,
      required Color color,
      required String label,
      required String value}) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: _ui(context, 39),
            height: _ui(context, 39),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(_ui(context, 12)),
            ),
            child: Icon(icon, color: Colors.white, size: _icon(context, 25)),
          ),
          SizedBox(width: _ui(context, 10)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      color: const Color(0xff8b99b2),
                      fontSize: _font(context, 14),
                      fontWeight: FontWeight.w800,
                    )),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xff121a2d),
                      fontSize: _font(context, 21),
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _openHomeDestination(String destination, [BuildContext? context]) {
    switch (destination) {
      case 'Wallet':
        Get.to(() => const WalletPage());
        break;
      case 'Events':
        Get.to(() => AllEvents(country: _homeCountry));
        break;
      case 'Vibes':
        Get.to(() => const VibesPage());
        break;
      case 'U Vibe':
        Get.to(() => const UVibePage());
        break;
      case 'Eats':
        Get.to(() => const EatsPage());
        break;
      case 'Live':
        Get.to(() => const LivePage());
        break;
      case 'Nightlife':
        Get.to(() => const NightlifePage());
        break;
      case 'Market':
      case 'Marketplace':
        Get.to(() => const MarketPage());
        break;
      case '360 News':
      case 'News':
        Get.to(() => const NewsPage());
        break;
      case 'LinkUp':
      case 'Matches':
        Get.to(ChatHomePage());
        break;
      default:
        break;
    }
  }

  Widget _askAiCard(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showLinkUpAiPopup(context),
      child: Container(
        height: _ui(context, 78),
        margin: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 15)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff7c3aed), Color(0xff2f9bef), Color(0xff06b6d4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(_ui(context, 22)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff2f9bef).withOpacity(0.28),
              blurRadius: 11,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: _ui(context, 42),
              height: _ui(context, 42),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(_ui(context, 14)),
              ),
              child: Icon(Icons.auto_awesome, color: Colors.white, size: _icon(context, 28)),
            ),
            SizedBox(width: _ui(context, 13)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask AI · What do you want to do?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LinkUpTextStyles.openSansStyle(
                      color: Colors.white,
                      fontSize: _font(context, 21),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Find tickets, food, products, people — just ask.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LinkUpTextStyles.openSansStyle(
                      color: Colors.white,
                      fontSize: _font(context, 15),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.white, size: _icon(context, 30)),
          ],
        ),
      ),
    );
  }

  void _syncShortcutRailMetrics(ScrollMetrics metrics) {
    if (metrics.axis != Axis.horizontal) return;

    final maxScroll = math.max(0.0, metrics.maxScrollExtent);
    final offset = metrics.pixels.clamp(0.0, maxScroll).toDouble();
    final viewport = math.max(0.0, metrics.viewportDimension);

    if ((_shortcutScrollOffset - offset).abs() < 0.25 &&
        (_shortcutMaxScroll - maxScroll).abs() < 0.25 &&
        (_shortcutViewportExtent - viewport).abs() < 0.25) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _shortcutScrollOffset = offset;
      _shortcutMaxScroll = maxScroll;
      _shortcutViewportExtent = viewport;
    });
  }

  Widget _shortcutRail(BuildContext context) {
    final items = <Map<String, Object>>[
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Wallet',
        'colors': const [Color(0xff00b7d8), Color(0xff0785ef)],
      },
      {
        'icon': Icons.confirmation_number_outlined,
        'label': 'Events',
        'colors': const [Color(0xffff8a00), Color(0xffff3f5f)],
      },
      {
        'icon': Icons.image_outlined,
        'label': 'Vibes',
        'colors': const [Color(0xfff02fb8), Color(0xff8a2be2)],
      },
      {
        'icon': Icons.school_outlined,
        'label': 'U Vibe',
        'colors': const [Color(0xff7b2ff7), Color(0xffc529d9)],
      },
      {
        'icon': Icons.restaurant_outlined,
        'label': 'Eats',
        'colors': const [Color(0xff34d11f), Color(0xff12a70e)],
      },
      {
        'icon': Icons.sensors,
        'label': 'Live',
        'colors': const [Color(0xffff8a00), Color(0xffff2d55)],
      },
      {
        'icon': Icons.favorite_border,
        'label': 'LinkUp',
        'colors': const [Color(0xffff2f7d), Color(0xffec0b55)],
      },
      {
        'icon': Icons.mic_none_outlined,
        'label': 'Nightlife',
        'colors': const [Color(0xff7c3aed), Color(0xffff2f92)],
      },
      {
        'icon': Icons.article_outlined,
        'label': '360 News',
        'colors': const [Color(0xff21b7ff), Color(0xff1677ff)],
      },
      {
        'icon': Icons.shopping_bag_outlined,
        'label': 'Market',
        'colors': const [Color(0xffff9f0a), Color(0xffff2f92)],
      },
    ];

    return SizedBox(
      height: _ui(context, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _ui(context, 88),
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (notification) {
                _syncShortcutRailMetrics(notification.metrics);
                return false;
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  _syncShortcutRailMetrics(notification.metrics);
                  return false;
                },
                child: ListView.separated(
                  controller: _shortcutScrollController,
                  padding: EdgeInsets.symmetric(horizontal: _ui(context, 20)),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => SizedBox(width: _ui(context, 14)),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final label = item['label'] as String;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openHomeDestination(label, context),
                      child: SizedBox(
                        width: _ui(context, 72),
                        child: Column(
                          children: [
                            _homeShortcutIcon(
                              context,
                              icon: item['icon'] as IconData,
                              colors: item['colors'] as List<Color>,
                            ),
                            SizedBox(height: _ui(context, 8)),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xff4d5b73),
                                fontSize: _font(context, 12),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeShortcutIcon(
    BuildContext context, {
    required IconData icon,
    required List<Color> colors,
  }) {
    final glow = colors.last;
    return Container(
      width: _ui(context, 58),
      height: _ui(context, 58),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withOpacity(0.26),
            blurRadius: _ui(context, 13),
            offset: Offset(0, _ui(context, 7)),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: _ui(context, 8),
            top: _ui(context, 7),
            child: Container(
              width: _ui(context, 18),
              height: _ui(context, 18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
              ),
            ),
          ),
          Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: _icon(context, 27),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dynamicRailIndicator(
    BuildContext context, {
    required ScrollController controller,
    required int itemCount,
    required double itemWidth,
    required double gapWidth,
    required double horizontalPadding,
    double maxTrackWidth = 220,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final trackWidth = math.min(
      screenWidth - _ui(context, 32),
      _ui(context, maxTrackWidth),
    );

    final fallbackViewport = screenWidth - (_ui(context, horizontalPadding) * 2);
    final fallbackContentWidth =
        (itemCount * _ui(context, itemWidth)) +
        ((itemCount - 1) * _ui(context, gapWidth)) +
        (_ui(context, horizontalPadding) * 2);

    final viewport = _shortcutViewportExtent > 0
        ? _shortcutViewportExtent
        : math.max(0.0, fallbackViewport);
    final maxScroll = _shortcutMaxScroll > 0
        ? _shortcutMaxScroll
        : math.max(0.0, fallbackContentWidth - screenWidth);
    final offset = _shortcutScrollOffset.clamp(0.0, maxScroll).toDouble();

    final contentWidth = math.max(viewport, viewport + maxScroll);
    final visibleRatio = contentWidth <= 0
        ? 1.0
        : (viewport / contentWidth).clamp(0.0, 1.0).toDouble();
    final minThumb = _ui(context, 46);
    final thumbWidth = (maxScroll <= 0 ? trackWidth : trackWidth * visibleRatio)
        .clamp(minThumb, trackWidth)
        .toDouble();
    final progress = maxScroll <= 0
        ? 0.0
        : (offset / maxScroll).clamp(0.0, 1.0).toDouble();
    final left = ((trackWidth - thumbWidth) * progress).toDouble();

    const barColor = Color(0xffa8c9e6);

    return Container(
      width: trackWidth,
      height: _ui(context, 5),
      decoration: BoxDecoration(
        color: barColor.withOpacity(0.35),
        borderRadius: BorderRadius.circular(_ui(context, 99)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: 0,
            bottom: 0,
            child: Container(
              width: thumbWidth,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(_ui(context, 99)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _railIndicator(BuildContext context, {double width = 190}) {
    return Container(
      width: _ui(context, width),
      height: _ui(context, 5),
      decoration: BoxDecoration(
        color: const Color(0xffa8c9e6),
        borderRadius: BorderRadius.circular(_ui(context, 99)),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required String action,
    required IconData icon,
    Color actionColor = const Color(0xff99a6ba),
    VoidCallback? onTap,
  }) {
    final actionRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          action,
          style: TextStyle(
            color: actionColor,
            fontSize: _font(context, 16),
            fontWeight: FontWeight.w900,
          ),
        ),
        Icon(icon, color: actionColor, size: _icon(context, 18)),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color(0xff10182b),
              fontSize: _font(context, 24),
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          onTap == null
              ? actionRow
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _ui(context, 2),
                      vertical: _ui(context, 6),
                    ),
                    child: actionRow,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _featuredRail(BuildContext context) {
    final users = homeController.exploreList.take(3).toList();
    if (users.isEmpty) {
      return _featuredEventsFallback(context);
    }

    return SizedBox(
      height: _ui(context, 204),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _ui(context, 180),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
              itemCount: users.length,
              separatorBuilder: (_, __) => SizedBox(width: _ui(context, 12)),
              itemBuilder: (context, index) {
                final user = users[index];
                return _featureCard(
                  context,
                  width: _ui(context, 260),
                  imageUrl: user.cardImageUrl,
                  badge: user.popularityLevel ?? 'Featured',
                  badgeIcon: Icons.star_rounded,
                  title: user.firstName,
                  subtitle: '📍 ${user.country}',
                  button: 'View Profile',
                  onTap: () => Navigator.pushNamed(context, RoutePath.user_detail_page, arguments: {'end_user': user}),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(BuildContext context,
      {required double width,
      String imageUrl = '',
      Color? color,
      required String badge,
      IconData? badgeIcon,
      required String title,
      required String subtitle,
      required String button,
      VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? const Color(0xff1d3540),
        borderRadius: BorderRadius.circular(_ui(context, 18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.black12,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/Group 164012 (1).jpg', fit: BoxFit.cover),
            )
          else if (color == null)
            Image.asset('assets/Group 164012 (1).jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.38)),
          Padding(
            padding: EdgeInsets.all(_ui(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _ui(context, 10),
                    vertical: _ui(context, 5),
                  ),
                  decoration: BoxDecoration(
                    color: title == 'Carnival Fete 2026'
                        ? const Color(0xffff6339)
                        : const Color(0xff19b970),
                    borderRadius: BorderRadius.circular(_ui(context, 18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badgeIcon != null) ...[
                        Icon(badgeIcon, color: Colors.white, size: _icon(context, 12)),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _font(context, 12),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _ui(context, 8)),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _font(context, 22),
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: _ui(context, 4)),
                Text(
                  subtitle.replaceAll('📍 ', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _font(context, 15),
                  ),
                ),
                SizedBox(height: _ui(context, 14)),
                Container(
                  height: _ui(context, 34),
                  padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_ui(context, 19)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        button,
                        style: TextStyle(
                          color: const Color(0xff142035),
                          fontSize: _font(context, 15),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: _ui(context, 5)),
                      Icon(Icons.arrow_forward,
                          color: const Color(0xff142035), size: _icon(context, 17)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }


  double _safePrice(dynamic value, [double fallback = 65.0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return fallback;
    return parsed;
  }

  String _bs(double value) {
    final safe = value.isNaN || value.isInfinite ? 0.0 : value;
    return 'BS\$${safe.toStringAsFixed(2)}';
  }

  ImageProvider _eventImage(String image) {
    if (image.startsWith('http')) return NetworkImage(image);
    return AssetImage(image);
  }

  void _openEventDetail(String slug) {
    if (slug.trim().isEmpty) return;
    Get.to(() => EventDetailScreen(slug: slug));
  }

  Widget _featuredEventsFallback(BuildContext context) {
    return Obx(() {
      LinkupEvent? event;
      try {
        final events = Get.find<EventsController>().eventsResponse.value.flattened;
        if (events.isNotEmpty) event = events.first;
      } catch (_) {}

      return SizedBox(
        height: _ui(context, 204),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _ui(context, 180),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
                children: [
                  _featureCard(
                    context,
                    width: _ui(context, 288),
                    imageUrl: event?.imageUrl ?? '',
                    badge: 'Trending Event',
                    badgeIcon: Icons.local_fire_department_rounded,
                    title: event?.title.isNotEmpty == true
                        ? event!.title
                        : 'Upcoming Event',
                    subtitle: event == null
                        ? '📍 $_homeCity'
                        : '📍 ${[
                            if (event.city.isNotEmpty) event.city,
                            if (event.country.isNotEmpty) event.country,
                          ].join(', ')}',
                    button: 'Get Tickets',
                    onTap: event == null
                        ? () => _openHomeDestination('Events')
                        : () => _openEventDetail(event!.slug),
                  ),
                  SizedBox(width: _ui(context, 12)),
                  _featureCard(
                    context,
                    width: _ui(context, 188),
                    imageUrl: '',
                    badge: 'Featured Live',
                    badgeIcon: Icons.auto_awesome_rounded,
                    title: 'Live now',
                    subtitle: 'Watch creators',
                    button: 'Watch Now',
                    onTap: () => _openHomeDestination('Live'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _eventDialogHeader({
    required String title,
    required VoidCallback onClose,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xffedf2f7))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xfff2f5f9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Close', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _webActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return SizedBox(
      height: 46,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 17),
              label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2f9cec),
                foregroundColor: Colors.white,
                elevation: 0,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 17, color: const Color(0xff10182b)),
              label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff10182b),
                side: const BorderSide(color: Color(0xffdbe5f0), width: 1.4),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
    );
  }

  Widget _eventInput(String hint, {int lines = 1}) {
    return TextField(
      maxLines: lines,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xff9aa8bb)),
        contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: lines == 1 ? 12 : 11),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffdbe5f0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff2f9cec), width: 1.4),
        ),
      ),
    );
  }

  Widget _eventMapPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 126,
        width: double.infinity,
        color: const Color(0xffd9f4df),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _MiniMapPainter()),
            ),
            const Center(
              child: Icon(Icons.location_on, color: Color(0xffea4335), size: 44),
            ),
            const Positioned(
              top: 14,
              left: 22,
              child: Text('Rev C Leonard Carty Rd', style: TextStyle(color: Color(0xff45556f), fontSize: 11)),
            ),
            const Positioned(
              top: 22,
              right: 22,
              child: Text('Essentials\nStationery Store', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff1a73e8), fontSize: 12, height: 1.0)),
            ),
            const Positioned(
              bottom: 19,
              right: 18,
              child: Text('Zack', style: TextStyle(color: Color(0xffe8710a), fontSize: 12)),
            ),
            const Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Text('Google', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff4285f4), fontSize: 12, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniOrganizerEvent({
    required String imageUrl,
    required String title,
    required String subtitle,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffe5edf6)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              imageUrl,
              height: 74,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset('assets/Group 164012 (1).jpg', height: 74, width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, height: 1.05)),
                  const SizedBox(height: 3),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff8fa0b6), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTicketDialog({
    required String title,
    required String image,
    required String category,
    required double price,
  }) {
    int qty = 0;
    final unitPrice = _safePrice(price);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final subtotal = unitPrice * qty;
            final fee = qty == 0 ? 0.0 : subtotal * 0.06;
            final tax = 0.0;
            final total = subtotal + fee + tax;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.78,
                  maxWidth: 430,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
                          InkWell(
                            onTap: () => Navigator.pop(dialogContext),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xfff2f5f9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('🎟 Tickets', style: TextStyle(fontSize: 18, color: Color(0xff238df2), fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffd8e4f2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('General Admission', style: TextStyle(fontWeight: FontWeight.w900)),
                                      const SizedBox(width: 6),
                                      _eventPill('Ticket'),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  const Text('General Admission', style: TextStyle(color: Color(0xff8fa0b6), fontSize: 12)),
                                  const SizedBox(height: 8),
                                  _eventPill('Type: $category · Available: 50'),
                                ],
                              ),
                            ),
                            Text(_bs(unitPrice), style: const TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(width: 10),
                            _qtyButton('−', qty == 0 ? null : () => setModalState(() => qty--)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900)),
                            ),
                            _qtyButton('+', () => setModalState(() => qty++)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image(
                          image: _eventImage(image),
                          height: 95,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      if (qty == 0)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 22),
                            child: Text('No items in cart', style: TextStyle(color: Color(0xff9aa8bb))),
                          ),
                        )
                      else ...[
                        _summaryRow('x$qty General Admission', _bs(subtotal)),
                        const SizedBox(height: 8),
                        _summaryRow('Services Subtotal', _bs(subtotal), muted: true),
                        _summaryRow('Service & Processing Fee', _bs(fee), green: true),
                        _summaryRow('Tax', _bs(tax), green: true),
                        const Divider(height: 22),
                        _summaryRow('Total', _bs(total), total: true),
                      ],
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: qty == 0 ? null : () => setModalState(() => qty = 0),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Clear Cart', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: qty == 0 ? null : () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff16a34a),
                          disabledBackgroundColor: const Color(0xffedf2f7),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: const Color(0xff9aa8bb),
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Pay with Wallet', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: qty == 0 ? null : () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2563eb),
                          disabledBackgroundColor: const Color(0xffedf2f7),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: const Color(0xff9aa8bb),
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Pay with Card', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _eventPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xffeef6ff),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xff2563eb), fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }

  Widget _eventStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffd8e4f2)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xff8fa0b6), fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _eventSection(String title, Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5edf6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _factRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xff8fa0b6), fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _qtyButton(String text, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xffedf2f7) : const Color(0xff2f9cec),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: onTap == null ? const Color(0xff9aa8bb) : Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool muted = false, bool green = false, bool total = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: muted ? const Color(0xff8fa0b6) : const Color(0xff617089),
                fontWeight: total ? FontWeight.w900 : FontWeight.w600,
                fontSize: total ? 18 : 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: green ? const Color(0xff009b72) : const Color(0xff111827),
              fontWeight: FontWeight.w900,
              fontSize: total ? 18 : 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vibesRail(BuildContext context) {
    final users = homeController.exploreList.take(5).toList();
    final names = ['@tanyab', '@islandvibez', '@reneeb', '@carlosmx', '@candice'];

    return SizedBox(
      height: _ui(context, 104),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _ui(context, 86),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 6,
              separatorBuilder: (_, __) => SizedBox(width: _ui(context, 16)),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: () => showNewVibeComposer(context),
                    child: SizedBox(
                      width: _ui(context, 58),
                      child: Column(
                        children: [
                          Container(
                            width: _ui(context, 58),
                            height: _ui(context, 58),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xff8757df), Color(0xffd348ba)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add,
                                color: Colors.white, size: _icon(context, 34)),
                          ),
                          SizedBox(height: _ui(context, 7)),
                          Text('Add',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: _font(context, 12),
                                fontWeight: FontWeight.w900,
                              )),
                        ],
                      ),
                    ),
                  );
                }
                final user = index - 1 < users.length ? users[index - 1] : null;
                final image = user?.cardImageUrl ?? '';
                final label = user?.firstName.isNotEmpty == true
                    ? '@${user!.firstName.toLowerCase()}'
                    : names[index - 1];
                return SizedBox(
                  width: _ui(context, 70),
                  child: Column(
                    children: [
                      Container(
                        width: _ui(context, 58),
                        height: _ui(context, 58),
                        padding: EdgeInsets.all(_ui(context, 3)),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xffff8438), Color(0xffef2d74), Color(0xff8757df)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: _ui(context, 23),
                            backgroundImage: image.startsWith('http')
                                ? NetworkImage(image)
                                : const AssetImage('assets/profile.png') as ImageProvider,
                          ),
                        ),
                      ),
                      SizedBox(height: _ui(context, 7)),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: _font(context, 11),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveNowSection(BuildContext context) {
    final liveItems = [
      {
        'title': 'Carnival Warmup',
        'handle': '@socaboss',
        'views': '4.2k',
        'image': 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?auto=format&fit=crop&w=700&q=80',
      },
      {
        'title': 'Caribbean Talk',
        'handle': '@island242',
        'views': '1.8k',
        'image': 'https://images.unsplash.com/photo-1513889961551-628c1e5e2ee9?auto=format&fit=crop&w=700&q=80',
      },
      {
        'title': 'Latino Beats',
        'handle': '@caribemusic',
        'views': '907',
        'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=700&q=80',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
          child: Row(
            children: [
              Container(
                width: _ui(context, 8),
                height: _ui(context, 8),
                decoration: const BoxDecoration(
                  color: Color(0xfff85264),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: _ui(context, 8)),
              Text(
                'Live Now',
                style: TextStyle(
                  color: const Color(0xff10182b),
                  fontSize: _font(context, 24),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openHomeDestination('Live'),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: _ui(context, 6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See all',
                        style: TextStyle(
                          color: const Color(0xff2589df),
                          fontSize: _font(context, 16),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: const Color(0xff2589df), size: _icon(context, 18)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _ui(context, 12)),
        SizedBox(
          height: _ui(context, 132),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: liveItems.length,
            separatorBuilder: (_, __) => SizedBox(width: _ui(context, 12)),
            itemBuilder: (context, index) {
              final item = liveItems[index];
              return _liveCard(
                context,
                title: item['title']!,
                handle: item['handle']!,
                views: item['views']!,
                imageUrl: item['image']!,
                onTap: () => _openHomeDestination('Live'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _liveCard(BuildContext context,
      {required String title,
      required String handle,
      required String views,
      required String imageUrl,
      VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
      width: _ui(context, 154),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xff0f3448),
        borderRadius: BorderRadius.circular(_ui(context, 13)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.black12,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) =>
                Image.asset('assets/Group 164012 (1).jpg', fit: BoxFit.cover),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xcc071827)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: _ui(context, 8),
            top: _ui(context, 8),
            child: Container(
              height: _ui(context, 19),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 7)),
              decoration: BoxDecoration(
                color: const Color(0xffff3360),
                borderRadius: BorderRadius.circular(_ui(context, 8)),
              ),
              child: Center(
                child: Text(
                  '• LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _font(context, 9),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: _ui(context, 8),
            top: _ui(context, 8),
            child: Container(
              height: _ui(context, 19),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 7)),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.50),
                borderRadius: BorderRadius.circular(_ui(context, 8)),
              ),
              child: Center(
                child: Text(
                  '👥 $views',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _font(context, 9),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: _ui(context, 10),
            right: _ui(context, 10),
            bottom: _ui(context, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _font(context, 14),
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: _ui(context, 3)),
                Text(
                  handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.80),
                    fontSize: _font(context, 11),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _earnCoinsSection(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openHomeDestination('Wallet'),
      child: Container(
      height: _ui(context, 88),
      margin: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xfff8a500), Color(0xffeb4278)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(_ui(context, 22)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffeb4278).withOpacity(0.25),
            blurRadius: 11,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: _ui(context, 48),
            height: _ui(context, 48),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(_ui(context, 16)),
            ),
            child: Center(
              child: Icon(
                Icons.monetization_on_outlined,
                color: Colors.white,
                size: _icon(context, 32),
              ),
            ),
          ),
          SizedBox(width: _ui(context, 14)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get paid to be liked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _font(context, 20),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: _ui(context, 3)),
                Text(
                  'Earn coins on LinkUp when people send you a Vibe.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: _font(context, 13),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white, size: _icon(context, 28)),
        ],
      ),
      ),
    );
  }

  Widget _nearYouSection(BuildContext context) {
    final nearbyUsers = homeController.exploreList.where((u) => u.distance != null).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
          child: Text(
            'Near you in $_homeCity',
            style: TextStyle(
              color: const Color(0xff10182b),
              fontSize: _font(context, 24),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: _ui(context, 12)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: _ui(context, 12),
              mainAxisSpacing: _ui(context, 12),
              childAspectRatio: 1.18,
            ),
            itemCount: math.max(4, nearbyUsers.length > 4 ? 4 : nearbyUsers.length),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              if (index < nearbyUsers.length) {
                final user = nearbyUsers[index];
                return _venueCard(
                  context,
                  title: '${user.firstName}, ${user.age}',
                  meta: '${user.distance} km away',
                  metaIcon: Icons.location_on_outlined,
                  badge: 'LinkUp',
                  badgeColor: const Color(0xffea2d77),
                  imageUrl: user.cardImageUrl,
                  onTap: () => Navigator.pushNamed(context, RoutePath.user_detail_page, arguments: {'end_user': user}),
                );
              }
              
              // Fallback/Static items if less than 4 users
              final fallbacks = [
                () => _venueCard(
                  context,
                  title: 'Polished Gem Wellness ...',
                  meta: '31 Mar 2026 - 29 Jun 2026',
                  badge: 'Event',
                  badgeColor: const Color(0xffff9f00),
                  imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=700&q=80',
                  onTap: () => _openHomeDestination('Events'),
                ),
                () => _venueCard(
                  context,
                  title: 'Wax Moi',
                  meta: '30 Aug 2026',
                  badge: 'Event',
                  badgeColor: const Color(0xffff9f00),
                  imageUrl: 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=700&q=80',
                  onTap: () => _openHomeDestination('Events'),
                ),
                () => _venueCard(
                  context,
                  title: 'Bahama Breeze Grill',
                  meta: '4.8 · 25–35 min',
                  metaIcon: Icons.star,
                  badge: 'Eats',
                  badgeColor: const Color(0xff19a96b),
                  imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=700&q=80',
                  onTap: () => _openHomeDestination('Eats'),
                ),
              ];
              
              final fallbackIndex = index - nearbyUsers.length;
              if (fallbackIndex < fallbacks.length) {
                return fallbacks[fallbackIndex]();
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _venueCard(
    BuildContext context, {
    required String title,
    required String meta,
    IconData? metaIcon,
    required String badge,
    required Color badgeColor,
    required String imageUrl,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.black12,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Image.asset(
                      'assets/Group 164012 (1).jpg',
                      fit: BoxFit.cover),
                ),
                Positioned(
                  left: _ui(context, 8),
                  top: _ui(context, 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _ui(context, 8),
                      vertical: _ui(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(_ui(context, 10)),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _font(context, 9),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              _ui(context, 9),
              _ui(context, 8),
              _ui(context, 9),
              _ui(context, 8),
            ),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xff10182b),
                    fontSize: _font(context, 14),
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: _ui(context, 5)),
                Row(
                  children: [
                    if (metaIcon != null) ...[
                      Icon(metaIcon, color: const Color(0xff8fa1b7), size: _icon(context, 12)),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xff8fa1b7),
                          fontSize: _font(context, 12),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _happeningNowSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
          child: Text(
            'Happening now',
            style: TextStyle(
              color: const Color(0xff10182b),
              fontSize: _font(context, 24),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: _ui(context, 12)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
          child: Column(
            children: [
              _feedItem(
                context,
                icon: Icons.sensors,
                title: '@islandvibez',
                subtitle: 'is live now 🔴',
                badge: 'LIVE',
                colors: const [Color(0xffff7a1a), Color(0xffff2f6d)],
                onTap: () => _openHomeDestination('Live'),
              ),
              SizedBox(height: _ui(context, 10)),
              _feedItem(
                context,
                icon: Icons.shopping_bag_outlined,
                title: 'Straw Bags',
                subtitle: 'New drop in Marketplace',
                badge: 'NEW',
                colors: const [Color(0xff8b42f5), Color(0xff9f39ff)],
                onTap: () => _openHomeDestination('Marketplace'),
              ),
              SizedBox(height: _ui(context, 10)),
              _feedItem(
                context,
                icon: Icons.confirmation_number_outlined,
                title: 'Carnival Fete 2026',
                subtitle: '80% sold — going fast',
                badge: '🔥 HOT',
                colors: const [Color(0xffff9b00), Color(0xffff2f6d)],
                onTap: () => _openHomeDestination('Events'),
              ),
              SizedBox(height: _ui(context, 10)),
              _feedItem(
                context,
                icon: Icons.favorite_border,
                title: '3 new matches',
                subtitle: 'nearby in $_homeCity',
                badge: '💗',
                colors: const [Color(0xffec2d67), Color(0xffff2f6d)],
                onTap: () => _openHomeDestination('Matches'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _feedItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required List<Color> colors,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
      height: _ui(context, 66),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(_ui(context, 16)),
      ),
      padding: EdgeInsets.all(_ui(context, 2)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 14)),
        ),
        child: Row(
          children: [
            Container(
              width: _ui(context, 40),
              height: _ui(context, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(_ui(context, 12)),
              ),
              child: Icon(icon, color: Colors.white, size: _icon(context, 23)),
            ),
            SizedBox(width: _ui(context, 12)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xff10182b),
                      fontSize: _font(context, 15),
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: _ui(context, 5)),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xff8fa1b7),
                      fontSize: _font(context, 12),
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: _ui(context, 22),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 9)),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(_ui(context, 12)),
              ),
              child: Center(
                child: Text(
                  badge,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _font(context, 10),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }


  void _showLinkUpAiPopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close LinkUp AI',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final size = MediaQuery.of(dialogContext).size;
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: size.width - _ui(context, 24),
                constraints: BoxConstraints(
                  maxWidth: _ui(context, 430),
                  maxHeight: size.height * 0.72,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_ui(context, 24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      height: _ui(context, 72),
                      padding: EdgeInsets.symmetric(horizontal: _ui(context, 15)),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xff7c3aed), Color(0xff2f9bef), Color(0xff06b6d4)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: [0.0, 0.52, 1.0],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: _ui(context, 38),
                            height: _ui(context, 38),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.24),
                              borderRadius: BorderRadius.circular(_ui(context, 13)),
                            ),
                            child: Icon(Icons.auto_awesome, color: Colors.white, size: _icon(context, 25)),
                          ),
                          SizedBox(width: _ui(context, 10)),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LinkUp AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _font(context, 22),
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                                SizedBox(height: _ui(context, 3)),
                                Text(
                                  'Your island concierge',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.90),
                                    fontSize: _font(context, 12),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: Padding(
                              padding: EdgeInsets.all(_ui(context, 8)),
                              child: Icon(Icons.close_rounded, color: Colors.white, size: _icon(context, 25)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(_ui(context, 16), _ui(context, 16), _ui(context, 16), 0),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: _ui(context, 28),
                                      height: _ui(context, 28),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xff7c3aed), Color(0xff0ea5e9)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.auto_awesome, color: Colors.white, size: _icon(context, 17)),
                                    ),
                                    SizedBox(width: _ui(context, 10)),
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.all(_ui(context, 13)),
                                        decoration: BoxDecoration(
                                          color: const Color(0xfff0f4f8),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(_ui(context, 4)),
                                            topRight: Radius.circular(_ui(context, 18)),
                                            bottomLeft: Radius.circular(_ui(context, 18)),
                                            bottomRight: Radius.circular(_ui(context, 18)),
                                          ),
                                        ),
                                        child: Text(
                                          'Hey $_firstName 👋 I\'m your LinkUp AI. Tell me what you want to do — buy something, get a ticket, order food, find people, catch the news — and I\'ll take you straight there.',
                                          style: TextStyle(
                                            color: const Color(0xff273247),
                                            fontSize: _font(context, 14),
                                            fontWeight: FontWeight.w600,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: _ui(context, 43),
                            padding: EdgeInsets.only(left: _ui(context, 14)),
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _aiPromptChip(context, 'Find me tickets this weekend'),
                                _aiPromptChip(context, 'Order Caribbean food'),
                                _aiPromptChip(context, 'Buy a straw bag'),
                                _aiPromptChip(context, 'Show live streams'),
                                _aiPromptChip(context, 'Find people nearby'),
                              ],
                            ),
                          ),
                          Container(
                            height: _ui(context, 5),
                            margin: EdgeInsets.only(right: _ui(context, 210)),
                            decoration: BoxDecoration(
                              color: const Color(0xffa8c9e6),
                              borderRadius: BorderRadius.circular(_ui(context, 99)),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 12), _ui(context, 12), _ui(context, 12)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: _ui(context, 44),
                                    padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: const Color(0xfff0f4f8),
                                      borderRadius: BorderRadius.circular(_ui(context, 24)),
                                    ),
                                    child: Text(
                                      'Ask anything...',
                                      style: TextStyle(
                                        color: const Color(0xff9aa6b5),
                                        fontSize: _font(context, 14),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: _ui(context, 9)),
                                Container(
                                  height: _ui(context, 44),
                                  padding: EdgeInsets.symmetric(horizontal: _ui(context, 18)),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xff2f9bef),
                                    borderRadius: BorderRadius.circular(_ui(context, 22)),
                                  ),
                                  child: Text(
                                    'Send',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: _font(context, 14),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _aiPromptChip(BuildContext context, String label) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final lower = label.toLowerCase();
        Navigator.of(context).pop();
        if (lower.contains('ticket')) {
          _openHomeDestination('Events', context);
        } else if (lower.contains('food')) {
          _openHomeDestination('Eats', context);
        } else if (lower.contains('market') || lower.contains('straw') || lower.contains('product')) {
          _openHomeDestination('Market', context);
        } else if (lower.contains('news') || lower.contains('360')) {
          _openHomeDestination('360 News', context);
        } else if (lower.contains('night')) {
          _openHomeDestination('Nightlife', context);
        } else if (lower.contains('live')) {
          _openHomeDestination('Live', context);
        } else {
          _openHomeDestination('LinkUp', context);
        }
      },
      child: Container(
        height: _ui(context, 30),
        margin: EdgeInsets.only(right: _ui(context, 8), top: _ui(context, 6), bottom: _ui(context, 6)),
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xffeef3f8),
          borderRadius: BorderRadius.circular(_ui(context, 18)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xff344155),
            fontSize: _font(context, 12),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  void _showWeatherSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: EdgeInsets.all(_ui(context, 12)),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 28))),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(_ui(context, 22)),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xff60a5fa), Color(0xff93c5fd)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$_homeCity, $_homeCountry', style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: _font(context, 14), fontWeight: FontWeight.w800)),
                    SizedBox(height: _ui(context, 4)),
                    Text('28°C', style: TextStyle(color: Colors.white, fontSize: _font(context, 44), fontWeight: FontWeight.w900)),
                    Text('Partly cloudy', style: TextStyle(color: Colors.white, fontSize: _font(context, 17), fontWeight: FontWeight.w800)),
                  ])),
                  Column(children: [Text('⛅', style: TextStyle(fontSize: _font(context, 54))), SizedBox(height: _ui(context, 8)), Container(padding: EdgeInsets.all(_ui(context, 3)), decoration: BoxDecoration(color: Colors.white.withOpacity(.25), borderRadius: BorderRadius.circular(_ui(context, 20))), child: Row(children: [_weatherUnitChip(context, '°C', true), _weatherUnitChip(context, '°F', false)]))]),
                ]),
              ),
              Padding(
                padding: EdgeInsets.all(_ui(context, 16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Today', style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
                  SizedBox(height: _ui(context, 12)),
                  Row(children: [_forecastTile(context, 'Now', '⛅', '28°'), SizedBox(width: _ui(context, 8)), _forecastTile(context, 'Midday', '☀️', '30°'), SizedBox(width: _ui(context, 8)), _forecastTile(context, 'Evening', '🌥️', '27°'), SizedBox(width: _ui(context, 8)), _forecastTile(context, 'Night', '☁️', '24°')]),
                  SizedBox(height: _ui(context, 12)),
                  Row(children: [_weatherMetric(context, 'Feels', '30°'), SizedBox(width: _ui(context, 8)), _weatherMetric(context, 'Humidity', '83%'), SizedBox(width: _ui(context, 8)), _weatherMetric(context, 'Wind', '12 km/h')]),
                  SizedBox(height: _ui(context, 12)),
                  Center(child: Text('Tap °C / °F to switch · weather updates with your location.', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 12), fontWeight: FontWeight.w700))),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _weatherUnitChip(BuildContext context, String text, bool active) => Container(padding: EdgeInsets.symmetric(horizontal: _ui(context, 13), vertical: _ui(context, 6)), decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(_ui(context, 18))), child: Text(text, style: TextStyle(color: active ? const Color(0xff111827) : Colors.white, fontSize: _font(context, 13), fontWeight: FontWeight.w900)));

  Widget _forecastTile(BuildContext context, String time, String icon, String temp) => Expanded(child: Container(padding: EdgeInsets.symmetric(vertical: _ui(context, 12)), decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(_ui(context, 18))), child: Column(children: [Text(time, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 12), fontWeight: FontWeight.w800)), SizedBox(height: _ui(context, 6)), Text(icon, style: TextStyle(fontSize: _font(context, 24))), SizedBox(height: _ui(context, 5)), Text(temp, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 16), fontWeight: FontWeight.w900))])));

  Widget _weatherMetric(BuildContext context, String label, String value) => Expanded(child: Container(padding: EdgeInsets.symmetric(vertical: _ui(context, 10)), decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(_ui(context, 14))), child: Column(children: [Text(label, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 11), fontWeight: FontWeight.w800)), SizedBox(height: _ui(context, 4)), Text(value, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 16), fontWeight: FontWeight.w900))])));

  Future<void> _showLocationPicker(BuildContext context) async {
    final location = await LinkupLocationService.showPicker(context);
    if (!mounted || location == null) return;
    setState(() {
      _homeCity = location.city;
      _homeCountry = location.country;
      _homeFlag = location.flag;
    });
  }

  Widget _bottomBar(BuildContext context) {
    final items = [
      [Icons.home_outlined, 'Home', true],
      [Icons.image_outlined, 'Vibes', false],
      [Icons.restaurant_outlined, 'Eats', false],
      [Icons.sensors, 'Live', false],
      [Icons.favorite_border, 'LinkUp', false],
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
                if (item[1] == 'Vibes') Get.to(() => const VibesPage());
                if (item[1] == 'Eats') Get.to(() => const EatsPage());
                if (item[1] == 'Live') Get.to(() => const LivePage());
                if (item[1] == 'LinkUp') Get.to(ChatHomePage());
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: selected ? _ui(context, 30) : _ui(context, 26),
                    height: selected ? _ui(context, 30) : _ui(context, 26),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xff2d98e5) : Colors.transparent,
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
                      color: selected ? const Color(0xff2589df) : const Color(0xff627085),
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



class _HomeNewsTicker extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _HomeNewsTicker({required this.text, required this.style});
  @override
  State<_HomeNewsTicker> createState() => _HomeNewsTickerState();
}

class _HomeNewsTickerState extends State<_HomeNewsTicker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return AnimatedBuilder(animation: _controller, builder: (_, __) {
        final width = constraints.maxWidth;
        final dx = width - (_controller.value * width * 2.8);
        return Transform.translate(offset: Offset(dx, 0), child: SizedBox(width: width * 2.8, child: Text('${widget.text}${widget.text}', maxLines: 1, overflow: TextOverflow.visible, softWrap: false, style: widget.style)));
      });
    });
  }
}


class _EventFactBox extends StatelessWidget {
  final String label;
  final String value;

  const _EventFactBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdbe5f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff8fa0b6),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xff111827),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final roadThin = Paint()
      ..color = const Color(0xffbaded0)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final water = Paint()
      ..color = const Color(0xffc7eef4).withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final p1 = Path()
      ..moveTo(-20, size.height * .78)
      ..quadraticBezierTo(size.width * .25, size.height * .50, size.width * .52, size.height * .68)
      ..quadraticBezierTo(size.width * .76, size.height * .84, size.width + 20, size.height * .55);
    canvas.drawPath(p1, road);
    canvas.drawPath(p1, roadThin);

    final p2 = Path()
      ..moveTo(size.width * .20, -10)
      ..quadraticBezierTo(size.width * .26, size.height * .35, size.width * .52, size.height * .44)
      ..quadraticBezierTo(size.width * .75, size.height * .52, size.width * .92, size.height + 10);
    canvas.drawPath(p2, road);
    canvas.drawPath(p2, roadThin);

    canvas.drawOval(Rect.fromLTWH(size.width * .62, -16, size.width * .42, size.height * .48), water);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum Location { Men, Women, Everyone }

enum Location1 {
  twenty2,
  twenty3,
  twenty4,
  twenty5,
  twenty6,
  twenty7,
  twenty8,
  twenty9,
}


enum Location2 {
  hundred1,
  hundred2,
  hundred3,
  hundred4,
  hundred5,
  hundred6,
  hundred7,
  hundred8,
  hundred9,
  hundred10,
  wholecountry,
}


enum Location3 { all, other }
