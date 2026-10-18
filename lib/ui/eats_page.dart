
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:link_up/ui/profile/profile_page.dart';
import 'package:link_up/widgets/linkup_location_sheet.dart';
import '../widgets/linkup_current_user.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/get_controller/home_controller.dart';
import 'package:link_up/ui/chat_home_page.dart';
import 'package:link_up/ui/home_page.dart';
import 'package:link_up/ui/vibes_page.dart';
import 'package:link_up/ui/live_page.dart';
import 'package:link_up/ui/wallet_page.dart';
import 'package:link_up/ui/notification_page.dart';

class EatsPage extends StatefulWidget {
  const EatsPage({Key? key}) : super(key: key);

  @override
  State<EatsPage> createState() => _EatsPageState();
}

enum _EatsMode { gate, qr, restaurants, restaurantDetails }

class _EatsPageState extends State<EatsPage> with TickerProviderStateMixin {
  final AuthController authController = Get.find(tag: AuthController().toString());
  final HomeController homeController = Get.find(tag: HomeController().toString());
  _EatsMode _mode = _EatsMode.restaurants;
  String _category = 'All';
  final TextEditingController _search = TextEditingController();
  bool _isDelivery = true;
  final Set<String> _selectedTools = {'Favorites', 'Reorder Last'};
  DateTime? _scheduledTime = DateTime(2026, 8, 3, 12, 3);
  _Restaurant? _selectedRestaurant;
  bool _isDeliveryInDetails = true;
  String _selectedDetailCategory = 'Popular';

  // Location State
  String _deliveryCity = 'Nassau, Bahamas (BSD)';
  String _deliveryStreet = 'Nassau, Bahamas';
  String _deliveryLat = '25.0443';
  String _deliveryLng = '-77.3504';

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  // Reservation State
  DateTime _resDate = DateTime(2026, 8, 4, 19, 0);
  int _partySize = 2;
  String? _resSeatingArea;
  String? _resClimate;
  String? _resTableType;
  Set<String> _resPositionView = {};
  Set<String> _resAccessibility = {};
  String? _resOccasion;
  final TextEditingController _resName = TextEditingController();
  final TextEditingController _resPhone = TextEditingController();
  final TextEditingController _resEmail = TextEditingController();
  final TextEditingController _resSpecial = TextEditingController();
  bool _showResSuccess = false;

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.90, 1.06).toDouble();
  }

  @override
  void dispose() {
    _search.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<_Restaurant> get _filteredRestaurants {
    final q = _search.text.trim().toLowerCase();
    return _Restaurant.seed().where((r) {
      final catOk = _category == 'All' || r.category == _category;
      final qOk = q.isEmpty ||
          r.name.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q) ||
          r.tags.join(' ').toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeaf4fe),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topHeader(context),
            _geoBar(context),
            _eatsToolbar(context),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _mode == _EatsMode.gate
                    ? _orderingGate(context)
                    : _mode == _EatsMode.qr
                        ? _qrScreen(context)
                        : _mode == _EatsMode.restaurantDetails
                            ? _restaurantDetailsScreen(context)
                            : _restaurantsScreen(context),
              ),
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
          Row(
            children: [
              Container(
                width: _ui(context, 18),
                height: _ui(context, 22),
                decoration: BoxDecoration(
                  color: const Color(0xff9EDB2F),
                  borderRadius: BorderRadius.circular(_ui(context, 8)),
                ),
              ),
              SizedBox(width: _ui(context, 5)),
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
            ],
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.to(() => const WalletPage()),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 13), vertical: _ui(context, 7)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(_ui(context, 22)),
              ),
              child: Row(
                children: [
                  Icon(Icons.paid_outlined, color: Colors.white, size: _ui(context, 15)),
                  SizedBox(width: _ui(context, 5)),
                  Text(
                    '${homeController.coins}',
                    style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: _ui(context, 12)),
          LinkUpNotificationBell(
            icon: Icons.notifications_none,
            iconSize: _ui(context, 27),
            badgeSize: _ui(context, 20),
            badgeFontSize: _font(context, 10),
          ),
          SizedBox(width: _ui(context, 10)),
          LinkUpCurrentUserAvatar(
            radius: _ui(context, 17),
            innerRadius: _ui(context, 15),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage())),
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

  Widget _eatsToolbar(BuildContext context) {
    return Column(
      children: [
        Container(
          height: _ui(context, 44),
          padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xff15803d), Color(0xff22c55e)]),
          ),
          child: Row(
            children: [
              _topAction(context, Icons.arrow_back, 'Home', () => Get.off(() => HomePage())),
              SizedBox(width: _ui(context, 10)),
              Icon(Icons.restaurant, color: Colors.white, size: _ui(context, 16)),
              SizedBox(width: _ui(context, 4)),
              Text('LinkUp Eats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: _font(context, 15))),
              const Spacer(),
              _greenPill(context, Icons.calendar_month, 'Reservations', _openReservations),
              SizedBox(width: _ui(context, 6)),
              _greenPill(context, Icons.refresh, 'Eats Home', () => setState(() => _mode = _EatsMode.gate)),
            ],
          ),
        ),
        Container(
          height: _ui(context, 92),
          padding: EdgeInsets.symmetric(horizontal: _ui(context, 16), vertical: _ui(context, 12)),
          color: const Color(0xff0b2942),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Home delivery mode', style: TextStyle(color: const Color(0xff9EDB2F), fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
                  SizedBox(height: _ui(context, 6)),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: _ui(context, 12), vertical: _ui(context, 7)),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 12))),
                        child: Row(
                          children: [
                            Text('Link', style: TextStyle(color: const Color(0xff2f9bef), fontSize: _font(context, 17), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                            Text('üp', style: TextStyle(color: const Color(0xffffe14d), fontSize: _font(context, 17), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      SizedBox(width: _ui(context, 10)),
                      Text('Eats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: _font(context, 26))),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _headerCircle(context, Icons.location_on_outlined, () => _openRestaurantQrMode()),
              SizedBox(width: _ui(context, 8)),
              _headerCircle(context, Icons.account_balance_wallet_outlined, () => _openWalletFromEats()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_ui(context, 18)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: _ui(context, 16)),
          SizedBox(width: _ui(context, 3)),
          Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
        ],
      ),
    );
  }

  Widget _greenPill(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_ui(context, 18)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 9), vertical: _ui(context, 5)),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), borderRadius: BorderRadius.circular(_ui(context, 18))),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: _ui(context, 13)),
            SizedBox(width: _ui(context, 3)),
            Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: _font(context, 10))),
          ],
        ),
      ),
    );
  }

  Widget _headerCircle(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_ui(context, 20)),
      child: Container(
        width: _ui(context, 38),
        height: _ui(context, 38),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: _ui(context, 21)),
      ),
    );
  }

  Widget _orderingGate(BuildContext context) {
    return Container(
      key: const ValueKey('gate'),
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.fromLTRB(_ui(context, 20), _ui(context, 112), _ui(context, 20), _ui(context, 24)),
        children: [
          Center(
            child: Container(
              width: _ui(context, 76),
              height: _ui(context, 76),
              decoration: BoxDecoration(
                color: const Color(0xff9EDB2F),
                borderRadius: BorderRadius.circular(_ui(context, 22)),
              ),
              child: Icon(Icons.restaurant, color: Colors.white, size: _ui(context, 34)),
            ),
          ),
          SizedBox(height: _ui(context, 20)),
          Text(
            'How are you ordering?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: _font(context, 28), fontWeight: FontWeight.w900, color: const Color(0xff0f172a), height: 1.05),
          ),
          SizedBox(height: _ui(context, 12)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _ui(context, 10)),
            child: Text(
              'The app changes based on whether the customer is home or inside the restaurant.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: _font(context, 15), color: const Color(0xff64748b), fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
          SizedBox(height: _ui(context, 34)),
          _orderChoice(
            context,
            color: const Color(0xff9EDB2F),
            icon: Icons.home_outlined,
            title: 'Order from Home',
            subtitle: 'Shows address, pin, delivery fee, driver, and tracking.',
            onTap: () => setState(() => _mode = _EatsMode.restaurants),
          ),
          SizedBox(height: _ui(context, 16)),
          _orderChoice(
            context,
            color: const Color(0xff0f5575),
            icon: Icons.qr_code_scanner,
            title: 'Scan QR at Restaurant',
            subtitle: 'Shows only table menu, cart, payment, and kitchen fulfillment.',
            onTap: () => setState(() => _mode = _EatsMode.qr),
          ),
        ],
      ),
    );
  }

  Widget _orderChoice(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_ui(context, 22)),
      child: Container(
        padding: EdgeInsets.all(_ui(context, 18)),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(_ui(context, 22)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.26), blurRadius: _ui(context, 18), offset: Offset(0, _ui(context, 10))),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: _ui(context, 46),
              height: _ui(context, 46),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(_ui(context, 14))),
              child: Icon(icon, color: Colors.white, size: _ui(context, 24)),
            ),
            SizedBox(width: _ui(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color == const Color(0xff9EDB2F) ? const Color(0xff075985) : Colors.white, fontWeight: FontWeight.w900, fontSize: _font(context, 20), height: 1.05)),
                  SizedBox(height: _ui(context, 4)),
                  Text(subtitle, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: _font(context, 13), height: 1.25)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrScreen(BuildContext context) {
    return Container(
      key: const ValueKey('qr'),
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.fromLTRB(_ui(context, 20), _ui(context, 105), _ui(context, 20), _ui(context, 28)),
        children: [
          Center(
            child: Container(
              width: _ui(context, 154),
              height: _ui(context, 154),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffff690e), width: _ui(context, 4)),
                borderRadius: BorderRadius.circular(_ui(context, 20)),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.qr_code_2, color: const Color(0xff9EDB2F), size: _ui(context, 24)),
            ),
          ),
          SizedBox(height: _ui(context, 36)),
          Text(
            'Scan Restaurant QR',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: _font(context, 25), color: const Color(0xff0f172a)),
          ),
          SizedBox(height: _ui(context, 12)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _ui(context, 24)),
            child: Text(
              'This path does not show delivery address, driver, or home delivery features.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: _font(context, 15), height: 1.35, color: const Color(0xff64748b)),
            ),
          ),
          SizedBox(height: _ui(context, 34)),
          Center(
            child: ElevatedButton(
              onPressed: () => _showSnack('QR table loaded'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff9EDB2F),
                foregroundColor: const Color(0xff075985),
                elevation: 7,
                shadowColor: const Color(0xff9EDB2F).withOpacity(0.3),
                padding: EdgeInsets.symmetric(horizontal: _ui(context, 32), vertical: _ui(context, 15)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_ui(context, 14))),
              ),
              child: Text('Simulate QR Scan', style: TextStyle(fontSize: _font(context, 15), fontWeight: FontWeight.w900)),
            ),
          ),
          SizedBox(height: _ui(context, 32)),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 18), vertical: _ui(context, 14)),
              decoration: BoxDecoration(color: const Color(0xffedf8d1), borderRadius: BorderRadius.circular(_ui(context, 15))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Restaurant QR ID', style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
                  Text('LU-EATS-BEACHGRILL-TABLE-07', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 13), fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _restaurantsScreen(BuildContext context) {
    final restaurants = _filteredRestaurants;
    return Container(
      key: const ValueKey('restaurants'),
      color: const Color(0xffeaf4fe),
      child: ListView(
        padding: EdgeInsets.fromLTRB(_ui(context, 14), _ui(context, 20), _ui(context, 14), _ui(context, 18)),
        physics: const BouncingScrollPhysics(),
        children: [
          _deliveryInfoCard(context),
          SizedBox(height: _ui(context, 16)),
          _deliveryMapCard(context),
          SizedBox(height: _ui(context, 24)),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: _ui(context, 52),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 14))),
                  padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: const Color(0xff94a3b8), size: _ui(context, 22)),
                      SizedBox(width: _ui(context, 10)),
                      Expanded(
                        child: TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Search food or restaurant'),
                          style: TextStyle(fontSize: _font(context, 15), fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _ui(context, 20)),
          SizedBox(
            height: _ui(context, 44),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => SizedBox(width: _ui(context, 10)),
              itemBuilder: (context, index) {
                final c = _categories[index];
                final selected = c == _category;
                return InkWell(
                  onTap: () => setState(() => _category = c),
                  borderRadius: BorderRadius.circular(_ui(context, 22)),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: _ui(context, 20)),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xff0b2942) : Colors.white,
                      borderRadius: BorderRadius.circular(_ui(context, 22)),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xff0f172a),
                        fontWeight: FontWeight.w900,
                        fontSize: _font(context, 14),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: _ui(context, 24)),
          ...restaurants.map((r) => _restaurantCard(context, r)).toList(),
          SizedBox(height: _ui(context, 24)),
          _customerTools(context),
        ],
      ),
    );
  }

  Widget _deliveryInfoCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 18)),
      decoration: BoxDecoration(
        color: const Color(0xfff7fee7),
        borderRadius: BorderRadius.circular(_ui(context, 24)),
        border: Border.all(color: const Color(0xffd9f99d), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOME DELIVERY TO', style: TextStyle(color: const Color(0xff15803d), fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
                SizedBox(height: _ui(context, 4)),
                Text('Nassau, Bahamas', style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
                Text('Pin not set yet', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 13), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openSetLocationSheet(context),
            child: Text('Set Pin', style: TextStyle(color: const Color(0xff168eea), fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
          ),
        ],
      ),
    );
  }

  Widget _deliveryMapCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(
        color: const Color(0xfff1ede9),
        borderRadius: BorderRadius.circular(_ui(context, 28)),
        border: Border.all(color: const Color(0xff9EDB2F), width: 1.2),
      ),
      child: Container(
        padding: EdgeInsets.all(_ui(context, 18)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 22)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery Map', style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
                      Text('Visible only for home orders', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 13), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Container(
                  width: _ui(context, 44),
                  height: _ui(context, 44),
                  decoration: BoxDecoration(color: const Color(0xff9EDB2F), borderRadius: BorderRadius.circular(_ui(context, 14))),
                  child: Icon(Icons.near_me, color: Colors.white, size: _ui(context, 24)),
                ),
              ],
            ),
            SizedBox(height: _ui(context, 16)),
            _coordRow(context, 'Lat:', '25.0443'),
            SizedBox(height: _ui(context, 10)),
            _coordRow(context, 'Lng:', '-77.3504'),
          ],
        ),
      ),
    );
  }

  Widget _coordRow(BuildContext context, String label, String val) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 14), vertical: _ui(context, 12)),
      decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(_ui(context, 16))),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: const Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: _font(context, 13))),
          SizedBox(width: _ui(context, 8)),
          Text(val, style: TextStyle(color: const Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: _font(context, 13))),
        ],
      ),
    );
  }

  Widget _restaurantCard(BuildContext context, _Restaurant r) {
    return InkWell(
      onTap: () => setState(() {
        _selectedRestaurant = r;
        _mode = _EatsMode.restaurantDetails;
      }),
      child: Container(
        margin: EdgeInsets.only(bottom: _ui(context, 20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(r.image, height: _ui(context, 180), width: double.infinity, fit: BoxFit.cover),
                Positioned(
                  right: _ui(context, 12),
                  top: _ui(context, 12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: _ui(context, 10), vertical: _ui(context, 4)),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 6))),
                    child: Text('BSD', style: TextStyle(color: const Color(0xff0b2942), fontWeight: FontWeight.w900, fontSize: _font(context, 11))),
                  ),
                ),
                Positioned(
                  right: _ui(context, 12),
                  top: _ui(context, 48),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: _ui(context, 8), vertical: _ui(context, 4)),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 8))),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: const Color(0xff0f172a), size: _ui(context, 14)),
                        SizedBox(width: _ui(context, 4)),
                        Text(r.rating, style: TextStyle(color: const Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: _font(context, 15))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(_ui(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(r.name, style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 20), fontWeight: FontWeight.w900))),
                    ],
                  ),
                  SizedBox(height: _ui(context, 4)),
                  Text('${r.category} · ${r.subCategory} · ${r.time} · ${r.distance}', style: TextStyle(color: const Color(0xff64748b), fontWeight: FontWeight.w700, fontSize: _font(context, 13))),
                  Text(r.location, style: TextStyle(color: const Color(0xff94a3b8), fontWeight: FontWeight.w700, fontSize: _font(context, 13))),
                  SizedBox(height: _ui(context, 4)),
                  Text('${r.priceLevel} menu', style: TextStyle(color: const Color(0xff94a3b8), fontWeight: FontWeight.w700, fontSize: _font(context, 13))),
                  SizedBox(height: _ui(context, 16)),
                  Row(
                    children: [
                      _toggleButton(context, 'Delivery', true, () => setState(() {
                        _selectedRestaurant = r;
                        _isDeliveryInDetails = true;
                        _mode = _EatsMode.restaurantDetails;
                      })),
                      SizedBox(width: _ui(context, 10)),
                      _toggleButton(context, 'Pickup', false, () => setState(() {
                        _selectedRestaurant = r;
                        _isDeliveryInDetails = false;
                        _mode = _EatsMode.restaurantDetails;
                      })),
                    ],
                  ),
                  SizedBox(height: _ui(context, 12)),
                  InkWell(
                    onTap: () => _openReservationSheet(context, r),
                    child: Container(
                      width: double.infinity,
                      height: _ui(context, 48),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xff0b2942), width: 1.5),
                        borderRadius: BorderRadius.circular(_ui(context, 12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month, color: const Color(0xff0b2942), size: _ui(context, 18)),
                          SizedBox(width: _ui(context, 8)),
                          Text('Reserve a Table', style: TextStyle(color: const Color(0xff0b2942), fontWeight: FontWeight.w900, fontSize: _font(context, 15))),
                        ],
                      ),
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

  Widget _toggleButton(BuildContext context, String label, bool active, [VoidCallback? onTap]) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_ui(context, 12)),
        child: Container(
          height: _ui(context, 40),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xff0b2942) : const Color(0xff9EDB2F),
            borderRadius: BorderRadius.circular(_ui(context, 12)),
          ),
          child: Text(label, style: TextStyle(color: active ? Colors.white : const Color(0xff0b2942), fontWeight: FontWeight.w900, fontSize: _font(context, 16))),
        ),
      ),
    );
  }

  Widget _customerTools(BuildContext context) {
    final isScheduled = _selectedTools.contains('Scheduled On');
    return Container(
      padding: EdgeInsets.all(_ui(context, 20)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 24))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Tools', style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
          SizedBox(height: _ui(context, 16)),
          Wrap(
            spacing: _ui(context, 10),
            runSpacing: _ui(context, 10),
            children: [
              _toolChip(context, 'Favorites', const Color(0xffecfdf5), const Color(0xff065f46)),
              _toolChip(context, 'Reorder Last', const Color(0xfff0fdf4), const Color(0xff166534)),
              _toolChip(context, isScheduled ? 'Scheduled On' : 'Schedule Delivery', const Color(0xfff8fafc), const Color(0xff334155)),
              _toolChip(context, 'Rewards', const Color(0xfff8fafc), const Color(0xff334155)),
            ],
          ),
          if (isScheduled) ...[
            SizedBox(height: _ui(context, 20)),
            _scheduledDeliveryCard(context),
          ],
        ],
      ),
    );
  }

  Widget _toolChip(BuildContext context, String label, Color bg, Color text) {
    final displayLabel = label == 'Scheduled On' ? 'Scheduled On' : label == 'Schedule Delivery' ? 'Schedule Delivery' : label;
    final isSelected = _selectedTools.contains(displayLabel) || (label == 'Scheduled On' && _selectedTools.contains('Scheduled On'));

    // Adjust label for selection check
    String checkLabel = label;
    if (label == 'Scheduled On') checkLabel = 'Scheduled On';
    if (label == 'Schedule Delivery') checkLabel = 'Scheduled On';

    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedTools.contains(checkLabel)) {
            _selectedTools.remove(checkLabel);
          } else {
            _selectedTools.add(checkLabel);
            if (checkLabel == 'Scheduled On' && _scheduledTime == null) {
              _selectDateTime(context);
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(_ui(context, 14)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 16), vertical: _ui(context, 10)),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xfff7fee7) : const Color(0xfff1f5f9),
          borderRadius: BorderRadius.circular(_ui(context, 14)),
          border: isSelected ? Border.all(color: const Color(0xffd9f99d), width: 1) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xff15803d) : const Color(0xff334155),
            fontWeight: FontWeight.w900,
            fontSize: _font(context, 14),
          ),
        ),
      ),
    );
  }

  Widget _restaurantDetailsScreen(BuildContext context) {
    final r = _selectedRestaurant;
    if (r == null) return const SizedBox();
    return Container(
      key: const ValueKey('restaurantDetails'),
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          Stack(
            children: [
              Image.network(r.image, height: _ui(context, 260), width: double.infinity, fit: BoxFit.cover),
              Positioned.fill(child: Container(color: Colors.black.withOpacity(0.35))),
              Positioned(
                left: _ui(context, 16),
                top: _ui(context, 16),
                child: GestureDetector(
                  onTap: () => setState(() => _mode = _EatsMode.restaurants),
                  child: Container(
                    width: _ui(context, 44),
                    height: _ui(context, 44),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.arrow_back, color: const Color(0xff0f172a), size: _ui(context, 24)),
                  ),
                ),
              ),
              Positioned(
                left: _ui(context, 16),
                bottom: _ui(context, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: _ui(context, 12), vertical: _ui(context, 6)),
                      decoration: BoxDecoration(color: const Color(0xff9EDB2F), borderRadius: BorderRadius.circular(_ui(context, 12))),
                      child: Text('Home delivery / pickup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: _font(context, 12))),
                    ),
                    SizedBox(height: _ui(context, 10)),
                    Text(r.name, style: TextStyle(color: Colors.white, fontSize: _font(context, 28), fontWeight: FontWeight.w900)),
                    Text('${r.category} · ${r.subCategory} · ${r.time} · ${r.distance}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: _font(context, 14))),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(_ui(context, 16)),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(_ui(context, 18)),
                  decoration: BoxDecoration(
                    color: const Color(0xfff7fee7),
                    borderRadius: BorderRadius.circular(_ui(context, 24)),
                    border: Border.all(color: const Color(0xffd9f99d), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Home Order Type', style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
                      SizedBox(height: _ui(context, 14)),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isDeliveryInDetails = false),
                            child: Text('Pickup', style: TextStyle(color: !_isDeliveryInDetails ? const Color(0xff0b2942) : const Color(0xff94a3b8), fontWeight: FontWeight.w900, fontSize: _font(context, 18))),
                          ),
                          SizedBox(width: _ui(context, 10)),
                          GestureDetector(
                            onTap: () => setState(() => _isDeliveryInDetails = true),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: _ui(context, 10), vertical: _ui(context, 5)),
                              decoration: BoxDecoration(
                                color: _isDeliveryInDetails ? const Color(0xff0b2942) : Colors.transparent,
                                borderRadius: BorderRadius.circular(_ui(context, 10)),
                              ),
                              child: Text('Delivery', style: TextStyle(color: _isDeliveryInDetails ? Colors.white : const Color(0xff94a3b8), fontWeight: FontWeight.w900, fontSize: _font(context, 18))),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _ui(context, 12)),
                      Text(
                        _isDeliveryInDetails
                            ? 'Delivery fee: \$9.64. Based on country, distance, and surge logic.'
                            : 'Pickup selected. No delivery address, driver, or delivery fee.',
                        style: TextStyle(color: const Color(0xff64748b), fontWeight: FontWeight.w600, fontSize: _font(context, 14)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _ui(context, 24)),
                SizedBox(
                  height: _ui(context, 44),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _categoryPill(context, 'Popular'),
                      _categoryPill(context, 'Breakfast'),
                      _categoryPill(context, 'Curry & Roti'),
                      _categoryPill(context, 'Jerk & Grill'),
                    ],
                  ),
                ),
                SizedBox(height: _ui(context, 20)),
                ...r.menu.map((m) => _menuItemCard(context, m)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryPill(BuildContext context, String label) {
    final selected = _selectedDetailCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedDetailCategory = label),
      child: Container(
        margin: EdgeInsets.only(right: _ui(context, 10)),
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 18)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xff0b2942) : const Color(0xfff1f5f9),
          borderRadius: BorderRadius.circular(_ui(context, 22)),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
      ),
    );
  }

  Widget _menuItemCard(BuildContext context, _MenuItem m) {
    return InkWell(
      onTap: () => _openAddItemSheet(context, m),
      child: Container(
        margin: EdgeInsets.only(bottom: _ui(context, 16)),
        padding: EdgeInsets.all(_ui(context, 14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 20)),
          border: Border.all(color: const Color(0xfff1f5f9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: _ui(context, 100),
              height: _ui(context, 100),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_ui(context, 16)),
                image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=70'), fit: BoxFit.cover),
              ),
            ),
            SizedBox(width: _ui(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(m.name, style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 16), fontWeight: FontWeight.w900))),
                      Text('\$${m.price.toStringAsFixed(2)}', style: TextStyle(color: const Color(0xff2f9bef), fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
                    ],
                  ),
                  SizedBox(height: _ui(context, 6)),
                  Text(m.desc, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff64748b), fontWeight: FontWeight.w600, fontSize: _font(context, 13), height: 1.3)),
                  SizedBox(height: _ui(context, 10)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: _ui(context, 14), vertical: _ui(context, 6)),
                    decoration: BoxDecoration(color: const Color(0xfff7fee7), borderRadius: BorderRadius.circular(_ui(context, 10))),
                    child: Text('Add', style: TextStyle(color: const Color(0xff15803d), fontWeight: FontWeight.w900, fontSize: _font(context, 13))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddItemSheet(BuildContext context, _MenuItem m) {
    int qty = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: _ui(context, 240),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1544025162-d76694265947?w=900&q=70'), fit: BoxFit.cover),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      padding: EdgeInsets.all(_ui(context, 20)),
                      shrinkWrap: true,
                      children: [
                        Text(m.name, style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 24), fontWeight: FontWeight.w900)),
                        SizedBox(height: _ui(context, 8)),
                        Text(m.desc, style: TextStyle(color: const Color(0xff64748b), fontWeight: FontWeight.w600, fontSize: _font(context, 15), height: 1.4)),
                        SizedBox(height: _ui(context, 16)),
                        Text('\$${m.price.toStringAsFixed(2)}', style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 22), fontWeight: FontWeight.w900)),
                        SizedBox(height: _ui(context, 24)),
                        Text('Special Instructions', style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
                        SizedBox(height: _ui(context, 12)),
                        Container(
                          padding: EdgeInsets.all(_ui(context, 12)),
                          decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(_ui(context, 16))),
                          child: TextField(
                            maxLines: 3,
                            decoration: const InputDecoration(border: InputBorder.none, hintText: 'No onions, extra sauce, well done...', hintStyle: TextStyle(color: Color(0xff94a3b8))),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: _font(context, 14)),
                          ),
                        ),
                        SizedBox(height: _ui(context, 32)),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(_ui(context, 14))),
                              child: Row(
                                children: [
                                  _qtyBtn(context, Icons.remove, () => setSheetState(() => qty = qty > 1 ? qty - 1 : 1)),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
                                    child: Text('$qty', style: TextStyle(fontWeight: FontWeight.w900, fontSize: _font(context, 18), color: const Color(0xff0f172a))),
                                  ),
                                  _qtyBtn(context, Icons.add, () => setSheetState(() => qty++)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: Container(
                                height: _ui(context, 54),
                                padding: EdgeInsets.symmetric(horizontal: _ui(context, 32)),
                                decoration: BoxDecoration(color: const Color(0xff9EDB2F), borderRadius: BorderRadius.circular(_ui(context, 14))),
                                child: Center(child: Text('Add to Cart', style: TextStyle(color: const Color(0xff0b2942), fontWeight: FontWeight.w900, fontSize: _font(context, 16)))),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _ui(context, 20)),
                        Center(
                          child: TextButton(
                            onPressed: () => Get.back(),
                            child: Text('Cancel', style: TextStyle(color: const Color(0xff64748b), fontWeight: FontWeight.w900, fontSize: _font(context, 16))),
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

  Widget _qtyBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _ui(context, 38),
        height: _ui(context, 38),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xff0f172a), size: _ui(context, 20)),
      ),
    );
  }

  Widget _scheduledDeliveryCard(BuildContext context) {
    final format = DateFormat('MM/dd/yyyy, hh:mm a');
    return Container(
      padding: EdgeInsets.all(_ui(context, 18)),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(_ui(context, 20)),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scheduled Delivery', style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 15), fontWeight: FontWeight.w900)),
          SizedBox(height: _ui(context, 12)),
          InkWell(
            onTap: () => _selectDateTime(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 16), vertical: _ui(context, 14)),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 14))),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _scheduledTime != null ? format.format(_scheduledTime!) : 'Select Date & Time',
                      style: TextStyle(color: const Color(0xff0f172a), fontWeight: FontWeight.w700, fontSize: _font(context, 14)),
                    ),
                  ),
                  Icon(Icons.calendar_month_outlined, color: const Color(0xff0f172a), size: _ui(context, 18)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledTime ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _scheduledTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          _selectedTools.add('Scheduled On');
        });
      }
    }
  }

  void _openReservationSheet(BuildContext context, _Restaurant r) {
    setState(() {
      _showResSuccess = false;
      _resName.text = "John Doe"; // Placeholder for demo
      _resPhone.text = "+1 242 555-0123";
      _resEmail.text = "john@example.com";
      _resSeatingArea = null;
      _resClimate = null;
      _resTableType = null;
      _resPositionView.clear();
      _resAccessibility.clear();
      _resOccasion = null;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.94),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showResSuccess ? _reservationSuccessView(context) : _reservationFormView(context, r, setSheetState),
              ),
            );
          },
        );
      },
    );
  }

  Widget _reservationFormView(BuildContext context, _Restaurant r, StateSetter setSheetState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHeader(context, 'Reserve a Table', '${r.name} · ${r.category}'),
        Flexible(
          child: ListView(
            padding: EdgeInsets.fromLTRB(_ui(context, 20), 0, _ui(context, 20), _ui(context, 32)),
            shrinkWrap: true,
            children: [
              _sectionLabel(context, 'Date & time'),
              _resDatePicker(context, setSheetState),
              SizedBox(height: _ui(context, 24)),
              _sectionLabel(context, 'Party size'),
              _partySizeSelector(context, setSheetState),
              SizedBox(height: _ui(context, 24)),
              _infoPill(context, 'Seating preferences for ${r.name}.'),
              SizedBox(height: _ui(context, 20)),
              _resSelectionGroup(context, 'Seating area', Icons.location_on_outlined, ['Indoor', 'Outdoor / Patio', 'Bar'], _resSeatingArea, (v) => setSheetState(() => _resSeatingArea = v)),
              SizedBox(height: _ui(context, 20)),
              _resSelectionGroup(context, 'Climate', Icons.wb_sunny_outlined, ['Air-conditioned', 'Open-air (no A/C)'], _resClimate, (v) => setSheetState(() => _resClimate = v)),
              SizedBox(height: _ui(context, 20)),
              _resSelectionGroup(context, 'Table type', Icons.restaurant_outlined, ['High-top', 'Low-top (standard)', 'Booth'], _resTableType, (v) => setSheetState(() => _resTableType = v)),
              SizedBox(height: _ui(context, 20)),
              _resMultiSelectionGroup(context, 'Position / view', '(choose any)', Icons.visibility_outlined, ['Window', 'Sea / waterfront', 'Quiet corner'], _resPositionView, (v) => setSheetState(() => _resPositionView.contains(v) ? _resPositionView.remove(v) : _resPositionView.add(v))),
              SizedBox(height: _ui(context, 20)),
              _resMultiSelectionGroup(context, 'Accessibility & family', '(choose any)', Icons.accessible_outlined, ['Wheelchair accessible', 'Ground floor', 'High chair / kids'], _resAccessibility, (v) => setSheetState(() => _resAccessibility.contains(v) ? _resAccessibility.remove(v) : _resAccessibility.add(v))),
              SizedBox(height: _ui(context, 24)),
              _sectionLabel(context, 'Occasion'),
              _occasionDropdown(context, setSheetState),
              SizedBox(height: _ui(context, 24)),
              _sectionLabel(context, 'Your details'),
              Row(
                children: [
                  Expanded(child: _resTextField(context, _resName, 'Your name')),
                  SizedBox(width: _ui(context, 12)),
                  Expanded(child: _resTextField(context, _resPhone, 'Phone')),
                ],
              ),
              SizedBox(height: _ui(context, 12)),
              _resTextField(context, _resEmail, 'Email (for your confirmation)'),
              SizedBox(height: _ui(context, 24)),
              _sectionLabel(context, 'Special requests', '(optional)'),
              _resTextField(context, _resSpecial, 'Quiet corner for an anniversary, birthday candle, allergy notes...', maxLines: 3),
              SizedBox(height: _ui(context, 32)),
              _primaryBtn(context, 'Request Reservation', () => setSheetState(() => _showResSuccess = true)),
              SizedBox(height: _ui(context, 12)),
              Center(child: TextButton(onPressed: () => Get.back(), child: Text('Cancel', style: TextStyle(color: const Color(0xff64748b), fontWeight: FontWeight.w900, fontSize: _font(context, 16))))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reservationSuccessView(BuildContext context) {
    final format = DateFormat('yyyy-MM-dd HH:mm');
    final seatingList = [
      if (_resSeatingArea != null) _resSeatingArea!,
      if (_resClimate != null) _resClimate!,
      if (_resTableType != null) _resTableType!,
      ..._resPositionView,
      ..._resAccessibility,
    ];
    final seating = seatingList.isEmpty ? 'Not specified' : seatingList.join(' · ');

    return Padding(
      padding: EdgeInsets.all(_ui(context, 24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: _ui(context, 40)),
          Container(
            width: _ui(context, 80),
            height: _ui(context, 80),
            decoration: const BoxDecoration(color: Color(0xfff7fee7), shape: BoxShape.circle),
            child: Icon(Icons.check, color: const Color(0xff15803d), size: _ui(context, 40)),
          ),
          SizedBox(height: _ui(context, 24)),
          Text('Reservation requested', style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 28), fontWeight: FontWeight.w900)),
          SizedBox(height: _ui(context, 8)),
          Text('${_selectedRestaurant?.name} will confirm your table shortly.', textAlign: TextAlign.center, style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 15), fontWeight: FontWeight.w600)),
          SizedBox(height: _ui(context, 32)),
          Container(
            padding: EdgeInsets.all(_ui(context, 20)),
            decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(_ui(context, 24)), border: Border.all(color: const Color(0xffe2e8f0))),
            child: Column(
              children: [
                _resSummaryRow(context, 'When:', format.format(_resDate)),
                _resSummaryRow(context, 'Party:', '$_partySize guests'),
                _resSummaryRow(context, 'Seating:', seating),
                _resSummaryRow(context, 'Occasion:', _resOccasion ?? 'Not specified'),
              ],
            ),
          ),
          SizedBox(height: _ui(context, 24)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_active_outlined, color: const Color(0xff0b5575), size: _ui(context, 18)),
              SizedBox(width: _ui(context, 8)),
              Text('In-app alert sent', style: TextStyle(color: const Color(0xff0b5575), fontWeight: FontWeight.w900, fontSize: _font(context, 15))),
            ],
          ),
          SizedBox(height: _ui(context, 8)),
          Text('Seating preferences are requests and subject to availability.', textAlign: TextAlign.center, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
          SizedBox(height: _ui(context, 40)),
          _primaryBtn(context, 'Done', () => Get.back()),
          SizedBox(height: _ui(context, 20)),
        ],
      ),
    );
  }

  Widget _sheetHeader(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.all(_ui(context, 20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.calendar_month_outlined, color: const Color(0xff0b2942), size: _ui(context, 28)),
          SizedBox(width: _ui(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 24), fontWeight: FontWeight.w900)),
                Text(subtitle, style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 15), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(onPressed: () => Get.back(), icon: Icon(Icons.close, color: const Color(0xff94a3b8), size: _ui(context, 28))),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label, [String? extra]) {
    return Padding(
      padding: EdgeInsets.only(bottom: _ui(context, 12)),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
          if (extra != null) ...[
            SizedBox(width: _ui(context, 6)),
            Text(extra, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 13), fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Widget _resDatePicker(BuildContext context, StateSetter setSheetState) {
    final format = DateFormat('MM/dd/yyyy, hh:mm a');
    return GestureDetector(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(context: context, initialDate: _resDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
        if (pickedDate != null) {
          final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_resDate));
          if (pickedTime != null) {
            setSheetState(() => _resDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute));
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 16), vertical: _ui(context, 16)),
        decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(_ui(context, 16))),
        child: Row(
          children: [
            Expanded(child: Text(format.format(_resDate), style: TextStyle(color: const Color(0xff0f172a), fontWeight: FontWeight.w700, fontSize: _font(context, 16)))),
            Icon(Icons.calendar_month, color: const Color(0xff0f172a), size: _ui(context, 20)),
          ],
        ),
      ),
    );
  }

  Widget _partySizeSelector(BuildContext context, StateSetter setSheetState) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 6)),
      decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(_ui(context, 16))),
      child: Row(
        children: [
          _qtyBtn(context, Icons.remove, () => setSheetState(() => _partySize = _partySize > 1 ? _partySize - 1 : 1)),
          Expanded(child: Center(child: Text('$_partySize', style: TextStyle(fontWeight: FontWeight.w900, fontSize: _font(context, 20), color: const Color(0xff0f172a))))),
          _qtyBtn(context, Icons.add, () => setSheetState(() => _partySize++)),
        ],
      ),
    );
  }

  Widget _infoPill(BuildContext context, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 14), vertical: _ui(context, 10)),
      decoration: BoxDecoration(color: const Color(0xfff7fee7), borderRadius: BorderRadius.circular(_ui(context, 14)), border: Border.all(color: const Color(0xffd9f99d))),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: const Color(0xff15803d), size: _ui(context, 16)),
          SizedBox(width: _ui(context, 10)),
          Expanded(child: Text(text, style: TextStyle(color: const Color(0xff15803d), fontWeight: FontWeight.w700, fontSize: _font(context, 13)))),
        ],
      ),
    );
  }

  Widget _resSelectionGroup(BuildContext context, String label, IconData icon, List<String> options, String? current, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xff9EDB2F), size: _ui(context, 18)),
            SizedBox(width: _ui(context, 8)),
            Text(label, style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 15), fontWeight: FontWeight.w900)),
          ],
        ),
        SizedBox(height: _ui(context, 12)),
        Wrap(
          spacing: _ui(context, 10),
          runSpacing: _ui(context, 10),
          children: options.map((o) => _selectionChip(context, o, o == current, () => onSelect(o))).toList(),
        ),
      ],
    );
  }

  Widget _resMultiSelectionGroup(BuildContext context, String label, String extra, IconData icon, List<String> options, Set<String> current, Function(String) onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xff9EDB2F), size: _ui(context, 18)),
            SizedBox(width: _ui(context, 8)),
            Text(label, style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 15), fontWeight: FontWeight.w900)),
            SizedBox(width: _ui(context, 6)),
            Text(extra, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 12), fontWeight: FontWeight.w700)),
          ],
        ),
        SizedBox(height: _ui(context, 12)),
        Wrap(
          spacing: _ui(context, 10),
          runSpacing: _ui(context, 10),
          children: options.map((o) => _selectionChip(context, o, current.contains(o), () => onToggle(o))).toList(),
        ),
      ],
    );
  }

  Widget _selectionChip(BuildContext context, String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_ui(context, 12)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 18), vertical: _ui(context, 12)),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff0b2942) : Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 12)),
          border: Border.all(color: selected ? const Color(0xff0b2942) : const Color(0xffcbd5e1), width: 1.2),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xff0b2942), fontWeight: FontWeight.w900, fontSize: _font(context, 14))),
      ),
    );
  }

  Widget _occasionDropdown(BuildContext context, StateSetter setSheetState) {
    final options = ['Business meal', 'Birthday', 'Anniversary', 'Date night', 'Other'];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
      decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(_ui(context, 16))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _resOccasion,
          hint: Text('Select occasion', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 14))),
          icon: Icon(Icons.expand_more, color: const Color(0xff0f172a)),
          isExpanded: true,
          style: TextStyle(color: const Color(0xff0f172a), fontWeight: FontWeight.w700, fontSize: _font(context, 16)),
          onChanged: (v) => setSheetState(() => _resOccasion = v!),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        ),
      ),
    );
  }

  Widget _resTextField(BuildContext context, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 16), vertical: maxLines > 1 ? _ui(context, 12) : 0),
      decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(_ui(context, 16))),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 14))),
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: _font(context, 14)),
      ),
    );
  }

  Widget _primaryBtn(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: _ui(context, 58),
        decoration: BoxDecoration(color: const Color(0xff0b2942), borderRadius: BorderRadius.circular(_ui(context, 16))),
        child: Center(child: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: _font(context, 18)))),
      ),
    );
  }

  Widget _resSummaryRow(BuildContext context, String label, String val) {
    return Padding(
      padding: EdgeInsets.only(bottom: _ui(context, 12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: const Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: _font(context, 15))),
          SizedBox(width: _ui(context, 8)),
          Expanded(child: Text(val, style: TextStyle(color: const Color(0xff334155), fontWeight: FontWeight.w700, fontSize: _font(context, 15)))),
        ],
      ),
    );
  }

  void _openSetLocationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHeader(context, 'Set Home Delivery Location', ''),
                  Flexible(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(_ui(context, 20), 0, _ui(context, 20), _ui(context, 32)),
                      shrinkWrap: true,
                      children: [
                        Text('This appears only when ordering from home.', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 15), fontWeight: FontWeight.w600)),
                        SizedBox(height: _ui(context, 24)),
                        _locationDropdown(context, setSheetState),
                        SizedBox(height: _ui(context, 12)),
                        _locationField(context, _deliveryStreet, 'Street address, building, settlement, city'),
                        SizedBox(height: _ui(context, 12)),
                        _locationField(context, _deliveryLat, 'Latitude'),
                        SizedBox(height: _ui(context, 12)),
                        _locationField(context, _deliveryLng, 'Longitude'),
                        SizedBox(height: _ui(context, 24)),
                        _mapPreviewCard(context),
                        SizedBox(height: _ui(context, 32)),
                        Row(
                          children: [
                            Expanded(child: _outlineBtn(context, 'Use Current GPS', () {})),
                            SizedBox(width: _ui(context, 12)),
                            Expanded(child: _primaryBtn(context, 'Save Pin', () => Get.back())),
                          ],
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

  Widget _locationDropdown(BuildContext context, StateSetter setSheetState) {
    final options = [
      'The Valley, Anguilla (XCD)',
      'St. John\'s, Antigua and Barbuda (XCD)',
      'Oranjestad, Aruba (AWG)',
      'Nassau, Bahamas (BSD)',
      'Bridgetown, Barbados (BBD)',
      'Belize City, Belize (BZD)',
      'Hamilton, Bermuda (BMD)',
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
      decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(_ui(context, 16))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _deliveryCity,
          icon: Icon(Icons.expand_more, color: const Color(0xff0f172a)),
          isExpanded: true,
          style: TextStyle(color: const Color(0xff0f172a), fontWeight: FontWeight.w700, fontSize: _font(context, 16)),
          onChanged: (v) => setSheetState(() => _deliveryCity = v!),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        ),
      ),
    );
  }

  Widget _locationField(BuildContext context, String initial, String hint) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 16), vertical: _ui(context, 12)),
      decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(_ui(context, 16))),
      child: Text(initial, style: TextStyle(color: const Color(0xff0f172a), fontWeight: FontWeight.w700, fontSize: _font(context, 16))),
    );
  }

  Widget _mapPreviewCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_ui(context, 20)),
      decoration: BoxDecoration(
        color: const Color(0xfff1ede9),
        borderRadius: BorderRadius.circular(_ui(context, 28)),
        border: Border.all(color: const Color(0xff9EDB2F), width: 1.2),
      ),
      child: Container(
        height: _ui(context, 240),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 22))),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(_ui(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Google Maps Pin Preview', style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
                  Text('Production version uses Places Autocomplete and draggable pin.', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 13), fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Spacer(),
            Center(child: _pulsingMarker(context)),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _pulsingMarker(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _ui(context, 120) * _pulseController.value,
              height: _ui(context, 120) * _pulseController.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xffef3e6d).withOpacity(1 - _pulseController.value),
              ),
            ),
            Container(
              width: _ui(context, 76),
              height: _ui(context, 76),
              decoration: const BoxDecoration(color: Color(0xff9EDB2F), shape: BoxShape.circle),
              child: Icon(Icons.location_on, color: Colors.white, size: _ui(context, 34)),
            ),
          ],
        );
      },
    );
  }

  Widget _outlineBtn(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: _ui(context, 58),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xffcbd5e1), width: 1.5), borderRadius: BorderRadius.circular(_ui(context, 16))),
        child: Center(child: Text(label, style: TextStyle(color: const Color(0xff0f172a), fontWeight: FontWeight.w900, fontSize: _font(context, 16)))),
      ),
    );
  }

  void _openReservations() {
    int tab = 1;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_ui(context, 20)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: _ui(context, 34), offset: Offset(0, _ui(context, 16)))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: _ui(context, 58),
                      padding: EdgeInsets.symmetric(horizontal: _ui(context, 16)),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xff2f9bef), Color(0xff2487e0)]),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_available, color: Colors.white, size: _ui(context, 22)),
                          SizedBox(width: _ui(context, 8)),
                          Text('My Reservations', style: TextStyle(color: Colors.white, fontSize: _font(context, 24), fontWeight: FontWeight.w900)),
                          const Spacer(),
                          InkWell(
                            onTap: () => Get.back(),
                            child: Icon(Icons.close, color: Colors.white, size: _ui(context, 24)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(_ui(context, 16), _ui(context, 14), _ui(context, 16), 0),
                      child: Row(
                        children: [
                          Expanded(child: _reservationTab(context, 'Upcoming', tab == 0, () => setDialogState(() => tab = 0))),
                          SizedBox(width: _ui(context, 8)),
                          Expanded(child: _reservationTab(context, 'Past', tab == 1, () => setDialogState(() => tab = 1))),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: _ui(context, 218),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy_outlined, color: const Color(0xffcbd5e1), size: _ui(context, 38)),
                          SizedBox(height: _ui(context, 10)),
                          Text(
                            tab == 0 ? 'No upcoming reservations.' : 'No past reservations.',
                            style: TextStyle(color: const Color(0xff94a3b8), fontWeight: FontWeight.w900, fontSize: _font(context, 16)),
                          ),
                          SizedBox(height: _ui(context, 5)),
                          Text(
                            'Book a table from any restaurant in LinkUp Eats.',
                            style: TextStyle(color: const Color(0xffcbd5e1), fontWeight: FontWeight.w700, fontSize: _font(context, 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _reservationTab(BuildContext context, String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_ui(context, 18)),
      child: Container(
        height: _ui(context, 33),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xff2f9bef) : Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 18)),
          border: Border.all(color: selected ? const Color(0xff2f9bef) : const Color(0xffdbe7f4)),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : const Color(0xff334155), fontWeight: FontWeight.w900, fontSize: _font(context, 12)),
        ),
      ),
    );
  }

  void _openRestaurantQrMode() {
    if (_mode != _EatsMode.qr) {
      setState(() => _mode = _EatsMode.qr);
    }
  }

  void _openWalletFromEats() {
    Get.to(() => const WalletPage());
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 1100)),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final items = [
      [Icons.home_outlined, 'Home', false],
      [Icons.image_outlined, 'Vibes', false],
      [Icons.restaurant_outlined, 'Eats', true],
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
                if (item[1] == 'Home') Get.off(() => HomePage());
                if (item[1] == 'Vibes') Get.off(() => const VibesPage());
                if (item[1] == 'LinkUp') Get.off(() => ChatHomePage());
                if (item[1] == 'Live') Get.off(() => const LivePage());
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
                      color: selected ? Colors.white : const Color(0xff64748b),
                      size: _ui(context, 22),
                    ),
                  ),
                  SizedBox(height: _ui(context, 3)),
                  Text(
                    item[1] as String,
                    style: TextStyle(
                      color: selected ? const Color(0xff158fe8) : const Color(0xff64748b),
                      fontWeight: FontWeight.w900,
                      fontSize: _font(context, 10),
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

const List<String> _categories = ['All', 'Carib', 'Seafood', 'Latin', 'Breakfast', 'Drinks'];

class _Restaurant {
  final String name;
  final String category;
  final String subCategory;
  final String rating;
  final String time;
  final String distance;
  final String fee;
  final String location;
  final String priceLevel;
  final String image;
  final List<String> tags;
  final List<_MenuItem> menu;

  const _Restaurant({
    required this.name,
    required this.category,
    required this.subCategory,
    required this.rating,
    required this.time,
    required this.distance,
    required this.fee,
    required this.location,
    required this.priceLevel,
    required this.image,
    required this.tags,
    required this.menu,
  });

  static List<_Restaurant> seed() => const [
        _Restaurant(
          name: 'Island Flame Grill',
          category: 'Bahamian',
          subCategory: 'Grill',
          rating: '4.8',
          time: '25–35 min',
          distance: '3.5 km',
          fee: '\$3.99',
          location: 'Nassau, Bahamas',
          priceLevel: '\$',
          image: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=900&q=70',
          tags: ['Conch', 'Seafood', 'Local'],
          menu: [
            _MenuItem('Conch Fritters', 'Crispy golden fritters with island sauce', 12.50),
            _MenuItem('Cracked Conch', 'Tender conch, fries, slaw and lime', 18.00),
          ],
        ),
        _Restaurant(
          name: 'Conch Shack Express',
          category: 'Bahamian',
          subCategory: 'Seafood',
          rating: '4.7',
          time: '30–45 min',
          distance: '4.9 km',
          fee: '\$4.49',
          location: 'Nassau, Bahamas',
          priceLevel: '\$',
          image: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=900&q=70',
          tags: ['Jerk', 'Oxtail', 'Spicy'],
          menu: [
            _MenuItem('Jerk Chicken', 'Smoky jerk chicken with festival', 14.00),
            _MenuItem('Oxtail Plate', 'Slow cooked oxtail with rice and peas', 22.00),
          ],
        ),
      ];
}

class _MenuItem {
  final String name;
  final String desc;
  final double price;
  const _MenuItem(this.name, this.desc, this.price);
}
