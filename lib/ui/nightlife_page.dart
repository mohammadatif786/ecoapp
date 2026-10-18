import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/home_controller.dart';
import 'package:link_up/get_controller/nightlife_controller.dart';
import 'package:link_up/model/nightlife_model.dart';
import 'package:link_up/ui/chat_home_page.dart';
import 'package:link_up/ui/eats_page.dart';
import 'package:link_up/ui/home_page.dart';
import 'package:link_up/ui/live_page.dart';
import 'package:link_up/ui/nightlife_detail_page.dart';
import 'package:link_up/ui/notification_page.dart';
import 'package:link_up/ui/profile/profile_page.dart';
import 'package:link_up/ui/vibes_page.dart';
import 'package:link_up/ui/wallet_page.dart';
import 'package:link_up/widgets/linkup_current_user.dart';
import 'package:link_up/widgets/linkup_location_sheet.dart';

class NightlifePage extends StatefulWidget {
  const NightlifePage({super.key});

  @override
  State<NightlifePage> createState() => _NightlifePageState();
}

class _NightlifePageState extends State<NightlifePage> {
  final HomeController homeController =
      Get.find(tag: HomeController().toString());
  late final NightlifeController _controller;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<NightlifeController>()) {
      Get.put(NightlifeController());
    }
    _controller = Get.find<NightlifeController>();
    _controller.fetchNightlife();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) => _ui(context, value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeaf4fe),
      body: SafeArea(
        child: Column(
          children: [
            _topHeader(context),
            _geoBar(context),
            _nightlifeBar(context),
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value &&
                    _controller.clubs.isEmpty &&
                    _controller.restaurants.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_controller.error.value != null &&
                    _controller.clubs.isEmpty &&
                    _controller.restaurants.isEmpty) {
                  return _errorState(context);
                }
                return RefreshIndicator(
                  onRefresh: _controller.fetchNightlife,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _searchAndTabs(context)),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          _ui(context, 14),
                          _ui(context, 4),
                          _ui(context, 14),
                          _ui(context, 18),
                        ),
                        sliver: _placesSliver(context),
                      ),
                    ],
                  ),
                );
              }),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _topHeader(BuildContext context) {
    return Container(
      height: _ui(context, 56),
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff2f9bef), Color(0xff2487e0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Text(
            'Link',
            style: TextStyle(
              fontSize: _font(context, 26),
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 1,
            ),
          ),
          Text(
            'üp',
            style: TextStyle(
              fontSize: _font(context, 26),
              color: const Color(0xffffe14d),
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 1,
            ),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.to(() => const WalletPage()),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _ui(context, 13),
                vertical: _ui(context, 7),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(_ui(context, 22)),
              ),
              child: Row(
                children: [
                  Icon(Icons.paid_outlined,
                      color: Colors.white, size: _ui(context, 15)),
                  SizedBox(width: _ui(context, 5)),
                  Text(
                    '${homeController.coins}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _font(context, 14),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: _ui(context, 12)),
          LinkUpNotificationBell(
            icon: Icons.notifications_none,
            iconSize: _ui(context, 27),
            badgeSize: _ui(context, 18),
            badgeFontSize: _font(context, 10),
          ),
          SizedBox(width: _ui(context, 10)),
          LinkUpCurrentUserAvatar(
            radius: _ui(context, 17),
            innerRadius: _ui(context, 15),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProfilePage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _geoBar(BuildContext context) {
    return LinkupLocationBar(
      height: _ui(context, 29),
      horizontalPadding: _ui(context, 16),
      iconSize: _ui(context, 16),
      fontSize: _font(context, 12),
      changeFontSize: _font(context, 12),
      textColor: const Color(0xff334155),
      changeColor: const Color(0xff168eea),
      iconColor: const Color(0xff2f9bef),
    );
  }

  Widget _nightlifeBar(BuildContext context) {
    return Container(
      height: _ui(context, 46),
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff7c3aed), Color(0xffff2f92)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Row(
              children: [
                Icon(Icons.arrow_back,
                    color: Colors.white, size: _ui(context, 18)),
                SizedBox(width: _ui(context, 4)),
                Text(
                  'Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: _font(context, 14),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: _ui(context, 12)),
          Icon(Icons.nightlife, color: Colors.white, size: _ui(context, 18)),
          SizedBox(width: _ui(context, 6)),
          Text(
            'Nightlife',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: _font(context, 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchAndTabs(BuildContext context) {
    final clubsCount = _controller.clubs.length;
    final restaurantsCount = _controller.restaurants.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _ui(context, 14),
        _ui(context, 16),
        _ui(context, 14),
        _ui(context, 10),
      ),
      child: Column(
        children: [
          Container(
            height: _ui(context, 48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_ui(context, 14)),
            ),
            padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
            child: Row(
              children: [
                Icon(Icons.search,
                    color: const Color(0xff94a3b8), size: _ui(context, 22)),
                SizedBox(width: _ui(context, 10)),
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (value) => _controller.searchQuery.value = value,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search clubs or restaurants',
                    ),
                    style: TextStyle(
                      fontSize: _font(context, 15),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _ui(context, 12)),
          Row(
            children: [
              _tabChip(context, 0, 'Clubs', clubsCount),
              SizedBox(width: _ui(context, 8)),
              _tabChip(context, 1, 'Restaurants', restaurantsCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabChip(BuildContext context, int index, String label, int count) {
    final selected = _controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _controller.selectedTab.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: _ui(context, 42),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xff7c3aed) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? const Color(0xff7c3aed) : const Color(0xffd9e4f2),
            ),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xff334155),
              fontWeight: FontWeight.w900,
              fontSize: _font(context, 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placesSliver(BuildContext context) {
    final places = _controller.visiblePlaces;
    if (places.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'No places found',
            style: TextStyle(
              color: const Color(0xff64748b),
              fontSize: _font(context, 15),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _placeCard(context, places[index]),
        childCount: places.length,
      ),
    );
  }

  Widget _placeCard(BuildContext context, NightlifePlace place) {
    return GestureDetector(
      onTap: () => _openPlace(place),
      child: Container(
        margin: EdgeInsets.only(bottom: _ui(context, 14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _placeImage(context, place),
            Padding(
              padding: EdgeInsets.fromLTRB(
                _ui(context, 14),
                _ui(context, 12),
                _ui(context, 14),
                _ui(context, 14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name.isEmpty ? 'Untitled place' : place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xff0f172a),
                      fontSize: _font(context, 18),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (place.address.isNotEmpty) ...[
                    SizedBox(height: _ui(context, 4)),
                    Text(
                      place.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xff64748b),
                        fontSize: _font(context, 13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeImage(BuildContext context, NightlifePlace place) {
    return Stack(
      children: [
        SizedBox(
          height: _ui(context, 168),
          width: double.infinity,
          child: place.imageUrl.isEmpty
              ? _imageFallback(context)
              : Image.network(
                  place.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imageFallback(context),
                ),
        ),
        if (place.ratingLabel.isNotEmpty)
          Positioned(
            right: _ui(context, 12),
            top: _ui(context, 12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _ui(context, 8),
                vertical: _ui(context, 4),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_ui(context, 8)),
              ),
              child: Row(
                children: [
                  Icon(Icons.star,
                      color: const Color(0xfff59e0b), size: _ui(context, 14)),
                  SizedBox(width: _ui(context, 4)),
                  Text(
                    place.ratingLabel,
                    style: TextStyle(
                      color: const Color(0xff0f172a),
                      fontWeight: FontWeight.w900,
                      fontSize: _font(context, 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _imageFallback(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff7c3aed), Color(0xffff2f92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.nightlife, color: Colors.white, size: _ui(context, 42)),
    );
  }

  Widget _errorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Could not load nightlife',
            style: TextStyle(
              color: const Color(0xff0f172a),
              fontSize: _font(context, 18),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: _ui(context, 10)),
          TextButton(
            onPressed: _controller.fetchNightlife,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  void _openPlace(NightlifePlace place) {
    if (place.placeId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NightlifeDetailPage(
          kind: place.kind,
          placeId: place.placeId,
          preview: place,
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final items = [
      [Icons.home_outlined, 'Home', false],
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
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(_ui(context, 18)),
              onTap: () {
                if (item[1] == 'Home') Get.off(() => HomePage());
                if (item[1] == 'Vibes') Get.off(() => const VibesPage());
                if (item[1] == 'Eats') Get.off(() => const EatsPage());
                if (item[1] == 'Live') Get.off(() => const LivePage());
                if (item[1] == 'LinkUp') Get.off(() => ChatHomePage());
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item[0] as IconData,
                    color: const Color(0xff69768a),
                    size: _ui(context, 24),
                  ),
                  SizedBox(height: _ui(context, 3)),
                  Text(
                    item[1] as String,
                    maxLines: 1,
                    style: TextStyle(
                      color: const Color(0xff627085),
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
