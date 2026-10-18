import 'dart:async';
import 'package:flutter/material.dart';
import 'package:link_up/ui/profile/profile_page.dart';
import 'package:link_up/widgets/linkup_location_sheet.dart';
import '../widgets/linkup_current_user.dart';
import 'package:get/get.dart';
import 'package:link_up/ui/wallet_page.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/ui/chat_home_page.dart';
import 'package:link_up/ui/eats_page.dart';
import 'package:link_up/ui/home_page.dart';
import 'package:link_up/ui/notification_page.dart';
import 'package:link_up/ui/vibes_page.dart';
import 'package:link_up/get_controller/live_controller.dart';
import 'package:link_up/model/live_stream_model.dart';
import 'package:link_up/ui/live/broadcast_settings_sheet.dart';

class LivePage extends StatefulWidget {
  const LivePage({Key? key}) : super(key: key);

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final AuthController authController = Get.find(tag: AuthController().toString());
  final LiveController liveController = Get.find<LiveController>();
  final ScrollController _scrollController = ScrollController();

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.9, 1.08).toDouble();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  ImageProvider _avatarProvider() => LinkUpCurrentUser.avatarProvider();

  String get _currentFirstName => LinkUpCurrentUser.firstName();
  String get _currentFullName => LinkUpCurrentUser.fullName();


  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 1300)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeaf4fe),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await liveController.fetchCategories();
            await liveController.fetchStreams();
          },
          child: Column(
            children: [
              _topHeader(context),
              _geoBar(context),
              Expanded(
                child: Obx(() {
                  if (liveController.isLoading.value && liveController.streams.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _heroBlock(context)),
                      SliverToBoxAdapter(child: _categoryRail(context)),
                      if (liveController.streams.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sensors_off, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No live streams available',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                if (liveController.selectedCategory.value != 'All')
                                  TextButton(
                                    onPressed: () => liveController.changeCategory('All'),
                                    child: const Text('View All Categories'),
                                  ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(_ui(context, 14), _ui(context, 12), _ui(context, 14), _ui(context, 16)),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _liveCard(context, liveController.streams[index]),
                              childCount: liveController.streams.length,
                            ),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: _ui(context, 12),
                              crossAxisSpacing: _ui(context, 12),
                              childAspectRatio: 0.82,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
              _bottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      height: topPad + _ui(context, 58),
      padding: EdgeInsets.only(top: topPad, left: _ui(context, 18), right: _ui(context, 14)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xff2f9bef), Color(0xff168eea)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Text('ü', style: TextStyle(color: const Color(0xff9edb2f), fontSize: _font(context, 24), fontWeight: FontWeight.w900, height: 1)),
              SizedBox(width: _ui(context, 8)),
              Text('Link', style: TextStyle(color: Colors.white, fontSize: _font(context, 27), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, height: 1)),
              Text('üp', style: TextStyle(color: const Color(0xffffe14d), fontSize: _font(context, 24), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, height: 1)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.to(() => const WalletPage()),
            child: Container(
              height: _ui(context, 30),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 13)),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), borderRadius: BorderRadius.circular(_ui(context, 24))),
              child: Row(children: [
                Icon(Icons.monetization_on_outlined, color: Colors.white, size: _ui(context, 16)),
                SizedBox(width: _ui(context, 6)),
                Text('37,005', style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
          SizedBox(width: _ui(context, 12)),
          LinkUpNotificationBell(
            icon: Icons.notifications_none,
            iconSize: _ui(context, 25),
            badgeSize: _ui(context, 19),
            badgeFontSize: _font(context, 10),
          ),
          SizedBox(width: _ui(context, 12)),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage())),
            child: CircleAvatar(radius: _ui(context, 17), backgroundColor: Colors.white, child: CircleAvatar(radius: _ui(context, 15), backgroundImage: _avatarProvider())),
          ),
        ],
      ),
    );
  }

  Widget _geoBar(BuildContext context) {
    return LinkupLocationBar(
      height: _ui(context, 30),
      horizontalPadding: _ui(context, 15),
      iconSize: _ui(context, 15),
      fontSize: _font(context, 12),
      changeFontSize: _font(context, 12),
      textColor: const Color(0xff26364d),
      changeColor: const Color(0xff168eea),
      iconColor: const Color(0xff2f9bef),
    );
  }

  Widget _heroBlock(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(_ui(context, 14), _ui(context, 16), _ui(context, 14), _ui(context, 4)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Text(
              'LinkUp Live',
              style: TextStyle(color: const Color(0xff071326), fontSize: _font(context, 26), fontWeight: FontWeight.w900, height: 1.0),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showAnalytics,
            child: Container(
              height: _ui(context, 34),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 13)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_ui(context, 20)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bar_chart_rounded, color: const Color(0xff42516a), size: _ui(context, 16)),
                SizedBox(width: _ui(context, 6)),
                Text('Analytics', style: TextStyle(color: const Color(0xff26364d), fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
        ]),
        SizedBox(height: _ui(context, 14)),
        Text(
          'Live streams, shows & podcasts from across the region.',
          style: TextStyle(color: const Color(0xff617089), fontSize: _font(context, 14), fontWeight: FontWeight.w600),
        ),
        SizedBox(height: _ui(context, 18)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _showBroadcastSettings,
          child: Container(
            height: _ui(context, 52),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xffff3f4f), Color(0xffe83fa4)], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(_ui(context, 15)),
              boxShadow: [BoxShadow(color: const Color(0xffec4899).withOpacity(0.16), blurRadius: 14, offset: const Offset(0, 8))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: _ui(context, 9), height: _ui(context, 9), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              SizedBox(width: _ui(context, 8)),
              Text('Go Live', style: TextStyle(color: Colors.white, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _roundAction(BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _ui(context, 42),
        height: _ui(context, 42),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: _ui(context, 22)),
      ),
    );
  }

  Widget _statPill(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 10), vertical: _ui(context, 10)),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(_ui(context, 16)), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: _ui(context, 12)), SizedBox(width: _ui(context, 4)), Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: _font(context, 9), fontWeight: FontWeight.w900)))]),
        SizedBox(height: _ui(context, 5)),
        Text(value, style: TextStyle(color: Colors.white, fontSize: _font(context, 18), fontWeight: FontWeight.w900, height: 1)),
      ]),
    );
  }

  Widget _gradientButton(BuildContext context, {required IconData icon, required String label, required List<Color> colors, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _ui(context, 48),
        decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(_ui(context, 18))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: _ui(context, 18)),
          SizedBox(width: _ui(context, 7)),
          Text(label, style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  Widget _softButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _ui(context, 48),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(_ui(context, 18)), border: Border.all(color: Colors.white.withOpacity(0.10))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: _ui(context, 18)),
          SizedBox(width: _ui(context, 7)),
          Text(label, style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  Widget _categoryRail(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: _ui(context, 12)),
      height: _ui(context, 52),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: _ui(context, 39),
          child: Obx(() => ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final label = liveController.categories[index];
              final selected = label == liveController.selectedCategory.value;
              return GestureDetector(
                onTap: () => liveController.changeCategory(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(horizontal: _ui(context, 14), vertical: _ui(context, 8)),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xff2f9bef) : Colors.white,
                    borderRadius: BorderRadius.circular(_ui(context, 18)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(selected ? 0.10 : 0.03), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xff35445b), fontSize: _font(context, 12), fontWeight: FontWeight.w900))),
                ),
              );
            },
            separatorBuilder: (_, __) => SizedBox(width: _ui(context, 8)),
            itemCount: liveController.categories.length,
          )),
        ),
        Padding(
          padding: EdgeInsets.only(left: _ui(context, 14), top: _ui(context, 6)),
          child: Container(width: _ui(context, 88), height: _ui(context, 4), decoration: BoxDecoration(color: const Color(0xffa8cef1), borderRadius: BorderRadius.circular(_ui(context, 6)))),
        ),
      ]),
    );
  }

  Widget _liveCard(BuildContext context, LiveStream stream) {
    final bool isLive = stream.status.toLowerCase() == 'live';
    return GestureDetector(
      onTap: () => _showLiveRoom(stream),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_ui(context, 18)),
        child: Container(
          color: const Color(0xff0f172a),
          child: Stack(children: [
            Positioned.fill(child: Image.network(stream.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xff0d2944)))),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.08), Colors.black.withOpacity(0.18), Colors.black.withOpacity(0.85)],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: _ui(context, 9),
              left: _ui(context, 9),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: _ui(context, 8), vertical: _ui(context, 5)),
                decoration: BoxDecoration(color: isLive ? const Color(0xffff315f) : const Color(0xff4b5563), borderRadius: BorderRadius.circular(_ui(context, 8))),
                child: Row(children: [
                  if (isLive) Container(width: _ui(context, 6), height: _ui(context, 6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  if (isLive) SizedBox(width: _ui(context, 4)),
                  Text(isLive ? 'LIVE' : 'Upcoming', style: TextStyle(color: Colors.white, fontSize: _font(context, 9), fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
            Positioned(
              top: _ui(context, 9),
              right: _ui(context, 9),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: _ui(context, 8), vertical: _ui(context, 5)),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.42), borderRadius: BorderRadius.circular(_ui(context, 10))),
                child: Row(children: [Icon(Icons.people_alt, color: Colors.white, size: _ui(context, 12)), SizedBox(width: _ui(context, 4)), Text('${stream.likeCount}', style: TextStyle(color: Colors.white, fontSize: _font(context, 9), fontWeight: FontWeight.w900))]),
              ),
            ),
            Positioned(
              left: _ui(context, 10),
              right: _ui(context, 10),
              bottom: _ui(context, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(stream.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: _font(context, 15), fontWeight: FontWeight.w900, height: 1.05)),
                SizedBox(height: _ui(context, 3)),
                Text(stream.broadcastType, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: _font(context, 9), fontWeight: FontWeight.w700)),
                SizedBox(height: _ui(context, 8)),
                Row(children: [
                  _metric(context, Icons.favorite, '${stream.likeCount}', color: const Color(0xffff6b93)),
                  SizedBox(width: _ui(context, 7)),
                  _metric(context, Icons.card_giftcard, '${stream.paidCoins}', color: const Color(0xffffcc32)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, IconData icon, String text, {Color color = const Color(0xffcbd5e1)}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: _ui(context, 12)),
      SizedBox(width: _ui(context, 2)),
      Text(text, style: TextStyle(color: Colors.white, fontSize: _font(context, 9), fontWeight: FontWeight.w900)),
    ]);
  }

  Future<void> _showBroadcastSettings() async {
    final result = await showBroadcastSettingsSheet(
      context,
      categories: liveController.categories.toList(),
    );
    if (result == null || !mounted) return;
    _toast('Going live: ${result.title}');
  }

  void _showAnalytics() {
    int selectedIndex = 1;
    final tabs = ['Today', '7D', '30D', '90D'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (innerContext, setSheetState) {
          return FractionallySizedBox(
            heightFactor: 0.92,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(innerContext, 20))),
              child: Material(
                color: const Color(0xff0b3150),
                child: Column(children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(_ui(innerContext, 16), _ui(innerContext, 15), _ui(innerContext, 12), _ui(innerContext, 14)),
                    color: const Color(0xff082b47),
                    child: Row(children: [
                      Icon(Icons.bar_chart_rounded, color: const Color(0xffffdf45), size: _ui(innerContext, 24)),
                      SizedBox(width: _ui(innerContext, 10)),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Analytics', style: TextStyle(color: Colors.white, fontSize: _font(innerContext, 19), fontWeight: FontWeight.w900)),
                        Text('Last 7 days · All sessions', style: TextStyle(color: const Color(0xffa8bed3), fontSize: _font(innerContext, 11), fontWeight: FontWeight.w700)),
                      ])),
                      TextButton.icon(
                        onPressed: () => _toast('Analytics export prepared.'),
                        style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.12), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_ui(innerContext, 10)))),
                        icon: Icon(Icons.file_download_outlined, size: _ui(innerContext, 15)),
                        label: Text('Export', style: TextStyle(fontSize: _font(innerContext, 12), fontWeight: FontWeight.w900)),
                      ),
                      IconButton(onPressed: () => Navigator.of(innerContext).pop(), icon: const Icon(Icons.close, color: Colors.white)),
                    ]),
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(_ui(innerContext, 16)),
                      children: [
                        Row(children: List.generate(tabs.length, (i) {
                          final selected = selectedIndex == i;
                          return Padding(
                            padding: EdgeInsets.only(right: _ui(innerContext, 8)),
                            child: GestureDetector(
                              onTap: () => setSheetState(() => selectedIndex = i),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: _ui(innerContext, 15), vertical: _ui(innerContext, 9)),
                                decoration: BoxDecoration(color: selected ? const Color(0xffffdf45) : const Color(0xff173e60), borderRadius: BorderRadius.circular(_ui(innerContext, 16))),
                                child: Text(tabs[i], style: TextStyle(color: selected ? const Color(0xff071326) : Colors.white, fontSize: _font(innerContext, 13), fontWeight: FontWeight.w900)),
                              ),
                            ),
                          );
                        })),
                        SizedBox(height: _ui(innerContext, 16)),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: _ui(innerContext, 12),
                          crossAxisSpacing: _ui(innerContext, 12),
                          childAspectRatio: 1.45,
                          children: [
                            _darkMetric(innerContext, 'Live Sessions', '12', 'ended in range', Icons.live_tv_outlined),
                            _darkMetric(innerContext, 'Unique Viewers', '3.1k', 'new + returning', Icons.people_alt_outlined),
                            _darkMetric(innerContext, 'PCU / ACU', '98 / 41', 'peak / avg concurrent', Icons.monitor_heart_outlined),
                            _darkMetric(innerContext, 'Watch Time', '214 hrs', 'avg 4m / viewer', Icons.access_time),
                            _darkMetric(innerContext, 'Engagement', '7.4%', '812 chats · 1.2k reacts', Icons.chat_bubble_outline),
                            _darkMetric(innerContext, 'Revenue', '12.8k', 'coins · \$127.50 cash', Icons.link),
                          ],
                        ),
                        SizedBox(height: _ui(innerContext, 12)),
                        _chartCard(innerContext),
                        SizedBox(height: _ui(innerContext, 12)),
                        _transferCard(innerContext),
                        SizedBox(height: _ui(innerContext, 12)),
                        _splitCard(innerContext),
                        SizedBox(height: _ui(innerContext, 12)),
                        _topSessionsCard(innerContext),
                        SizedBox(height: _ui(innerContext, 8)),
                        Center(child: Text('All data is synchronized in real-time.', style: TextStyle(color: const Color(0xff7895ad), fontSize: _font(innerContext, 11), fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _darkMetric(BuildContext context, String label, String value, String sub, IconData icon) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(color: const Color(0xff082b47), borderRadius: BorderRadius.circular(_ui(context, 14))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff87a1b9), fontSize: _font(context, 9), fontWeight: FontWeight.w900))), Icon(icon, color: const Color(0xff87a1b9), size: _ui(context, 16))]),
        const Spacer(),
        Text(value, style: TextStyle(color: Colors.white, fontSize: _font(context, 25), fontWeight: FontWeight.w900, height: 1)),
        SizedBox(height: _ui(context, 4)),
        Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff87a1b9), fontSize: _font(context, 10), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _chartCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(color: const Color(0xff082b47), borderRadius: BorderRadius.circular(_ui(context, 16))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Concurrency Over Time', style: TextStyle(color: Colors.white, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
        SizedBox(height: _ui(context, 3)),
        Text('How many viewers were watching (bucketed)', style: TextStyle(color: const Color(0xffa8bed3), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
        SizedBox(height: _ui(context, 12)),
        SizedBox(height: _ui(context, 112), child: CustomPaint(painter: _AnalyticsLinePainter())),
      ]),
    );
  }

  Widget _transferCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(color: const Color(0xff082b47), borderRadius: BorderRadius.circular(_ui(context, 16))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Transfer to Wallet', style: TextStyle(color: Colors.white, fontSize: _font(context, 16), fontWeight: FontWeight.w900))),
          Container(padding: EdgeInsets.symmetric(horizontal: _ui(context, 9), vertical: _ui(context, 4)), decoration: BoxDecoration(color: const Color(0xff334f2d), borderRadius: BorderRadius.circular(20)), child: Text('50/50 SPLIT', style: TextStyle(color: const Color(0xffffdf45), fontSize: _font(context, 9), fontWeight: FontWeight.w900))),
        ]),
        SizedBox(height: _ui(context, 6)),
        Text('You keep 50% of everything collected — LinkUp keeps the other 50%.', style: TextStyle(color: const Color(0xffa8bed3), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
        SizedBox(height: _ui(context, 12)),
        Row(children: [
          Expanded(child: _moneyBox(context, 'COLLECTED', '\$224.00', Colors.white)),
          SizedBox(width: _ui(context, 8)),
          Expanded(child: _moneyBox(context, 'YOUR 50%', '\$112.00', const Color(0xffffdf45))),
          SizedBox(width: _ui(context, 8)),
          Expanded(child: _moneyBox(context, 'LINKUP 50%', '\$112.00', Colors.white)),
        ]),
        SizedBox(height: _ui(context, 12)),
        _transferRow(context, 'Eligible to transfer now', '\$112.00', const Color(0xff20e0aa)),
        _transferRow(context, 'Already transferred', '\$0.00', Colors.white),
        SizedBox(height: _ui(context, 12)),
        GestureDetector(
          onTap: () => _toast('Earnings transferred to wallet.'),
          child: Container(
            height: _ui(context, 44),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xff14c78f), borderRadius: BorderRadius.circular(_ui(context, 12))),
            child: Text('Transfer \$112.00 Now (your 50%)', style: TextStyle(color: Colors.white, fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
          ),
        ),
      ]),
    );
  }

  Widget _moneyBox(BuildContext context, String label, String amount, Color amountColor) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 10)),
      decoration: BoxDecoration(color: const Color(0xff173e60), borderRadius: BorderRadius.circular(_ui(context, 11))),
      child: Column(children: [
        Text(label, style: TextStyle(color: const Color(0xffa8bed3), fontSize: _font(context, 8), fontWeight: FontWeight.w900)),
        SizedBox(height: _ui(context, 4)),
        Text(amount, style: TextStyle(color: amountColor, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _transferRow(BuildContext context, String left, String right, Color color) {
    return Padding(
      padding: EdgeInsets.only(top: _ui(context, 2)),
      child: Row(children: [Expanded(child: Text(left, style: TextStyle(color: const Color(0xffa8bed3), fontSize: _font(context, 11), fontWeight: FontWeight.w600))), Text(right, style: TextStyle(color: color, fontSize: _font(context, 12), fontWeight: FontWeight.w900))]),
    );
  }

  Widget _splitCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(color: const Color(0xff082b47), borderRadius: BorderRadius.circular(_ui(context, 16))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Private Subscription Split (50/50)', style: TextStyle(color: Colors.white, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
        SizedBox(height: _ui(context, 12)),
        Row(children: [
          Expanded(child: _moneyBox(context, 'HOST (50%)', '\$31.88', const Color(0xff20e0aa))),
          SizedBox(width: _ui(context, 8)),
          Expanded(child: _moneyBox(context, 'PARTNER (50%)', '\$31.88', const Color(0xff33b6ff))),
        ]),
      ]),
    );
  }

  Widget _topSessionsCard(BuildContext context) {
    final rows = [
      ['Carnival Warmup', 'Carnival Mixers · 👥4.2k · 🎁18', '\$182'],
      ['Caribbean Talk', 'News, Sports · 👥1.8k · 🎁7', '\$64'],
      ['Book Launch', 'Education · 👥140 · 🎁7', '\$31'],
    ];
    return Container(
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(color: const Color(0xff082b47), borderRadius: BorderRadius.circular(_ui(context, 16))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Top Sessions', style: TextStyle(color: Colors.white, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
        SizedBox(height: _ui(context, 8)),
        for (final row in rows)
          Container(
            padding: EdgeInsets.symmetric(vertical: _ui(context, 9)),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06)))),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(row[0], style: TextStyle(color: Colors.white, fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
                SizedBox(height: _ui(context, 3)),
                Text(row[1], style: TextStyle(color: const Color(0xff87a1b9), fontSize: _font(context, 10), fontWeight: FontWeight.w600)),
              ])),
              Text(row[2], style: TextStyle(color: const Color(0xff20e0aa), fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
            ]),
          ),
      ]),
    );
  }

  void _showLiveRoom(LiveStream stream) {
    final TextEditingController messageController = TextEditingController();
    final List<_LiveMessage> messages = List<_LiveMessage>.from(_LiveMessage.seed());
    bool followed = false;
    bool muted = true;
    int coins = 1400;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Live room',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(builder: (innerContext, setRoomState) {
          void sendMessage([String? forced]) {
            final text = (forced ?? messageController.text).trim();
            if (text.isEmpty) return;
            setRoomState(() {
              messages.add(_LiveMessage(_currentFirstName, text, highlight: true));
              messageController.clear();
            });
          }

          final safeTop = MediaQuery.of(innerContext).padding.top;
          final safeBottom = MediaQuery.of(innerContext).padding.bottom;

          return Scaffold(
            backgroundColor: Colors.black,
            resizeToAvoidBottomInset: true,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        stream.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xff05080f)),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.30),
                              Colors.black.withOpacity(0.03),
                              Colors.black.withOpacity(0.12),
                              Colors.black.withOpacity(0.86),
                            ],
                            stops: const [0.0, 0.28, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: safeTop + _ui(innerContext, 10),
                      left: _ui(innerContext, 12),
                      right: _ui(innerContext, 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: _ui(innerContext, 17), backgroundImage: NetworkImage(stream.user?.avatar ?? '')),
                              SizedBox(width: _ui(innerContext, 8)),
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '@${stream.user?.firstName ?? 'User'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white, fontSize: _font(innerContext, 12), fontWeight: FontWeight.w900, height: 1),
                                      ),
                                    ),
                                    SizedBox(width: _ui(innerContext, 7)),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => setRoomState(() => followed = !followed),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: _ui(innerContext, 11), vertical: _ui(innerContext, 6)),
                                        decoration: BoxDecoration(
                                          color: followed ? Colors.white.withOpacity(0.18) : const Color(0xffff315f),
                                          borderRadius: BorderRadius.circular(_ui(innerContext, 16)),
                                        ),
                                        child: Text(followed ? 'Following' : '+ Follow', style: TextStyle(color: Colors.white, fontSize: _font(innerContext, 10), fontWeight: FontWeight.w900)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _viewerStack(innerContext),
                              SizedBox(width: _ui(innerContext, 8)),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _showHostSheet(innerContext, stream),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: _ui(innerContext, 11), vertical: _ui(innerContext, 7)),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.48), borderRadius: BorderRadius.circular(_ui(innerContext, 18))),
                                  child: Text('${stream.likeCount}', style: TextStyle(color: Colors.white, fontSize: _font(innerContext, 11), fontWeight: FontWeight.w900)),
                                ),
                              ),
                              SizedBox(width: _ui(innerContext, 8)),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => Navigator.of(dialogContext).pop(),
                                child: _liveCircle(innerContext, Icons.close),
                              ),
                            ],
                          ),
                          SizedBox(height: _ui(innerContext, 9)),
                          Row(
                            children: [
                              _webLivePill(innerContext, '🔥 Top Live', const Color(0xff0c1724)),
                              SizedBox(width: _ui(innerContext, 7)),
                              Expanded(child: _webLivePill(innerContext, '🌎 ${stream.broadcastType}', const Color(0xff513747))),
                              SizedBox(width: _ui(innerContext, 7)),
                              _webLivePill(innerContext, '🔗 ${stream.paidCoins} · \$${stream.subscriptionRate}', const Color(0xff0d2330), greenAmount: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: _ui(innerContext, 14),
                      top: safeTop + _ui(innerContext, 92),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setRoomState(() => muted = !muted),
                        child: _liveCircle(innerContext, muted ? Icons.volume_off : Icons.volume_up),
                      ),
                    ),
                    Positioned(
                      left: _ui(innerContext, 10),
                      right: _ui(innerContext, 118),
                      bottom: safeBottom + _ui(innerContext, 84),
                      child: _LiveCommentStream(
                        externalMessages: messages,
                        ui: _ui,
                        font: _font,
                      ),
                    ),
                    Positioned(
                      left: _ui(innerContext, 12),
                      right: _ui(innerContext, 12),
                      bottom: safeBottom + _ui(innerContext, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: _ui(innerContext, 45),
                              padding: EdgeInsets.symmetric(horizontal: _ui(innerContext, 15)),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.54),
                                borderRadius: BorderRadius.circular(_ui(innerContext, 24)),
                                border: Border.all(color: Colors.white.withOpacity(0.10)),
                              ),
                              child: TextField(
                                controller: messageController,
                                style: TextStyle(color: Colors.white, fontSize: _font(innerContext, 13), fontWeight: FontWeight.w700),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => sendMessage(),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.only(top: _ui(innerContext, 13)),
                                  border: InputBorder.none,
                                  hintText: 'Say something...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: _font(innerContext, 13), fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: _ui(innerContext, 8)),
                          GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => sendMessage('😍'), child: _bottomLiveAction(innerContext, Icons.emoji_emotions_outlined)),
                          SizedBox(width: _ui(innerContext, 8)),
                          GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _showHostSheet(innerContext, stream), child: _bottomLiveAction(innerContext, Icons.group_add_outlined)),
                          SizedBox(width: _ui(innerContext, 8)),
                          GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => sendMessage('sent a rose 🌹'), child: _bottomLiveAction(innerContext, Icons.local_florist, gradient: const [Color(0xffe11d48), Color(0xffff315f)])),
                          SizedBox(width: _ui(innerContext, 8)),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _showLiveGiftSheet(innerContext, stream, coins, (spent) {
                              setRoomState(() {
                                coins = (coins - spent).clamp(0, 999999).toInt();
                                messages.add(_LiveMessage(_currentFirstName, 'sent a gift 🎁', highlight: true));
                              });
                            }),
                            child: _bottomLiveAction(innerContext, Icons.card_giftcard, gradient: const [Color(0xffff315f), Color(0xffff9c32)]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    ).whenComplete(() => messageController.dispose());
  }

  Widget _viewerStack(BuildContext context) {
    return const _LiveViewerStack(
      avatars: [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=90&q=70',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=90&q=70',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=90&q=70',
      ],
    );
  }

  Widget _webLivePill(BuildContext context, String text, Color color, {bool greenAmount = false}) {
    final dollarIndex = text.indexOf('\$');
    return Container(
      height: _ui(context, 28),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 10)),
      decoration: BoxDecoration(color: color.withOpacity(0.88), borderRadius: BorderRadius.circular(_ui(context, 18))),
      child: greenAmount && dollarIndex > 0
          ? RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(text: text.substring(0, dollarIndex), style: TextStyle(color: const Color(0xffffdf45), fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
                  TextSpan(text: text.substring(dollarIndex), style: TextStyle(color: const Color(0xff20e0aa), fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
                ],
              ),
            )
          : Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: text.contains('Afrobeats') ? const Color(0xffffdf45) : Colors.white, fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
    );
  }

  Widget _staticLiveComments(BuildContext context, List<_LiveMessage> messages) {
    final visible = messages.length <= 4 ? messages : messages.sublist(messages.length - 4);
    return IgnorePointer(
      ignoring: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation), child: child),
        ),
        child: Column(
          key: ValueKey<int>(messages.length),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: visible.map((msg) {
            return Padding(
              padding: EdgeInsets.only(bottom: _ui(context, 8)),
              child: RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(text: '${msg.name} ', style: TextStyle(color: msg.highlight ? const Color(0xffffdf45) : Colors.white, fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
                    TextSpan(text: msg.text, style: TextStyle(color: Colors.white, fontSize: _font(context, 13), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _liveTopPill(BuildContext context, IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 10), vertical: _ui(context, 7)),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.42), borderRadius: BorderRadius.circular(18)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: _ui(context, 14)), SizedBox(width: _ui(context, 4)), Text(text, style: TextStyle(color: Colors.white, fontSize: _font(context, 11), fontWeight: FontWeight.w900))]),
    );
  }

  Widget _liveCircle(BuildContext context, IconData icon) {
    return Container(width: _ui(context, 34), height: _ui(context, 34), decoration: BoxDecoration(color: Colors.black.withOpacity(0.42), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: _ui(context, 20)));
  }

  Widget _badge(BuildContext context, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 11), vertical: _ui(context, 6)),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(20)),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: label.contains('\$') ? const Color(0xff20e0aa) : Colors.white, fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
    );
  }

  Widget _bottomLiveAction(BuildContext context, IconData icon, {List<Color>? gradient}) {
    return Container(
      width: _ui(context, 43),
      height: _ui(context, 43),
      decoration: BoxDecoration(
        color: gradient == null ? Colors.black.withOpacity(0.52) : null,
        gradient: gradient == null ? null : LinearGradient(colors: gradient),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: _ui(context, 22)),
    );
  }

  void _showHostSheet(BuildContext context, LiveStream stream) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(_ui(sheetContext, 16), _ui(sheetContext, 16), _ui(sheetContext, 16), _ui(sheetContext, 24)),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(sheetContext, 24)))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('Viewers & Hosts', style: TextStyle(color: const Color(0xff071326), fontSize: _font(sheetContext, 20), fontWeight: FontWeight.w900)), const Spacer(), IconButton(onPressed: () => Navigator.of(sheetContext).pop(), icon: const Icon(Icons.close))]),
          _viewerRow(sheetContext, stream.user?.avatar ?? '', '@${stream.user?.firstName ?? 'User'}', 'Host · live now', true),
          _viewerRow(sheetContext, 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=70', 'Renee', 'Tuned in from Nassau 🇧🇸', false),
          _viewerRow(sheetContext, 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=70', 'Dr. Cassius Stuart', 'joined', false),
          _viewerRow(sheetContext, 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&q=70', 'Amara', 'love this', false),
        ]),
      ),
    );
  }

  Widget _viewerRow(BuildContext context, String avatar, String name, String sub, bool host) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: _ui(context, 10)),
      child: Row(children: [
        CircleAvatar(radius: _ui(context, 20), backgroundImage: NetworkImage(avatar)),
        SizedBox(width: _ui(context, 12)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: TextStyle(color: const Color(0xff071326), fontSize: _font(context, 14), fontWeight: FontWeight.w900)), Text(sub, style: TextStyle(color: const Color(0xff65748a), fontSize: _font(context, 11), fontWeight: FontWeight.w600))])),
        if (host) Container(padding: EdgeInsets.symmetric(horizontal: _ui(context, 10), vertical: _ui(context, 5)), decoration: BoxDecoration(color: const Color(0xffffedf5), borderRadius: BorderRadius.circular(20)), child: Text('HOST', style: TextStyle(color: const Color(0xffec4899), fontSize: _font(context, 10), fontWeight: FontWeight.w900))),
      ]),
    );
  }

  void _showLiveGiftSheet(BuildContext context, LiveStream stream, int coins, ValueChanged<int> onGift) {
    final gifts = _GiftItem.seed();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.74,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(sheetContext, 24))),
          child: Material(
            color: Colors.white,
            child: Column(children: [
              Container(
                padding: EdgeInsets.fromLTRB(_ui(sheetContext, 16), _ui(sheetContext, 15), _ui(sheetContext, 12), _ui(sheetContext, 13)),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xffff812f), Color(0xffec4899)])),
                child: Row(children: [
                  Icon(Icons.card_giftcard, color: Colors.white, size: _ui(sheetContext, 22)),
                  SizedBox(width: _ui(sheetContext, 9)),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Send a Live Gift', style: TextStyle(color: Colors.white, fontSize: _font(sheetContext, 20), fontWeight: FontWeight.w900)),
                    Text('Show @${stream.user?.firstName ?? 'User'} love · balance 🔗 $coins', style: TextStyle(color: Colors.white, fontSize: _font(sheetContext, 12), fontWeight: FontWeight.w700)),
                  ])),
                  IconButton(onPressed: () => Navigator.of(sheetContext).pop(), icon: const Icon(Icons.close, color: Colors.white)),
                ]),
              ),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(_ui(sheetContext, 14)),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: _ui(sheetContext, 10), crossAxisSpacing: _ui(sheetContext, 10), childAspectRatio: 0.88),
                  itemCount: gifts.length,
                  itemBuilder: (_, index) {
                    final gift = gifts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        onGift(gift.coins);
                      },
                      child: Container(
                        padding: EdgeInsets.all(_ui(sheetContext, 8)),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(sheetContext, 14)), border: Border.all(color: const Color(0xffe6edf7)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(gift.emoji, style: TextStyle(fontSize: _font(sheetContext, 25))),
                          SizedBox(height: _ui(sheetContext, 5)),
                          Text(gift.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff071326), fontSize: _font(sheetContext, 11), fontWeight: FontWeight.w900)),
                          SizedBox(height: _ui(sheetContext, 5)),
                          Container(padding: EdgeInsets.symmetric(horizontal: _ui(sheetContext, 8), vertical: _ui(sheetContext, 4)), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xffff812f), Color(0xffec4899)]), borderRadius: BorderRadius.circular(20)), child: Text('🔗 ${gift.coins}', style: TextStyle(color: Colors.white, fontSize: _font(sheetContext, 10), fontWeight: FontWeight.w900))),
                          SizedBox(height: _ui(sheetContext, 3)),
                          Text('≈ \$${gift.cash}', style: TextStyle(color: const Color(0xff059669), fontSize: _font(sheetContext, 10), fontWeight: FontWeight.w900)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final items = [
      [Icons.home_outlined, 'Home', false],
      [Icons.image_outlined, 'Vibes', false],
      [Icons.restaurant_outlined, 'Eats', false],
      [Icons.sensors, 'Live', true],
      [Icons.favorite_border, 'LinkUp', false],
    ];
    return Container(
      height: _ui(context, 64) + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(left: _ui(context, 12), right: _ui(context, 12), bottom: MediaQuery.of(context).padding.bottom),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final selected = item[2] as bool;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(_ui(context, 18)),
              onTap: () {
                if (item[1] == 'Home') Get.off(() => HomePage());
                if (item[1] == 'Vibes') Get.off(() => const VibesPage());
                if (item[1] == 'Eats') Get.off(() => const EatsPage());
                if (item[1] == 'LinkUp') Get.off(() => ChatHomePage());
              },
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: selected ? _ui(context, 30) : _ui(context, 26),
                  height: selected ? _ui(context, 30) : _ui(context, 26),
                  decoration: BoxDecoration(color: selected ? const Color(0xff2d98e5) : Colors.transparent, borderRadius: BorderRadius.circular(_ui(context, 11))),
                  child: Icon(item[0] as IconData, color: selected ? Colors.white : const Color(0xff69768a), size: _ui(context, 24)),
                ),
                SizedBox(height: _ui(context, 3)),
                Text(item[1] as String, maxLines: 1, style: TextStyle(color: selected ? const Color(0xff2589df) : const Color(0xff627085), fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}


class _LiveCommentStream extends StatefulWidget {
  final List<_LiveMessage> externalMessages;
  final double Function(BuildContext context, double value) ui;
  final double Function(BuildContext context, double value) font;

  const _LiveCommentStream({
    required this.externalMessages,
    required this.ui,
    required this.font,
  });

  @override
  State<_LiveCommentStream> createState() => _LiveCommentStreamState();
}

class _LiveCommentEntry {
  final int id;
  final _LiveMessage message;

  const _LiveCommentEntry(this.id, this.message);
}

class _LiveCommentStreamState extends State<_LiveCommentStream> {
  final List<_LiveCommentEntry> _entries = <_LiveCommentEntry>[];
  Timer? _timer;
  int _lastExternalLength = 0;
  int _autoIndex = 0;
  int _nextEntryId = 0;

  static List<_LiveMessage> get _autoFeed => <_LiveMessage>[
    const _LiveMessage('Renee', 'Tuned in from Nassau 🇧🇸', highlight: true),
    _LiveMessage(LinkUpCurrentUser.fullName(), 'joined', highlight: true),
    const _LiveMessage('Amara', 'love this', highlight: true),
    const _LiveMessage('caribe', 'Welcome in everybody!', highlight: false),
    const _LiveMessage('Renee', 'Big island energy tonight 🔥', highlight: true),
    const _LiveMessage('Malik', 'this mix is sweet', highlight: false),
    const _LiveMessage('Aaliyah', 'sent a gift 🎁', highlight: true),
  ];

  @override
  void initState() {
    super.initState();
    _appendAll(widget.externalMessages);
    _lastExternalLength = widget.externalMessages.length;
    _timer = Timer.periodic(const Duration(milliseconds: 2100), (_) {
      if (!mounted) return;
      setState(() {
        _append(_autoFeed[_autoIndex % _autoFeed.length]);
        _autoIndex++;
        _trimEntries();
      });
    });
  }

  void _append(_LiveMessage message) {
    _entries.add(_LiveCommentEntry(_nextEntryId++, message));
  }

  void _appendAll(Iterable<_LiveMessage> messages) {
    for (final message in messages) {
      _append(message);
    }
  }

  @override
  void didUpdateWidget(covariant _LiveCommentStream oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalMessages.length > _lastExternalLength) {
      setState(() {
        _appendAll(widget.externalMessages.sublist(_lastExternalLength));
        _lastExternalLength = widget.externalMessages.length;
        _trimEntries();
      });
    } else if (widget.externalMessages.length < _lastExternalLength) {
      _lastExternalLength = widget.externalMessages.length;
    }
  }

  void _trimEntries() {
    while (_entries.length > 22) {
      _entries.removeAt(0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _entries.length <= 6 ? _entries : _entries.sublist(_entries.length - 6);
    final rowStep = widget.ui(context, 24);

    return IgnorePointer(
      ignoring: true,
      child: SizedBox(
        height: widget.ui(context, 164),
        width: double.infinity,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.bottomLeft,
            children: List.generate(visible.length, (index) {
              final entry = visible[index];
              final message = entry.message;
              final slotsFromBottom = visible.length - 1 - index;
              final isTopFading = index == 0 && _entries.length > visible.length;

              return AnimatedPositioned(
                key: ValueKey<int>(entry.id),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                bottom: slotsFromBottom * rowStep,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: (isTopFading ? 0.58 : 1.0) * value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * widget.ui(context, 10)),
                        child: child,
                      ),
                    );
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: widget.ui(context, 270)),
                      child: RichText(
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${message.name} ',
                              style: TextStyle(
                                color: message.highlight ? const Color(0xffffdf45) : Colors.white,
                                fontSize: widget.font(context, 13.8),
                                fontWeight: FontWeight.w900,
                                height: 1.18,
                                shadows: const [Shadow(color: Colors.black87, blurRadius: 7)],
                              ),
                            ),
                            TextSpan(
                              text: message.text,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.font(context, 13.8),
                                fontWeight: FontWeight.w800,
                                height: 1.18,
                                shadows: const [Shadow(color: Colors.black87, blurRadius: 7)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}



class _LiveViewerStack extends StatefulWidget {
  final List<String> avatars;
  const _LiveViewerStack({required this.avatars});

  @override
  State<_LiveViewerStack> createState() => _LiveViewerStackState();
}

class _LiveViewerStackState extends State<_LiveViewerStack> {
  Timer? _timer;
  int _shift = 0;

  double _scale(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || widget.avatars.isEmpty) return;
      setState(() => _shift = (_shift + 1) % widget.avatars.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatars = widget.avatars;
    return SizedBox(
      width: _scale(context, 54),
      height: _scale(context, 26),
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(avatars.length, (index) {
          final visualIndex = (index + _shift) % avatars.length;
          return AnimatedPositioned(
            key: ValueKey<String>('live-viewer-${avatars[index]}'),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            left: _scale(context, visualIndex * 14.0),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 320),
              scale: visualIndex == avatars.length - 1 ? 1.05 : 1.0,
              child: CircleAvatar(
                radius: _scale(context, 13),
                backgroundColor: Colors.white.withOpacity(0.75),
                child: CircleAvatar(radius: _scale(context, 11.5), backgroundImage: NetworkImage(avatars[index])),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AnalyticsLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffffdf45)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final values = <double>[42, 58, 36, 12, 43, 75, 22, 48, 45, 10, 55, 35, 64, 19];
    final max = 80.0;
    final min = 0.0;
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height - ((values[i] - min) / (max - min) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LiveMessage {
  final String name;
  final String text;
  final bool highlight;

  const _LiveMessage(this.name, this.text, {this.highlight = false});

  static List<_LiveMessage> seed() => [
        const _LiveMessage('Renee', 'Tuned in from Nassau 🇧🇸', highlight: true),
        _LiveMessage(LinkUpCurrentUser.fullName(), 'joined', highlight: true),
        const _LiveMessage('Amara', 'love this', highlight: true),
        const _LiveMessage('caribe', 'Welcome in everybody!', highlight: false),
      ];
}

class _GiftItem {
  final String emoji;
  final String title;
  final int coins;
  final String cash;

  const _GiftItem(this.emoji, this.title, this.coins, this.cash);

  static List<_GiftItem> seed() => const [
        _GiftItem('👍', 'Likkle Up', 10, '0.10'),
        _GiftItem('🙌', 'Big Up', 25, '0.25'),
        _GiftItem('👊', 'Respect', 50, '0.50'),
        _GiftItem('🙏', 'Bless Up', 75, '0.75'),
        _GiftItem('💯', 'Nuff Respect', 100, '1.00'),
        _GiftItem('🕊️', 'Blessings', 150, '1.50'),
        _GiftItem('❤️', 'One Love', 200, '2.00'),
        _GiftItem('😇', 'God Bless You', 250, '2.50'),
        _GiftItem('💞', 'Love & Respect', 350, '3.50'),
        _GiftItem('🔥', 'Big Tings', 500, '5.00'),
        _GiftItem('👑', 'Caribbean Crown', 1000, '10.00'),
      ];
}
