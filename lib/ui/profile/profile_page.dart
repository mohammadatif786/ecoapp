import 'package:flutter/material.dart';
import '../../widgets/linkup_current_user.dart';
import '../../widgets/custom_qr_code_widget.dart';
import 'package:link_up/helper/router/route_path.dart';
import 'package:link_up/ui/chat_home_page.dart';
import 'package:link_up/ui/eats_page.dart';
import 'package:link_up/ui/home_page.dart';
import 'package:link_up/ui/live_page.dart';
import 'package:link_up/ui/market_page.dart';
import 'package:link_up/ui/news_page.dart';
import 'package:link_up/ui/notification_page.dart';
import 'package:link_up/ui/setting/setting_page.dart';
import 'package:link_up/ui/vibes_page.dart';
import 'package:link_up/ui/wallet_page.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/home_controller.dart';
import 'package:link_up/events/AllEvents.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final homeController = Get.find<HomeController>(tag: HomeController().toString());
  int _mainTab = 0;
  int _subTab = 0;
  int _ticketTab = 0;
  int _marketTab = 0;
  int _eatsTab = 0;
  int _newsTab = 0;
  int _matchTab = 0;
  int _giftTab = 0;
  int _coinsTab = 0;
  int _billTab = 0;
  int _eventOrganizerTab = 0;
  int _subTabSubscription = 0;
  int _walletTab = 0;

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) => _ui(context, value);

  String get _currentFullName => LinkUpCurrentUser.fullName();
  String get _currentFirstName => LinkUpCurrentUser.firstName();
  String get _currentEmail => LinkUpCurrentUser.email(fallback: '');
  ImageProvider get _currentAvatar => LinkUpCurrentUser.avatarProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeaf4fc),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(context),
            _locationBar(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  _ui(context, 10),
                  _ui(context, 12),
                  _ui(context, 10),
                  _ui(context, 18),
                ),
                children: [
                  _profileHero(context),
                  SizedBox(height: _ui(context, 10)),
                  _mainTabs(context),
                  SizedBox(height: _ui(context, 9)),
                  _content(context),
                ],
              ),
            ),
            _bottomNav(context),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      height: _ui(context, 58),
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 15)),
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
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletPage())),
            child: Container(
              height: _ui(context, 30),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 13)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(_ui(context, 24)),
              ),
              child: Row(
                children: [
                  Icon(Icons.monetization_on_outlined, color: Colors.white, size: _ui(context, 16)),
                  SizedBox(width: _ui(context, 6)),
                  Text('37,005', style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
                ],
              ),
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
          LinkUpCurrentUserAvatar(
            radius: _ui(context, 17),
            innerRadius: _ui(context, 15),
          ),
        ],
      ),
    );
  }

  Widget _locationBar(BuildContext context) {
    return Container(
      height: _ui(context, 30),
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 15)),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, color: const Color(0xff2f9bef), size: _ui(context, 15)),
          SizedBox(width: _ui(context, 7)),
          Expanded(
            child: Text('The Valley, Anguilla 🇦🇮', style: TextStyle(color: const Color(0xff26364d), fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
          ),
          Text('Change', style: TextStyle(color: const Color(0xff168eea), fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _profileHero(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 15)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_ui(context, 19)),
        gradient: const LinearGradient(
          colors: [Color(0xff2f9bef), Color(0xff4b48e8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xff2563eb).withOpacity(0.20), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _ui(context, 64),
                height: _ui(context, 64),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_ui(context, 15)),
                  border: Border.all(color: Colors.white, width: 3),
                  image: DecorationImage(image: _currentAvatar, fit: BoxFit.cover),
                ),
              ),
              SizedBox(width: _ui(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentFullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: _font(context, 23), fontWeight: FontWeight.w900, height: 1.0)),
                    SizedBox(height: _ui(context, 7)),
                    Wrap(
                      spacing: _ui(context, 5),
                      runSpacing: _ui(context, 5),
                      children: [
                        _HeroMiniChip(text: 'ID: @${_currentFirstName.toLowerCase()}'),
                        const _HeroMiniChip(text: 'Verify ID ›'),
                        const _HeroMiniChip(text: '🎟️ Organizer'),
                        const _HeroMiniChip(text: '📍 Nassau, BS'),
                        const _HeroMiniChip(text: '📅 Joined Sep 2025'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: _ui(context, 15)),
          Row(
            children: [
              Expanded(
                child: _heroButton(
                  context,
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  bg: const Color(0xffffdf3e),
                  fg: Colors.black,
                  onTap: () => _showEditProfile(context),
                ),
              ),
              SizedBox(width: _ui(context, 8)),
              Expanded(
                child: _heroButton(
                  context,
                  label: 'My QR',
                  icon: Icons.qr_code_2_rounded,
                  bg: Colors.white,
                  fg: Colors.black,
                  onTap: () => _showMyQr(context),
                ),
              ),
              SizedBox(width: _ui(context, 8)),
              GestureDetector(
                onTap: () => showLinkUpSettingsSheet(context),
                child: Container(
                  width: _ui(context, 40),
                  height: _ui(context, 40),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(_ui(context, 12))),
                  child: Icon(Icons.settings_outlined, color: Colors.white, size: _ui(context, 21)),
                ),
              ),
            ],
          ),
          SizedBox(height: _ui(context, 18)),
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Colors.white, size: _ui(context, 15)),
              SizedBox(width: _ui(context, 5)),
              Text('Dashboard Snapshot', style: TextStyle(color: Colors.white, fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
            ],
          ),
          SizedBox(height: _ui(context, 9)),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: _ui(context, 9),
            mainAxisSpacing: _ui(context, 9),
            childAspectRatio: 1.92,
            children: const [
              _SnapshotTile(label: 'Tickets', value: '6', sub: '0 cancelled', subColor: Color(0xffff4b75)),
              _SnapshotTile(label: 'Marketplace', value: '0', sub: 'items purchased'),
              _SnapshotTile(label: 'Matches', value: '3', sub: '3 likes'),
              _SnapshotTile(label: 'Gifts', value: '−3,665', sub: '3,200 in · 6,865 out', subColor: Color(0xffff4b75), avatar: true),
            ],
          ),
          SizedBox(height: _ui(context, 12)),
          Wrap(
            spacing: _ui(context, 6),
            runSpacing: _ui(context, 6),
            children: ['💼 Marketing', 'Gender: female', '✨ Status: active'].map((e) => _statusPill(context, e)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _heroButton(BuildContext context, {required String label, required IconData icon, required Color bg, required Color fg, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _ui(context, 40),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(_ui(context, 12))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: _ui(context, 17), color: fg),
            SizedBox(width: _ui(context, 6)),
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(BuildContext context, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 9), vertical: _ui(context, 5)),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(_ui(context, 14))),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: _font(context, 10.5), fontWeight: FontWeight.w900)),
    );
  }

  Widget _mainTabs(BuildContext context) {
    final tabs = const ['About', 'Tickets & Events', 'Marketplace', 'Eats', 'Vibes', 'News', 'Matches', 'Gifts', 'LinkUp Live', 'Subscription', 'LinkUp Coins', 'Bill Payment', 'Event Organizer', 'Wallet'];
    return SizedBox(
      height: _ui(context, 43),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => SizedBox(width: _ui(context, 7)),
        itemBuilder: (_, index) {
          final active = _mainTab == index;
          return GestureDetector(
            onTap: () => setState(() => _mainTab = index),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 15)),
              decoration: BoxDecoration(
                color: active ? const Color(0xff2f9bef) : Colors.white,
                borderRadius: BorderRadius.circular(_ui(context, 21)),
                border: Border.all(color: active ? const Color(0xff2f9bef) : const Color(0xffdfe9f5)),
              ),
              child: Text(tabs[index], style: TextStyle(color: active ? Colors.white : const Color(0xff435168), fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
            ),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (_mainTab == 1) return _ticketsContent(context);
    if (_mainTab == 2) return _marketplaceContent(context);
    if (_mainTab == 3) return _eatsContent(context);
    if (_mainTab == 4) return _vibesContent(context);
    if (_mainTab == 5) return _newsContent(context);
    if (_mainTab == 6) return _matchesContent(context);
    if (_mainTab == 7) return _giftsContent(context);
    if (_mainTab == 8) return _liveContent(context);
    if (_mainTab == 9) return _subscriptionContent(context);
    if (_mainTab == 10) return _coinsContent(context);
    if (_mainTab == 11) return _billPaymentContent(context);
    if (_mainTab == 12) return _eventOrganizerContent(context);
    if (_mainTab == 13) return _walletContent(context);
    return _aboutContent(context);
  }

  Widget _billPaymentContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _whiteCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long_outlined, color: const Color(0xfff59e0b), size: _ui(context, 18)),
                            const SizedBox(width: 8),
                            Text('Bill Payment', style: TextStyle(color: Colors.black, fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Text('Bills paid history', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Text('3', style: TextStyle(color: const Color(0xfff59e0b), fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
                ],
              ),
              const SizedBox(height: 16),
              Text('TOTAL PAID', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('\$285', style: TextStyle(color: Colors.black, fontSize: _font(context, 32), fontWeight: FontWeight.w900, height: 1.0)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(context, 'Bills Paid', 'Company • account # • amount'),
        const SizedBox(height: 12),
        _billItem(context, 'BTC (Bahamas Telecommunications)', 'BILL-9901', 'ACC-2201933', 'Dec 12, 2025', '\$89.50'),
        _billItem(context, 'BEC (Bahamas Electric)', 'BILL-9902', 'ACC-1088331', 'Dec 8, 2025', '\$143.20'),
        _billItem(context, 'WSC (Water & Sewerage)', 'BILL-9903', 'ACC-2307721', 'Nov 29, 2025', '\$52.00'),
        const SizedBox(height: 12),
        _payBillCard(context),
      ],
    );
  }

  Widget _eventOrganizerContent(BuildContext context) {
    final tabs = const ['📈 Overview', '🗒 Events', '💳 Payouts'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inlineTabs(context, tabs, _eventOrganizerTab, (v) => setState(() => _eventOrganizerTab = v)),
        const SizedBox(height: 18),
        if (_eventOrganizerTab == 0) _organizerOverview(context),
        if (_eventOrganizerTab == 1) _organizerEvents(context),
        if (_eventOrganizerTab == 2) _organizerPayouts(context),
      ],
    );
  }

  Widget _organizerOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.event_note_rounded, color: Colors.black, size: _ui(context, 18)),
                const SizedBox(width: 8),
                Text('Event Organizer', style: TextStyle(color: Colors.black, fontSize: _font(context, 17), fontWeight: FontWeight.w900)),
              ],
            ),
            Text('Organizer', style: TextStyle(color: const Color(0xff2f9bef), fontWeight: FontWeight.w900, fontSize: _font(context, 12))),
          ],
        ),
        Text('Events, sales, payouts, refunds', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: _ui(context, 10),
          mainAxisSpacing: _ui(context, 10),
          childAspectRatio: 1.6,
          children: [
            _organizerStatTile(context, 'Total Events', '16'),
            _organizerStatTile(context, 'Gross Sales', '\$3,893.28'),
            _organizerStatTile(context, 'Platform Fees', '\$149.06'),
            _organizerStatTile(context, 'Net Earnings', '\$4,042.34'),
            _organizerStatTile(context, 'Live Events', '13', 'currently active'),
            _organizerStatTile(context, 'Total Tickets', '16', 'tickets sold'),
            _organizerStatTile(context, 'Total Refunds', '\$0.00', 'refunded'),
            _organizerStatTile(context, 'Avg per Event', '\$252.65', 'average'),
          ],
        ),
        const SizedBox(height: 16),
        _createEventCTA(context),
      ],
    );
  }

  Widget _organizerEvents(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Events Management', style: TextStyle(color: Colors.black, fontSize: _font(context, 17), fontWeight: FontWeight.w900)),
                Text('Manage your events and track performance.', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
              ],
            ),
            Text('16 Events', style: TextStyle(color: const Color(0xff2f9bef), fontWeight: FontWeight.w900, fontSize: _font(context, 12))),
          ],
        ),
        const SizedBox(height: 16),
        _organizerEventItem(context, 'Fred\'s Medical Fund Cookout', 'draft', '2', '7.65', '0.00', '235.58', const Color(0xff94a3b8)),
        _organizerEventItem(context, 'Executive wellness and spa', 'live', '0', '0.00', '0.00', '0.00', const Color(0xff16a34a)),
        _organizerEventItem(context, 'Polished Gem Wellness Spa', 'live', '1', '9.00', '0.00', '310.00', const Color(0xff16a34a)),
        _organizerEventItem(context, 'Wax Moi', 'live', '1', '41.60', '0.00', '1346.00', const Color(0xff16a34a)),
        _organizerEventItem(context, 'Dave\'s Cookout Special', 'live', '1', '1.70', '0.00', '45.00', const Color(0xff16a34a)),
        _organizerEventItem(context, 'Harry\'s Cookout Fund', 'live', '0', '0.00', '0.00', '0.00', const Color(0xff16a34a)),
        _organizerEventItem(context, 'Howard\'s Grill and Chill', 'live', '0', '0.00', '0.00', '0.00', const Color(0xff16a34a)),
        const SizedBox(height: 8),
        _createEventCTA(context),
      ],
    );
  }

  Widget _organizerPayouts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _whiteCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AVAILABLE PAYOUT', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('\$4,042.34', style: TextStyle(color: const Color(0xff16a34a), fontSize: _font(context, 32), fontWeight: FontWeight.w900, height: 1.0)),
              Text('Net earnings ready to transfer', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletPage())),
                child: Container(
                  width: double.infinity,
                  height: _ui(context, 48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xff16a34a), borderRadius: BorderRadius.circular(_ui(context, 10))),
                  child: Text('Transfer to Wallet', style: TextStyle(color: Colors.white, fontSize: _font(context, 15), fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(context, 'Recent payouts', 'Last 30 days history'),
        const SizedBox(height: 12),
        _whiteCard(
          context,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('May payout', style: TextStyle(color: Colors.black, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
                    Text('May 1, 2026', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Text('\$1,250.00', style: TextStyle(color: const Color(0xff16a34a), fontSize: _font(context, 15), fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _organizerStatTile(BuildContext context, String label, String value, [String? sub, Color? subColor]) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 12)),
        border: Border.all(color: const Color(0xfff0f4f8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: Colors.black, fontSize: _font(context, 20), fontWeight: FontWeight.w900, height: 1.1)),
          if (sub != null)
            Text(sub, style: TextStyle(color: subColor ?? const Color(0xff8ca0ba), fontSize: _font(context, 9), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _organizerEventItem(BuildContext context, String title, String status, String tickets, String fees, String refunds, String net, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff0f4f8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: TextStyle(color: Colors.black, fontSize: _font(context, 14.5), fontWeight: FontWeight.w900))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.confirmation_num_rounded, color: const Color(0xffff3f72), size: 10),
              const SizedBox(width: 4),
              Text(tickets, style: TextStyle(color: const Color(0xff435168), fontSize: 10, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              Text('Fees \$$fees', style: TextStyle(color: const Color(0xffff3f72), fontSize: 9, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('Refunds \$$refunds', style: TextStyle(color: const Color(0xfff59e0b), fontSize: 9, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Net \$$net', style: TextStyle(color: const Color(0xff16a34a), fontSize: 10, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _createEventCTA(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => const AllEvents(country: 'Bahamas')),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(_ui(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xfff0f4f8), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: _ui(context, 44),
              height: _ui(context, 44),
              decoration: BoxDecoration(
                color: const Color(0xfff59e0b),
                borderRadius: BorderRadius.circular(_ui(context, 12)),
              ),
              child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create an Event', style: TextStyle(color: Colors.black, fontSize: _font(context, 15.5), fontWeight: FontWeight.w900)),
                  Text('Host & sell tickets', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xffdfe6ef), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _billItem(BuildContext context, String title, String billId, String accId, String date, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff0f4f8), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.black, fontSize: _font(context, 14.5), fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('$billId • $accId • $date', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 10), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: TextStyle(color: Colors.black, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Paid', style: TextStyle(color: Color(0xff16a34a), fontSize: 10, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _payBillCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletPage(scrollToPayBills: true))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(_ui(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xfff0f4f8), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: _ui(context, 44),
              height: _ui(context, 44),
              decoration: BoxDecoration(
                color: const Color(0xff3fa9f5),
                borderRadius: BorderRadius.circular(_ui(context, 12)),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pay a Bill', style: TextStyle(color: Colors.black, fontSize: _font(context, 15.5), fontWeight: FontWeight.w900)),
                  Text('Utilities & more', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xffdfe6ef), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _coinsContent(BuildContext context) {
    final tabs = const [
      [Icons.monetization_on_outlined, 'Balance'],
      [Icons.shopping_cart_outlined, 'Purchases'],
      [Icons.info_outline_rounded, 'Info'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _ui(context, 32),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, __) => SizedBox(width: _ui(context, 18)),
            itemBuilder: (_, index) {
              final active = _coinsTab == index;
              return GestureDetector(
                onTap: () => setState(() => _coinsTab = index),
                child: Container(
                  padding: EdgeInsets.only(bottom: _ui(context, 8)),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: active ? const Color(0xff2f6fff) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tabs[index][0] as IconData,
                        size: _ui(context, 16),
                        color: active ? const Color(0xff2f6fff) : const Color(0xff93a4bb),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tabs[index][1] as String,
                        style: TextStyle(
                          color: active ? const Color(0xff0f172a) : const Color(0xff93a4bb),
                          fontSize: _font(context, 13),
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
        const SizedBox(height: 18),
        if (_coinsTab == 0) _coinsBalanceView(context),
        if (_coinsTab == 1) _coinsPurchasesView(context),
        if (_coinsTab == 2) _coinsInfoView(context),
      ],
    );
  }

  Widget _coinsBalanceView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'LinkUp Coins Balance', 'in-app coins (not crypto)'),
        const SizedBox(height: 12),
        _whiteCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CURRENT BALANCE', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(homeController.coins.toString(), style: TextStyle(color: Colors.black, fontSize: _font(context, 32), fontWeight: FontWeight.w900, height: 1.0)),
              Text('LinkUp Coins ≈ \$${homeController.walletAmount}', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _summaryTile(context, 'COINS EARNED', '3,200', 'From gifts & activities')),
            SizedBox(width: _ui(context, 8)),
            Expanded(child: _summaryTile(context, 'COINS SPENT', '6,865', 'On gifts & activities')),
          ],
        ),
        const SizedBox(height: 16),
        _buyCoinsCard(context),
      ],
    );
  }

  Widget _coinsPurchasesView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Coin Purchases', 'Top-ups you’ve bought'),
        const SizedBox(height: 12),
        _coinPurchaseItem(context, '3000 LUC', 'Apr 28, 2026', '\$25'),
        _coinPurchaseItem(context, '1200 LUC', 'Apr 2, 2026', '\$10'),
        const SizedBox(height: 8),
        _buyCoinsCard(context),
      ],
    );
  }

  Widget _coinPurchaseItem(BuildContext context, String title, String date, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff0f4f8), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.black, fontSize: _font(context, 15), fontWeight: FontWeight.w900)),
                Text(date, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(price, style: TextStyle(color: Colors.black, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _coinsInfoView(BuildContext context) {
    return _whiteCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About LinkUp Coins', style: TextStyle(color: Colors.black, fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...[
            '1 LinkUp Coin ≈ \$0.01 in value.',
            'Coins are in-app only (not crypto).',
            'Earn coins from gifts (Big Ups & Vibes) and activities.',
            'Spend coins to send gifts, tip creators, and boost.',
            'Received gift coins can be converted to wallet cash (50/50 split).',
          ].map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: const Color(0xff2f9bef), fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
                    Expanded(child: Text(text, style: TextStyle(color: const Color(0xff475569), fontSize: _font(context, 13), fontWeight: FontWeight.w600, height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buyCoinsCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletPage(triggerBuyCoins: true))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(_ui(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xfff0f4f8), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: _ui(context, 44),
              height: _ui(context, 44),
              decoration: BoxDecoration(
                color: const Color(0xfff59e0b),
                borderRadius: BorderRadius.circular(_ui(context, 12)),
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buy Coins', style: TextStyle(color: Colors.black, fontSize: _font(context, 15.5), fontWeight: FontWeight.w900)),
                  Text('Top up your balance', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xffdfe6ef), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _subscriptionContent(BuildContext context) {
    final tabs = const [
      [Icons.workspace_premium_outlined, 'Current Plan'],
      [Icons.history_rounded, 'History'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(tabs.length, (index) {
            final active = _subTabSubscription == index;
            return GestureDetector(
              onTap: () => setState(() => _subTabSubscription = index),
              child: Container(
                margin: EdgeInsets.only(right: _ui(context, 18)),
                padding: EdgeInsets.only(bottom: _ui(context, 8)),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? const Color(0xff2f6fff) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tabs[index][0] as IconData,
                      size: _ui(context, 16),
                      color: active ? const Color(0xff2f6fff) : const Color(0xff93a4bb),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[index][1] as String,
                      style: TextStyle(
                        color: active ? const Color(0xff0f172a) : const Color(0xff93a4bb),
                        fontSize: _font(context, 13),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        if (_subTabSubscription == 0) _currentSubscriptionView(context),
        if (_subTabSubscription == 1) _billingHistoryView(context),
      ],
    );
  }

  Widget _currentSubscriptionView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium_outlined, color: Colors.black, size: _ui(context, 18)),
                    const SizedBox(width: 8),
                    Text('Current Subscription', style: TextStyle(color: Colors.black, fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Plan details and status', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
              ],
            ),
            Text('No Active Plan', style: TextStyle(color: const Color(0xff2f9bef), fontWeight: FontWeight.w900, fontSize: _font(context, 11))),
          ],
        ),
        const SizedBox(height: 16),
        _whiteCard(
          context,
          child: Container(
            height: _ui(context, 140),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.workspace_premium_outlined, color: const Color(0xffcbd5e1), size: _ui(context, 42)),
                const SizedBox(height: 12),
                Text('No Active Subscription', style: TextStyle(color: Colors.black, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Subscribe to a plan to access premium features', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: _ui(context, 50),
          child: ElevatedButton(
            onPressed: () => showLinkUpSubscriptionSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2f9bef),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_ui(context, 14))),
            ),
            child: Text('See Plans & Subscribe', style: TextStyle(color: Colors.white, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  Widget _billingHistoryView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Billing History', 'Past subscription charges'),
        const SizedBox(height: 12),
        _whiteCard(
          context,
          child: Container(
            height: _ui(context, 100),
            alignment: Alignment.center,
            child: Text('No billing history yet.', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 15), fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _liveContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sensors, color: Colors.black, size: _ui(context, 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LinkUp Live', style: TextStyle(color: Colors.black, fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
                  Text('Live broadcasts • engagement • coins', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Text('Live Creator', style: TextStyle(color: const Color(0xff7c3aed), fontWeight: FontWeight.w900, fontSize: _font(context, 11))),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.1,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _summaryTile(context, 'Live broadcasts', '3', 'sessions'),
            _summaryTile(context, 'Watchers', '1', 'unique'),
            _summaryTile(context, 'Likes', '0', 'total'),
            _summaryTile(context, 'Watch time', '1.57', 'minutes'),
          ],
        ),
        const SizedBox(height: 12),
        _whiteCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COINS GENERATED FROM LIVE', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 9), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text('22.4k', style: TextStyle(color: const Color(0xff7c3aed), fontSize: _font(context, 28), fontWeight: FontWeight.w900)),
              Text('Coins received through Live interactions', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _whiteCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REVENUE GENERATED FROM COINS', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 9), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text('\$224.00', style: TextStyle(color: const Color(0xff16a34a), fontSize: _font(context, 28), fontWeight: FontWeight.w900)),
              Text('Gross revenue value from coin activity', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _whiteCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('TRANSFERRED TO WALLET', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 9), fontWeight: FontWeight.w900, letterSpacing: 0.5))),
                  Text('50/50 SPLIT', style: TextStyle(color: const Color(0xfff97316), fontSize: _font(context, 9), fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 4),
              Text('You keep 50% of everything collected — LinkUp keeps the other 50%', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _miniMetricColumn('Your 50% share', '\$112.00', 'creator share')),
                  Expanded(child: _miniMetricColumn('LinkUp 50% fee', '\$112.00', 'platform')),
                ],
              ),
              const Divider(height: 24, color: Color(0xfff1f5f9)),
              Row(
                children: [
                  Expanded(child: _miniMetricColumn('Transferred', '\$0.00', 'to wallet')),
                  Expanded(child: _miniMetricColumn('Eligible now', '\$112.00', 'ready to transfer', isBold: true)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff16a34a).withOpacity(0.7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Transfer \$112.00 to Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(context, 'Live Broadcast Activity', 'Broadcasts, engagement, coins, payout'),
        const SizedBox(height: 12),
        _liveActivityItem(context, 'tests', 'L-00-213', 'Dec 12', 0, '0m', 0, 0),
        _liveActivityItem(context, 'Live Stream', 'L-36-212', 'Dec 13', 0, '0m', 0, 0),
        _liveActivityItem(context, 'gfhj', 'LIVE-2311', 'Dec 30', 1, '1.57m', 0, 0),
        const SizedBox(height: 12),
        Text(
          'Notes: Coins are generated during Live, converted to revenue, then split 50/50. Creator share can be transferred to wallet.',
          style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w600, height: 1.4),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _miniMetricColumn(String label, String value, String sub, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: const Color(0xff475569), fontSize: _font(context, 10), fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: Colors.black, fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
        Text(sub, style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _liveActivityItem(BuildContext context, String title, String id, String date, int watchers, String time, int likes, double coins) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff0f4f8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(title, style: TextStyle(color: Colors.black, fontSize: _font(context, 14.5), fontWeight: FontWeight.w900)),
                  const SizedBox(width: 6),
                  Text(id, style: TextStyle(color: const Color(0xffcbd5e1), fontSize: _font(context, 9), fontWeight: FontWeight.w700)),
                ],
              ),
              Text(date, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 11), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _activityMetric(Icons.person_outline, watchers.toString()),
              _activityMetric(Icons.access_time_rounded, time),
              _activityMetric(Icons.favorite_border_rounded, likes.toString()),
              _activityMetric(Icons.monetization_on_rounded, '\$${coins.toStringAsFixed(2)}'),
              const Spacer(),
              Text('Creator \$0.00', style: TextStyle(color: const Color(0xff2563eb), fontSize: _font(context, 10), fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Text('Xfer \$0.00', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityMetric(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xffcbd5e1), size: 14),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: const Color(0xff475569), fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _aboutContent(BuildContext context) {
    final tabs = const [
      [Icons.contact_page_outlined, 'About'],
      [Icons.phone_enabled_outlined, 'Contact'],
      [Icons.favorite_border_rounded, 'Interests'],
    ];
    return Column(
      children: [
        Row(
          children: List.generate(tabs.length, (index) {
            final active = _subTab == index;
            return GestureDetector(
              onTap: () => setState(() => _subTab = index),
              child: Container(
                margin: EdgeInsets.only(right: _ui(context, 22)),
                padding: EdgeInsets.only(bottom: _ui(context, 8)),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? const Color(0xff2f6fff) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tabs[index][0] as IconData,
                      size: _ui(context, 17),
                      color: active ? const Color(0xff0f172a) : const Color(0xff93a4bb),
                    ),
                    SizedBox(width: _ui(context, 7)),
                    Text(
                      tabs[index][1] as String,
                      style: TextStyle(
                        color: active ? const Color(0xff0f172a) : const Color(0xff93a4bb),
                        fontSize: _font(context, 14.5),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        if (_subTab == 0) _profileDetails(context),
        if (_subTab == 1) _contactDetails(context),
        if (_subTab == 2) _interestsCard(context),
      ],
    );
  }

  Widget _profileDetails(BuildContext context) {
    return _whiteCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.contact_page_outlined, size: _ui(context, 20), color: Colors.black),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profile Details', style: TextStyle(color: Colors.black, fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('Personal information and background', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          _detailRow(context, Icons.person_outline, 'FULL NAME', _currentFullName),
          _detailRow(context, Icons.mail_outline_rounded, 'EMAIL', _currentEmail.isEmpty ? 'No email added' : _currentEmail),
          _detailRow(context, Icons.cake_outlined, 'BIRTHDAY', 'May 2, 2000'),
          _detailRow(context, Icons.work_outline, 'JOB', 'Marketing'),
          _detailRow(context, Icons.verified_user_outlined, 'STATUS', 'Active'),
          _detailRow(context, Icons.groups_2_outlined, 'GENDER', 'Female'),
          _detailRow(context, Icons.school_outlined, 'UNIVERSITY', 'High Point University'),
          _detailRow(context, Icons.flag_outlined, 'COUNTRY', 'BS'),
        ],
      ),
    );
  }

  Widget _contactDetails(BuildContext context) {
    return Column(
      children: [
        _detailRow(context, Icons.mail_outline_rounded, 'EMAIL', _currentEmail.isEmpty ? 'No email added' : _currentEmail, card: true),
        _detailRow(context, Icons.phone_enabled_outlined, 'PHONE', '(242) 801–5860', card: true),
        _detailRow(context, Icons.location_on_outlined, 'LOCATION', 'Nassau, NP, BS', card: true),
        _detailRow(context, Icons.language_rounded, 'WEBSITE', 'linkup.app/cassius', card: true),
      ],
    );
  }

  Widget _interestsCard(BuildContext context) {
    return _whiteCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interests', style: TextStyle(fontSize: _font(context, 18), fontWeight: FontWeight.w900, color: Colors.black)),
          const SizedBox(height: 18),
          Wrap(
            spacing: _ui(context, 10),
            runSpacing: _ui(context, 10),
            children: [
              '✨ Caribbean Culture', '✨ Live Music', '✨ Soca Fêtes', '✨ Carnival',
              '✨ Community Events', '✨ Travel', '✨ Cooking', '✨ Beach Days'
            ].map((e) => _interestPill(context, e)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _ticketsContent(BuildContext context) {
    final tabs = const [
      [Icons.confirmation_number_outlined, 'Purchased Tickets'],
      [Icons.cancel_outlined, 'Cancelled Tickets'],
      [Icons.trending_up_rounded, 'Summary'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _ui(context, 32),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, __) => SizedBox(width: _ui(context, 18)),
            itemBuilder: (_, index) {
              final active = _ticketTab == index;
              return GestureDetector(
                onTap: () => setState(() => _ticketTab = index),
                child: Container(
                  padding: EdgeInsets.only(bottom: _ui(context, 8)),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: active ? const Color(0xff2f6fff) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tabs[index][0] as IconData,
                        size: _ui(context, 16),
                        color: active ? const Color(0xff2f6fff) : const Color(0xff93a4bb),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tabs[index][1] as String,
                        style: TextStyle(
                          color: active ? const Color(0xff0f172a) : const Color(0xff93a4bb),
                          fontSize: _font(context, 13),
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
        const SizedBox(height: 18),
        if (_ticketTab == 0) ...[
          Row(
            children: [
              Expanded(child: _sectionTitle(context, 'Ticket Records', 'Your confirmed ticket purchases, grouped by event')),
              Text('6', style: TextStyle(color: const Color(0xff2563eb), fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
            ],
          ),
          const SizedBox(height: 8),
          _ticketCard(context),
        ],
        if (_ticketTab == 1) _emptyState(context, null, 'No cancelled tickets.', ''),
        if (_ticketTab == 2) _ticketSummary(context),
      ],
    );
  }

  Widget _ticketSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Ticket Summary', 'Your event activity'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _summaryTile(context, 'Tickets', '6', 'purchased')),
            SizedBox(width: _ui(context, 8)),
            Expanded(child: _summaryTile(context, 'Checked-in', '2', 'scanned')),
            SizedBox(width: _ui(context, 8)),
            Expanded(child: _summaryTile(context, 'Spent', '\$461', 'total')),
          ],
        ),
      ],
    );
  }

  Widget _ticketCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 17))),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 2.0,
                child: Image.network('https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=900&q=80', fit: BoxFit.cover),
              ),
              Positioned(left: _ui(context, 10), bottom: _ui(context, 10), child: _smallBadge(context, '30 Aug 2026', Colors.white, Colors.black)),
              Positioned(right: _ui(context, 9), top: _ui(context, 9), child: _smallBadge(context, '2 Tickets', const Color(0xff2f6fff), Colors.white)),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(_ui(context, 12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wax Moi', style: TextStyle(color: Colors.black, fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
                Text('Welcome to Wax Moi Day Spa, the pr...', style: TextStyle(color: const Color(0xff8ba0bb), fontSize: _font(context, 13))),
                SizedBox(height: _ui(context, 10)),
                _summaryLine(context, 'Total Purchases:', '2'),
                _summaryLine(context, 'Total Tickets:', '2'),
                _summaryLine(context, 'Total Paid:', '\$364.00', valueColor: const Color(0xff08a66d)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _marketplaceContent(BuildContext context) {
    final tabs = const [
      [Icons.shopping_cart_outlined, 'Orders'],
      [Icons.trending_up_rounded, 'Spend Summary'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(tabs.length, (index) {
            final active = _marketTab == index;
            return GestureDetector(
              onTap: () => setState(() => _marketTab = index),
              child: Container(
                margin: EdgeInsets.only(right: _ui(context, 18)),
                padding: EdgeInsets.only(bottom: _ui(context, 8)),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? const Color(0xff2f6fff) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tabs[index][0] as IconData,
                      size: _ui(context, 16),
                      color: active ? const Color(0xff2f6fff) : const Color(0xff93a4bb),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[index][1] as String,
                      style: TextStyle(
                        color: active ? const Color(0xff0f172a) : const Color(0xff93a4bb),
                        fontSize: _font(context, 13),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        if (_marketTab == 0) _marketplaceOrders(context),
        if (_marketTab == 1) _marketSpendSummary(context),
      ],
    );
  }

  Widget _marketplaceOrders(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle(context, 'Marketplace Orders', 'Items purchased')),
            Text('2', style: TextStyle(color: const Color(0xff16a34a), fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
          ],
        ),
        const SizedBox(height: 12),
        _orderItem(context, '27', 'Book', 'Apr 20, 2026', '\$20.00', 'Processing'),
        _orderItem(context, '33', 'All-Weather HDPE Folding Adirondack Chair Fire Pit Chair w/Cup Holder, Gray', 'Apr 29, 2026', '\$108.11', 'Processing'),
        const SizedBox(height: 8),
        _browseMarketCard(context),
      ],
    );
  }

  Widget _browseMarketCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MarketPage())),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(_ui(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xfff0f4f8), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: _ui(context, 44),
              height: _ui(context, 44),
              decoration: BoxDecoration(
                color: const Color(0xffa855f7),
                borderRadius: BorderRadius.circular(_ui(context, 12)),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Browse Marketplace', style: TextStyle(color: Colors.black, fontSize: _font(context, 15.5), fontWeight: FontWeight.w900)),
                  Text('Shop products', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xffdfe6ef), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _orderItem(BuildContext context, String id, String title, String date, String price, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff0f4f8), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('#$id', style: TextStyle(color: const Color(0xffcbd5e1), fontSize: _font(context, 12), fontWeight: FontWeight.w700)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.black, fontSize: _font(context, 14.5), fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(date, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: TextStyle(color: Colors.black, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: const TextStyle(color: Color(0xff2f9bef), fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _marketSpendSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Spend Summary', 'Your marketplace spending overview'),
        const SizedBox(height: 12),
        _whiteCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL SPEND', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('\$128.11', style: TextStyle(color: Colors.black, fontSize: _font(context, 32), fontWeight: FontWeight.w900, height: 1.0)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _summaryTile(context, 'Delivered', '0', 'completed')),
            SizedBox(width: _ui(context, 8)),
            Expanded(child: _summaryTile(context, 'Processing', '2', 'in progress')),
            SizedBox(width: _ui(context, 8)),
            Expanded(child: _summaryTile(context, 'Cancelled', '0', 'cancelled')),
          ],
        ),
      ],
    );
  }

  Widget _eatsContent(BuildContext context) {
    final tabs = const [
      [Icons.restaurant_outlined, 'Orders'],
      [Icons.trending_up_rounded, 'Summary'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(tabs.length, (index) {
            final active = _eatsTab == index;
            return GestureDetector(
              onTap: () => setState(() => _eatsTab = index),
              child: Container(
                margin: EdgeInsets.only(right: _ui(context, 18)),
                padding: EdgeInsets.only(bottom: _ui(context, 8)),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? const Color(0xff2f6fff) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tabs[index][0] as IconData,
                      size: _ui(context, 16),
                      color: active ? const Color(0xff2f6fff) : const Color(0xff93a4bb),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[index][1] as String,
                      style: TextStyle(
                        color: active ? const Color(0xff0f172a) : const Color(0xff93a4bb),
                        fontSize: _font(context, 13),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        if (_eatsTab == 0) _eatsOrders(context),
        if (_eatsTab == 1) _eatsSummary(context),
      ],
    );
  }

  Widget _eatsOrders(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant_outlined, color: const Color(0xff16a34a), size: _ui(context, 18)),
            const SizedBox(width: 8),
            Expanded(child: _sectionTitle(context, 'LinkUp Eats Orders', "Food you ordered")),
            Text('3', style: TextStyle(color: const Color(0xff16a34a), fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
          ],
        ),
        const SizedBox(height: 12),
        _eatsOrderItem(context, 'Island Flame Grill', 'EATS-3312', 'Jerk Chicken, Festival · Jun 5, 2026', '\$34.00'),
        _eatsOrderItem(context, 'Conch Shack Express', 'EATS-3287', 'Conch Salad, Sky Juice · May 12, 2026', '\$28.00'),
        _eatsOrderItem(context, 'Trini Roti House', 'EATS-3201', 'Doubles x3, Roti · Apr 28, 2026', '\$22.50'),
      ],
    );
  }

  Widget _eatsOrderItem(BuildContext context, String title, String id, String desc, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 16)),
        border: Border.all(color: const Color(0xfff0f4f8), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(color: Colors.black, fontSize: _font(context, 14.5), fontWeight: FontWeight.w900)),
                    const SizedBox(width: 6),
                    Text(id, style: TextStyle(color: const Color(0xffcbd5e1), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: TextStyle(color: Colors.black, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xfff0fdf4), borderRadius: BorderRadius.circular(8)),
                child: const Text('Delivered', style: TextStyle(color: Color(0xff16a34a), fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _eatsSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Eats Summary', 'Your food ordering overview'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _summaryTile(context, 'Orders', '3', 'placed')),
            SizedBox(width: _ui(context, 8)),
            Expanded(child: _summaryTile(context, 'Spent', '\$85', 'total')),
            SizedBox(width: _ui(context, 8)),
            Expanded(child: _summaryTile(context, 'Delivered', '3', 'completed')),
          ],
        ),
      ],
    );
  }

  Widget _vibesContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.collections_outlined, color: const Color(0xff7c3aed), size: _ui(context, 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Vibes', style: TextStyle(color: Colors.black, fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
                  Text('Posts, reels & engagement', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Text('0', style: TextStyle(color: const Color(0xff7c3aed), fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _summaryTile(context, 'Posts', '0', 'shared')),
            SizedBox(width: _ui(context, 8)),
            Expanded(child: _summaryTile(context, 'Likes', '0', 'received')),
            SizedBox(width: _ui(context, 8)),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(_ui(context, 12)),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 16))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coins', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.monetization_on_rounded, color: const Color(0xff94a3b8), size: _ui(context, 18)),
                        const SizedBox(width: 4),
                        Text('0', style: TextStyle(color: Colors.black, fontSize: _font(context, 22), fontWeight: FontWeight.w900, height: 1.1)),
                      ],
                    ),
                    Text('from Big Ups', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _whiteCard(
          context,
          child: Container(
            height: _ui(context, 100),
            alignment: Alignment.center,
            child: Text('No vibes posted yet.', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 15), fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        _createVibeCard(context),
      ],
    );
  }

  Widget _createVibeCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VibesPage(showComposer: true))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(_ui(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 16)),
          border: Border.all(color: const Color(0xfff0f4f8), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: _ui(context, 44),
              height: _ui(context, 44),
              decoration: BoxDecoration(
                color: const Color(0xff6366f1),
                borderRadius: BorderRadius.circular(_ui(context, 12)),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create a Vibe', style: TextStyle(color: Colors.black, fontSize: _font(context, 15.5), fontWeight: FontWeight.w900)),
                  Text('Post photos or video', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xffdfe6ef), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _newsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _whiteCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Published News', style: TextStyle(color: Colors.black, fontSize: _font(context, 17), fontWeight: FontWeight.w900)),
                        Text('Updates you have shared with the community', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Text('0 posts', style: TextStyle(color: const Color(0xff2563eb), fontWeight: FontWeight.w900, fontSize: _font(context, 13))),
                ],
              ),
              SizedBox(height: _ui(context, 32)),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.newspaper_outlined, color: const Color(0xffcbd5e1), size: _ui(context, 48)),
                    SizedBox(height: _ui(context, 12)),
                    Text('No news posts yet', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              SizedBox(height: _ui(context, 24)),
            ],
          ),
        ),
        SizedBox(height: _ui(context, 12)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(_ui(context, 20)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_ui(context, 20)),
            gradient: const LinearGradient(
              colors: [Color(0xff4b48e8), Color(0xff2f9bef)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xff2563eb).withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Global Impact', style: TextStyle(color: Colors.white, fontSize: _font(context, 20), fontWeight: FontWeight.w900)),
              Text('Trending across LinkUp', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
              SizedBox(height: _ui(context, 16)),
              _impactRow(context, 'MOST ACTIVE REGION', 'Caribbean Islands'),
              SizedBox(height: _ui(context, 8)),
              _impactRow(context, 'TOTAL ENGAGEMENT', '0 Points', isPoints: true),
              SizedBox(height: _ui(context, 8)),
              _impactRow(context, 'TOP CATEGORY', 'Breaking News'),
            ],
          ),
        ),
        SizedBox(height: _ui(context, 12)),
        _newsNavigationCard(context),
      ],
    );
  }

  Widget _impactRow(BuildContext context, String label, String value, {bool isPoints = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 16), vertical: _ui(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(_ui(context, 14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isPoints ? const Color(0xfffbbf24) : Colors.white.withOpacity(0.7), fontSize: _font(context, 9), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: Colors.white, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _newsNavigationCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewsPage())),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(_ui(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xfff0f4f8), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: _ui(context, 44),
              height: _ui(context, 44),
              decoration: BoxDecoration(
                color: const Color(0xff3fa9f5),
                borderRadius: BorderRadius.circular(_ui(context, 12)),
              ),
              child: const Icon(Icons.newspaper_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Open Caribbean 360 News', style: TextStyle(color: Colors.black, fontSize: _font(context, 15.5), fontWeight: FontWeight.w900)),
                  Text('Your personalized feed', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xffdfe6ef), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _matchesContent(BuildContext context) {
    final tabs = const [
      [Icons.people_outline_rounded, 'Matches'],
      [Icons.favorite_border_rounded, 'Likes'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(tabs.length, (index) {
            final active = _matchTab == index;
            return GestureDetector(
              onTap: () => setState(() => _matchTab = index),
              child: Container(
                margin: EdgeInsets.only(right: _ui(context, 18)),
                padding: EdgeInsets.only(bottom: _ui(context, 8)),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? const Color(0xff2f6fff) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tabs[index][0] as IconData,
                      size: _ui(context, 16),
                      color: active ? const Color(0xff2f6fff) : const Color(0xff93a4bb),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[index][1] as String,
                      style: TextStyle(
                        color: active ? const Color(0xff0f172a) : const Color(0xff93a4bb),
                        fontSize: _font(context, 13),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        if (_matchTab == 0) _recentMatches(context),
        if (_matchTab == 1) _likesYou(context),
        const SizedBox(height: 16),
        _openLinkUpCard(context),
      ],
    );
  }

  Widget _recentMatches(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle(context, 'Recent Matches', "People you matched with")),
            Text('3', style: TextStyle(color: const Color(0xff7c3aed), fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            {'name': 'Aaliyah', 'loc': 'Trinidad & Tobago', 'flag': '🇹🇹', 'img': 'https://picsum.photos/seed/aaliyah/400/400'},
            {'name': 'Renee', 'loc': 'Bahamas', 'flag': '🇧🇸', 'img': 'https://picsum.photos/seed/renee/400/400'},
            {'name': 'Nouman Zakir', 'loc': 'Bahamas', 'flag': '🇧🇸', 'img': 'https://picsum.photos/seed/nouman/400/400'},
          ].map((m) => _matchGridItem(context, m)).toList(),
        ),
      ],
    );
  }

  Widget _likesYou(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle(context, 'Likes You', 'People who liked your profile')),
            Text('3', style: TextStyle(color: const Color(0xff7c3aed), fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            {'name': 'Gabriela', 'loc': 'Brazil', 'flag': '🇧🇷', 'img': 'https://picsum.photos/seed/gabriela/400/400'},
            {'name': 'Marissa Bain', 'loc': 'Bahamas', 'flag': '🇧🇸', 'img': 'https://picsum.photos/seed/marissa/400/400'},
            {'name': 'Amara Jean', 'loc': 'Barbados', 'flag': '🇧🇧', 'img': 'https://picsum.photos/seed/amara/400/400'},
          ].map((m) => _matchGridItem(context, m)).toList(),
        ),
      ],
    );
  }

  Widget _matchGridItem(BuildContext context, Map<String, String> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff0f4f8), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Image.network(data['img']!, width: double.infinity, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name']!, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
                Row(
                  children: [
                    Text(data['flag']!, style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(data['loc']!, style: const TextStyle(color: Color(0xff8ca0ba), fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _openLinkUpCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChatHomePage())),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(_ui(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xfff0f4f8), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: _ui(context, 44),
              height: _ui(context, 44),
              decoration: BoxDecoration(
                color: const Color(0xffdb2777).withOpacity(0.85),
                borderRadius: BorderRadius.circular(_ui(context, 12)),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Open LinkUp', style: TextStyle(color: Colors.black, fontSize: _font(context, 15.5), fontWeight: FontWeight.w900)),
                  Text('Matches, likes & chats', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xffdfe6ef), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _giftsContent(BuildContext context) {
    final tabs = const [
      [Icons.copy_rounded, 'Gift Wallet'],
      [Icons.bolt_rounded, 'Activity'],
      [Icons.trending_up_rounded, 'Summary'],
      [Icons.account_balance_wallet_outlined, 'Convert To Cash'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _ui(context, 32),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, __) => SizedBox(width: _ui(context, 18)),
            itemBuilder: (_, index) {
              final active = _giftTab == index;
              return GestureDetector(
                onTap: () => setState(() => _giftTab = index),
                child: Container(
                  padding: EdgeInsets.only(bottom: _ui(context, 8)),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: active ? const Color(0xff2f6fff) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tabs[index][0] as IconData,
                        size: _ui(context, 16),
                        color: active ? const Color(0xff2f6fff) : const Color(0xff93a4bb),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tabs[index][1] as String,
                        style: TextStyle(
                          color: active ? const Color(0xff0f172a) : const Color(0xff93a4bb),
                          fontSize: _font(context, 13),
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
        const SizedBox(height: 18),
        if (_giftTab == 0) _giftWalletView(context),
        if (_giftTab == 1) _giftActivityView(context),
        if (_giftTab == 2) _giftSummaryView(context),
        if (_giftTab == 3) _convertToCashView(context),
      ],
    );
  }

  Widget _giftWalletView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Gift Wallet', 'Purchased vs collected revenue'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryTile(context, 'GIFTS SENT', homeController.coins.toString(), 'Coins', subValue: 'Value: \$${homeController.walletAmount}'),
            ),
            SizedBox(width: _ui(context, 8)),
            Expanded(
              child: _summaryTile(context, 'GIFTS RECEIVED', homeController.coins.toString(), 'Coins', subValue: 'Value: \$${homeController.walletAmount}'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _whiteCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOP GIFT TYPES (RECEIVED)', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 9), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text('Caribbean Crown', style: TextStyle(color: Colors.black, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  Text('8 received', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _giftNavigationCard(context),
      ],
    );
  }

  Widget _giftActivityView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle(context, 'Gift Activity', 'Sent + received + collected')),
            Text('8', style: TextStyle(color: const Color(0xffdc2626), fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
          ],
        ),
        const SizedBox(height: 12),
        _giftActivityItem(context, 'SENT', 'Island Smile', 'To Cassius Stuart (469)', 'May 8, 2026', '10', '\$0.10'),
        _giftActivityItem(context, 'SENT', 'Island Smile', 'To Cassius Stuart (150)', 'May 7, 2026', '10', '\$0.10'),
        _giftActivityItem(context, 'SENT', 'Soca Vibe', 'To Cassius Stuart (469)', 'May 6, 2026', '35', '\$0.35'),
        _giftActivityItem(context, 'RECEIVED', 'Caribbean Crown', 'From Simone (88)', 'Apr 30, 2026', '400', '\$4.00'),
      ],
    );
  }

  Widget _giftActivityItem(BuildContext context, String type, String name, String user, String date, String coins, String value) {
    final isSent = type == 'SENT';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff0f4f8), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSent ? const Color(0xfffff1f2) : const Color(0xfff0fdf4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(type, style: TextStyle(color: isSent ? const Color(0xffe11d48) : const Color(0xff16a34a), fontSize: 9, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(color: Colors.black, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    Text('G-SENT-33', style: TextStyle(color: const Color(0xffcbd5e1), fontSize: _font(context, 8), fontWeight: FontWeight.w700)),
                  ],
                ),
                Text(user, style: TextStyle(color: const Color(0xff475569), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
                Text(date, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 10), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(coins, style: TextStyle(color: Colors.black, fontSize: _font(context, 15), fontWeight: FontWeight.w900)),
                  const SizedBox(width: 4),
                  Icon(Icons.monetization_on_rounded, color: const Color(0xff94a3b8), size: _ui(context, 14)),
                ],
              ),
              Text(value, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _giftSummaryView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Gift Summary', 'Your gifting activity overview'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _summaryStatCard(context, 'TOTAL SPENT', '6,865', '\$68.65')),
            SizedBox(width: _ui(context, 8)),
            Expanded(child: _summaryStatCard(context, 'TOTAL RECEIVED', '3,200', '\$32.00')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _summaryTile(context, 'SENT', '21', 'Gifts sent')),
            SizedBox(width: _ui(context, 8)),
            Expanded(child: _summaryTile(context, 'RECEIVED', '8', 'Gifts received')),
          ],
        ),
      ],
    );
  }

  Widget _summaryStatCard(BuildContext context, String label, String coins, String value) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 9), fontWeight: FontWeight.w900, letterSpacing: 0.5))),
              const Icon(Icons.wallet_giftcard_rounded, color: Color(0xfff97316), size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(coins, style: TextStyle(color: Colors.black, fontSize: _font(context, 22), fontWeight: FontWeight.w900, height: 1.1)),
              const SizedBox(width: 4),
              Icon(Icons.monetization_on_rounded, color: const Color(0xff94a3b8), size: _ui(context, 18)),
            ],
          ),
          Text('Value: $value', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _convertToCashView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle(context, 'Convert to Cash', 'Turn your received gifts into wallet cash')),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('CASH-OUT MIN', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 8), fontWeight: FontWeight.w900)),
                Text('\$25', style: TextStyle(color: Colors.black, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xfffff7ed), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xffffedd5))),
          child: Text(
            'Note: To convert, your available received balance must meet the cash-out minimum. Keep collecting gifts until you do.',
            style: TextStyle(color: const Color(0xff9a3412), fontSize: _font(context, 11), fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        _whiteCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AVAILABLE TO CONVERT', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 10), fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('3,200 Coins', style: TextStyle(color: Colors.black, fontSize: _font(context, 24), fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              _convertInfoRow('Gross value', '\$32.00'),
              _convertInfoRow('You receive (50%)', '\$16.00', isGreen: true),
              _convertInfoRow('Platform share (50%)', '\$16.00'),
              const Divider(height: 24, color: Color(0xfff1f5f9)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Conversion rate', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                  Text('1 Coin = \$0.01', style: TextStyle(color: Colors.black, fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WALLET (AFTER)', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 9), fontWeight: FontWeight.w900)),
                      Text('\$197.04', style: TextStyle(color: Colors.black, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Meets minimum?', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 9), fontWeight: FontWeight.w600)),
                      const Row(
                        children: [
                          Text('No ', style: TextStyle(color: Color(0xffdc2626), fontSize: 18, fontWeight: FontWeight.w900)),
                          Icon(Icons.close_rounded, color: Color(0xffdc2626), size: 24),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Amount (coins)', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 11), fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xffe2e8f0))),
              child: const Text('Convert All', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xffe2e8f0))),
                child: Row(
                  children: [
                    const Expanded(child: Text('3200', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900))),
                    Icon(Icons.unfold_more_rounded, color: const Color(0xff94a3b8), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xffe2e8f0))),
              child: const Text('Max', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _convertInfoRow('You will receive', '\$16.00', isGreen: true),
        _convertInfoRow('Platform share', '\$16.00'),
        _convertInfoRow('Destination', 'LinkUp Wallet - Instant'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffcbd5e1),
              disabledBackgroundColor: const Color(0xffcbd5e1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Convert to Cash', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _convertInfoRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(color: isGreen ? const Color(0xff16a34a) : Colors.black, fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _summaryTile(BuildContext context, String label, String value, String sub, {String? subValue}) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(value, style: TextStyle(color: Colors.black, fontSize: _font(context, 22), fontWeight: FontWeight.w900, height: 1.1)),
              if (sub.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(sub, style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          if (subValue != null) Text(subValue, style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _giftNavigationCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const VibesPage())),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(_ui(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xfff0f4f8), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: _ui(context, 44),
              height: _ui(context, 44),
              decoration: BoxDecoration(
                color: const Color(0xffec4899),
                borderRadius: BorderRadius.circular(_ui(context, 12)),
              ),
              child: const Icon(Icons.redeem_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Send a Vibe', style: TextStyle(color: Colors.black, fontSize: _font(context, 15.5), fontWeight: FontWeight.w900)),
                  Text('Gift coins to others', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xffdfe6ef), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _walletContent(BuildContext context) {
    final tabs = const ['📈 Overview', '🗒 Transactions', '📊 Analytics'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inlineTabs(context, tabs, _walletTab, (v) => setState(() => _walletTab = v)),
        const SizedBox(height: 18),
        if (_walletTab == 0) _walletOverview(context),
        if (_walletTab == 1) _walletTransactions(context),
        if (_walletTab == 2) _walletAnalytics(context),
      ],
    );
  }

  Widget _walletOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: Colors.black, size: _ui(context, 18)),
            const SizedBox(width: 8),
            Text('Wallet Overview', style: TextStyle(color: Colors.black, fontSize: _font(context, 17), fontWeight: FontWeight.w900)),
          ],
        ),
        Text('Balance, transfers, and payouts', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _whiteCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CURRENT BALANCE', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('\$${homeController.walletAmount}', style: TextStyle(color: Colors.black, fontSize: _font(context, 32), fontWeight: FontWeight.w900, height: 1.0)),
              Text('Available balance', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _miniMoneyCard(context, 'INCOMING', '\$822', 'received', const Color(0xff16a34a))),
            SizedBox(width: _ui(context, 8)),
            Expanded(child: _miniMoneyCard(context, 'OUTGOING', '\$1296.96', 'sent', const Color(0xffdc2626))),
            SizedBox(width: _ui(context, 8)),
            Expanded(child: _miniMoneyCard(context, 'PAYOUTS', '\$0', 'cash-outs', const Color(0xff2f9bef))),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _walletCTA(
                context,
                title: 'Open Wallet',
                subtitle: 'Send, top up, bills',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xff2f9bef),
                onTap: () => Get.to(() => const WalletPage()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _walletCTA(
                context,
                title: 'LinkUp Save',
                subtitle: 'High-yield savings',
                icon: Icons.savings_outlined,
                color: const Color(0xff16a34a),
                onTap: () => Get.to(() => const WalletPage(showSavings: true)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _walletTransactions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction History', style: TextStyle(color: Colors.black, fontSize: _font(context, 17), fontWeight: FontWeight.w900)),
                Text('Send / Receive / Bills / Market / Gifts / Coins', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 9), fontWeight: FontWeight.w600)),
              ],
            ),
            Text('9', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: _font(context, 12))),
          ],
        ),
        const SizedBox(height: 16),
        _transactionItem(context, 'transfer', '819e9882-6', 'Jun 2, 2026', '−\$29.85', const Color(0xffdc2626)),
        _transactionItem(context, 'transfer', '819e4234-a', 'May 19, 2026', '−\$100.00', const Color(0xffdc2626)),
        _transactionItem(context, 'deposit', '819e4214-a', 'May 19, 2026', '+\$194.00', const Color(0xff16a34a)),
        _transactionItem(context, 'deposit', '819e4214-7', 'May 19, 2026', '+\$100.00', const Color(0xff16a34a)),
        _transactionItem(context, 'transfer', '819e4189-6', 'May 19, 2026', '−\$5.00', const Color(0xffdc2626)),
        _transactionItem(context, 'earn', '819e3182-3', 'May 12, 2026', '−\$28.00', const Color(0xffdc2626)),
        _transactionItem(context, 'market', '819e3a77-a', 'Apr 29, 2026', '−\$108.11', const Color(0xffdc2626)),
        _transactionItem(context, 'gift', '819e38e1-2', 'Apr 20, 2026', '+\$16.00', const Color(0xff16a34a)),
        _transactionItem(context, 'bill', '819e22c4-5', 'Dec 12, 2025', '−\$89.50', const Color(0xffdc2626)),
      ],
    );
  }

  Widget _walletAnalytics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wallet Analytics', style: TextStyle(color: Colors.black, fontSize: _font(context, 17), fontWeight: FontWeight.w900)),
        Text('Financial insights and trends', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: _ui(context, 10),
          mainAxisSpacing: _ui(context, 10),
          childAspectRatio: 1.8,
          children: [
            _analyticsTile(context, 'NET CASHFLOW', '−\$50.46', 'Negative cash flow', const Color(0xffdc2626)),
            _analyticsTile(context, 'Total Transactions', '9', 'all types'),
            _analyticsTile(context, 'AVERAGE TRANSACTION', '\$74.50', 'Per transaction', const Color(0xfff59e0b)),
            _analyticsTile(context, 'PAYOUT RATIO', '0.0%', 'Of total balance', const Color(0xff2f9bef)),
          ],
        ),
        const SizedBox(height: 20),
        Text('Transaction Types', style: TextStyle(color: Colors.black, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: const Color(0xfffef2f2), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('6', style: TextStyle(color: Color(0xffdc2626), fontSize: 24, fontWeight: FontWeight.w900)),
                    Text('Money out', style: TextStyle(color: const Color(0xffdc2626).withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: const Color(0xfff0fdf4), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('3', style: TextStyle(color: Color(0xff16a34a), fontSize: 24, fontWeight: FontWeight.w900)),
                    Text('Money in', style: TextStyle(color: const Color(0xff16a34a).withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _analyticsTile(BuildContext context, String label, String value, String sub, [Color? valueColor]) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xfff0f4f8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 8.5), fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: valueColor ?? Colors.black, fontSize: _font(context, 20), fontWeight: FontWeight.w900, height: 1.1)),
          Text(sub, style: TextStyle(color: const Color(0xff8ca0ba).withOpacity(0.8), fontSize: _font(context, 8.5), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _transactionItem(BuildContext context, String type, String id, String date, String amount, Color amountColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xfff0f4f8))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: amountColor.withOpacity(0.06), borderRadius: BorderRadius.circular(6)),
            child: Text(type, style: TextStyle(color: amountColor, fontSize: 8, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: TextStyle(color: const Color(0xff435168), fontSize: 10, fontWeight: FontWeight.w800)),
                Text(date, style: TextStyle(color: const Color(0xff94a3b8), fontSize: 9, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(color: amountColor, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _walletCTA(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xfff0f4f8))),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.black, fontSize: _font(context, 12.5), fontWeight: FontWeight.w900)),
                  Text(subtitle, style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 9), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineTabs(BuildContext context, List<String> tabs, int value, ValueChanged<int> onChanged) {
    return SizedBox(
      height: _ui(context, 32),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => SizedBox(width: _ui(context, 13)),
        itemBuilder: (_, index) {
          final active = value == index;
          return GestureDetector(
            onTap: () => onChanged(index),
            child: Container(
              padding: EdgeInsets.only(bottom: _ui(context, 7)),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? const Color(0xff246bff) : Colors.transparent, width: 2))),
              child: Text(tabs[index], style: TextStyle(color: active ? const Color(0xff1d63ff) : const Color(0xff92a2b9), fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
            ),
          );
        },
      ),
    );
  }

  Widget _whiteCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_ui(context, 15)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 17))),
      child: child,
    );
  }

  Widget _sectionTitle(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.black, fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
        SizedBox(height: _ui(context, 2)),
        Text(subtitle, style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value, {bool card = false}) {
    final row = Padding(
      padding: EdgeInsets.only(top: _ui(context, 20)),
      child: Row(
        children: [
          Container(
            width: _ui(context, 44),
            height: _ui(context, 44),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_ui(context, 12)),
              border: Border.all(color: const Color(0xfff0f4f8), width: 1),
            ),
            child: Icon(icon, color: const Color(0xff8ca0ba), size: _ui(context, 18)),
          ),
          SizedBox(width: _ui(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xff94a3b8),
                    fontSize: _font(context, 9),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: _font(context, 16),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return row;
  }

  Widget _interestPill(BuildContext context, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 11), vertical: _ui(context, 8)),
      decoration: BoxDecoration(color: const Color(0xfff0f6ff), borderRadius: BorderRadius.circular(_ui(context, 18))),
      child: Text(text, style: TextStyle(color: const Color(0xff1155de), fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
    );
  }

  Widget _smallBadge(BuildContext context, String text, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 8), vertical: _ui(context, 5)),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(_ui(context, 10))),
      child: Text(text, style: TextStyle(color: fg, fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
    );
  }

  Widget _summaryLine(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(top: _ui(context, 4)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: const Color(0xff687892), fontSize: _font(context, 13), fontWeight: FontWeight.w600))),
          Text(value, style: TextStyle(color: valueColor ?? Colors.black, fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _metricRow(BuildContext context, String a, String av, String b, String bv) {
    return Row(
      children: [
        Expanded(child: _miniMoneyCard(context, a, av, '', const Color(0xff2f9bef))),
        SizedBox(width: _ui(context, 8)),
        Expanded(child: _miniMoneyCard(context, b, bv, '', const Color(0xff8b5cf6))),
      ],
    );
  }

  Widget _miniMoneyCard(BuildContext context, String label, String value, String sub, Color color) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: const Color(0xff8ba0bb), fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: _font(context, 20), fontWeight: FontWeight.w900, height: 1.1)),
          if (sub.isNotEmpty) Text(sub, style: TextStyle(color: const Color(0xff8ba0bb), fontSize: _font(context, 11))),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, IconData? icon, String title, String subtitle) {
    return _whiteCard(
      context,
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xff2f9bef), size: _ui(context, 42)),
            SizedBox(height: _ui(context, 8)),
          ],
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: _font(context, 16), fontWeight: FontWeight.w900, color: Colors.black)),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: _ui(context, 4)),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: _font(context, 12), color: const Color(0xff8ca0ba), fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _restaurantCard(BuildContext context, String title, String subtitle, String image) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 17))),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 2.05, child: Image.network(image, fit: BoxFit.cover)),
          Padding(
            padding: EdgeInsets.all(_ui(context, 12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: Colors.black, fontSize: _font(context, 17), fontWeight: FontWeight.w900)),
              Text(subtitle, style: TextStyle(color: const Color(0xff7486a0), fontSize: _font(context, 12), fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    final nameController = TextEditingController(text: _currentFullName);
    final emailController = TextEditingController(text: _currentEmail);
    final jobController = TextEditingController(text: 'Marketing');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheetFrame(
        title: 'Edit Profile',
        subtitle: 'Update your public LinkUp details.',
        child: Column(
          children: [
            _sheetField(context, 'FULL NAME', nameController),
            _sheetField(context, 'EMAIL', emailController),
            _sheetField(context, 'JOB', jobController),
            _sheetButton(context, 'Save Changes', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(BuildContext context, String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: _ui(context, 12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: const Color(0xff70829b), fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
          SizedBox(height: _ui(context, 6)),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xfff8fbff),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 14)), borderSide: const BorderSide(color: Color(0xffdfe9f5))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 14)), borderSide: const BorderSide(color: Color(0xffdfe9f5))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetButton(BuildContext context, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: _ui(context, 50),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff2f9bef),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_ui(context, 14))),
        ),
        child: Text(label, style: TextStyle(color: Colors.white, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
      ),
    );
  }

  void _showMyQr(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: _ui(context, 22)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_ui(context, 22))),
        child: Padding(
          padding: EdgeInsets.all(_ui(context, 18)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('My QR', style: TextStyle(color: Colors.black, fontSize: _font(context, 22), fontWeight: FontWeight.w900)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              CircleAvatar(radius: 28, backgroundImage: _currentAvatar),
              SizedBox(height: _ui(context, 8)),
              Text(_currentFullName, style: TextStyle(color: Colors.black, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
              Text('@${_currentFirstName.toLowerCase()}', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 12), fontWeight: FontWeight.w700)),
              SizedBox(height: _ui(context, 14)),
              CustomQrCodeWidget(size: _ui(context, 210)),
              SizedBox(height: _ui(context, 8)),
              Text('Scan to view my LinkUp profile', style: TextStyle(color: const Color(0xff8ca0ba), fontSize: _font(context, 11))),
              SizedBox(height: _ui(context, 14)),
              _sheetButton(context, 'Share QR', () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    final items = const [
      [Icons.home_outlined, 'Home'],
      [Icons.image_outlined, 'Vibes'],
      [Icons.restaurant_outlined, 'Eats'],
      [Icons.wifi_tethering_rounded, 'Live'],
      [Icons.favorite_border_rounded, 'LinkUp'],
    ];
    return Container(
      height: _ui(context, 64),
      padding: EdgeInsets.only(bottom: _ui(context, 6)),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xffe6edf7)))) ,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final selected = index == 4;
          return GestureDetector(
            onTap: () {
              Widget page;
              if (index == 0) page = HomePage();
              else if (index == 1) page = const VibesPage();
              else if (index == 2) page = const EatsPage();
              else if (index == 3) page = const LivePage();
              else page = ChatHomePage();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: _ui(context, 30),
                  height: _ui(context, 30),
                  decoration: BoxDecoration(color: selected ? const Color(0xff2f9bef) : Colors.transparent, borderRadius: BorderRadius.circular(_ui(context, 10))),
                  child: Icon(items[index][0] as IconData, color: selected ? Colors.white : const Color(0xff627085), size: _ui(context, 23)),
                ),
                Text(items[index][1] as String, style: TextStyle(color: selected ? const Color(0xff2f9bef) : const Color(0xff627085), fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _HeroMiniChip extends StatelessWidget {
  final String text;
  const _HeroMiniChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? subColor;
  final bool avatar;
  const _SnapshotTile({required this.label, required this.value, required this.sub, this.subColor, this.avatar = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xff8ca0ba), fontSize: 11, fontWeight: FontWeight.w900)),
          const Spacer(),
          Row(
            children: [
              if (avatar) ...[
                CircleAvatar(radius: 13, backgroundImage: LinkUpCurrentUser.avatarProvider()),
                const SizedBox(width: 4),
              ],
              Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff0f172a), fontSize: 24, fontWeight: FontWeight.w900, height: 1.0))),
            ],
          ),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: subColor ?? const Color(0xff8ca0ba), fontSize: 10.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ProfileSheetFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _ProfileSheetFrame({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xff2f9bef), Color(0xff2487e0)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final cell = size.width / 21;
    final blocks = <Offset>[
      const Offset(0, 0), const Offset(1, 0), const Offset(2, 0), const Offset(3, 0), const Offset(4, 0), const Offset(5, 0), const Offset(6, 0),
      const Offset(0, 1), const Offset(6, 1), const Offset(0, 2), const Offset(2, 2), const Offset(3, 2), const Offset(4, 2), const Offset(6, 2),
      const Offset(0, 3), const Offset(2, 3), const Offset(4, 3), const Offset(6, 3), const Offset(0, 4), const Offset(2, 4), const Offset(3, 4), const Offset(4, 4), const Offset(6, 4),
      const Offset(0, 5), const Offset(6, 5), const Offset(0, 6), const Offset(1, 6), const Offset(2, 6), const Offset(3, 6), const Offset(4, 6), const Offset(5, 6), const Offset(6, 6),
      const Offset(14, 0), const Offset(15, 0), const Offset(16, 0), const Offset(17, 0), const Offset(18, 0), const Offset(19, 0), const Offset(20, 0),
      const Offset(14, 1), const Offset(20, 1), const Offset(14, 2), const Offset(16, 2), const Offset(17, 2), const Offset(18, 2), const Offset(20, 2),
      const Offset(14, 3), const Offset(16, 3), const Offset(18, 3), const Offset(20, 3), const Offset(14, 4), const Offset(16, 4), const Offset(17, 4), const Offset(18, 4), const Offset(20, 4),
      const Offset(14, 5), const Offset(20, 5), const Offset(14, 6), const Offset(15, 6), const Offset(16, 6), const Offset(17, 6), const Offset(18, 6), const Offset(19, 6), const Offset(20, 6),
      const Offset(0, 14), const Offset(1, 14), const Offset(2, 14), const Offset(3, 14), const Offset(4, 14), const Offset(5, 14), const Offset(6, 14),
      const Offset(0, 15), const Offset(6, 15), const Offset(0, 16), const Offset(2, 16), const Offset(3, 16), const Offset(4, 16), const Offset(6, 16),
      const Offset(0, 17), const Offset(2, 17), const Offset(4, 17), const Offset(6, 17), const Offset(0, 18), const Offset(2, 18), const Offset(3, 18), const Offset(4, 18), const Offset(6, 18),
      const Offset(0, 19), const Offset(6, 19), const Offset(0, 20), const Offset(1, 20), const Offset(2, 20), const Offset(3, 20), const Offset(4, 20), const Offset(5, 20), const Offset(6, 20),
    ];
    for (final b in blocks) {
      canvas.drawRect(Rect.fromLTWH(b.dx * cell, b.dy * cell, cell, cell), paint);
    }
    for (var y = 0; y < 21; y++) {
      for (var x = 0; x < 21; x++) {
        final finder = (x < 7 && y < 7) || (x > 13 && y < 7) || (x < 7 && y > 13);
        if (finder) continue;
        final on = ((x * 7 + y * 11 + x * y) % 5 == 0) || ((x + y) % 7 == 0) || ((x * 3 + y) % 11 == 0);
        if (on) canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
