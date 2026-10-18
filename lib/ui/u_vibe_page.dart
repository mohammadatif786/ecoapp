import 'package:flutter/material.dart';
import 'package:link_up/ui/profile/profile_page.dart';
import 'package:link_up/widgets/linkup_location_sheet.dart';
import '../widgets/linkup_current_user.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/home_controller.dart';
import 'package:link_up/ui/wallet_page.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/ui/chat_home_page.dart';
import 'package:link_up/ui/eats_page.dart';
import 'package:link_up/ui/home_page.dart';
import 'package:link_up/ui/live_page.dart';
import 'package:link_up/ui/notification_page.dart';
import 'package:link_up/ui/vibes_page.dart';

class UVibePage extends StatefulWidget {
  const UVibePage({Key? key}) : super(key: key);

  @override
  State<UVibePage> createState() => _UVibePageState();
}

class _UVibePageState extends State<UVibePage> {
  final HomeController homeController = Get.find(tag: HomeController().toString());
  late final AuthController authController;
  final ScrollController _scrollController = ScrollController();
  String _selectedCampus = 'All Campuses';
  String _selectedType = 'All';
  final List<_UPost> _posts = _UPost.seed();

  @override
  void initState() {
    super.initState();
    authController = Get.find(tag: AuthController().toString());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.90, 1.08).toDouble();
  }

  ImageProvider _avatarProvider() => LinkUpCurrentUser.avatarProvider();

  List<_UPost> get _visiblePosts {
    return _posts.where((post) {
      final campusOk = _selectedCampus == 'All Campuses' || post.campus == _selectedCampus;
      final typeOk = _selectedType == 'All' || post.type == _selectedType;
      return campusOk && typeOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final posts = _visiblePosts;
    return Scaffold(
      backgroundColor: const Color(0xffeaf4fe),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _topHeader(context),
            _geoBar(context),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.only(bottom: _ui(context, 14)),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xff5c35ed), Color(0xff7c3aed), Color(0xffc026d3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _uVibeHero(context),
                          _campusRail(context),
                          _typeRail(context),
                          SizedBox(height: _ui(context, 10)),
                          if (posts.isEmpty) _emptyState(context),
                          ...posts.map((post) => _postCard(context, post)).toList(),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: _ui(context, 220))),
                ],
              ),
            ),
            _bottomBar(context),
          ],
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
        gradient: LinearGradient(
          colors: [Color(0xff2f9bef), Color(0xff168eea)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
              child: Row(
                children: [
                  Icon(Icons.monetization_on_outlined, color: Colors.white, size: _ui(context, 16)),
                  SizedBox(width: _ui(context, 6)),
                  Text('${homeController.coins}', style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
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
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage())),
            child: CircleAvatar(radius: _ui(context, 16), backgroundColor: Colors.white, child: CircleAvatar(radius: _ui(context, 14), backgroundImage: _avatarProvider())),
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
      textColor: const Color(0xff26364d),
      changeColor: const Color(0xff168eea),
      iconColor: const Color(0xff2f9bef),
    );
  }

  Widget _uVibeHero(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 12), _ui(context, 12), _ui(context, 6)),
      child: Row(
        children: [
          Container(
            width: _ui(context, 42),
            height: _ui(context, 42),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), shape: BoxShape.circle),
            child: Icon(Icons.school_outlined, color: Colors.white, size: _ui(context, 24)),
          ),
          SizedBox(width: _ui(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('U Vibe', style: TextStyle(color: Colors.white, fontSize: _font(context, 24), fontWeight: FontWeight.w900, height: 1.0)),
                SizedBox(height: _ui(context, 3)),
                Text('University Vibes · cross-campus', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.90), fontSize: _font(context, 12), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showPostSheet(context),
            child: Container(
              height: _ui(context, 42),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 17)),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 24))),
              child: Row(
                children: [
                  Icon(Icons.add, color: const Color(0xff5137dc), size: _ui(context, 20)),
                  SizedBox(width: _ui(context, 4)),
                  Text('Post', style: TextStyle(color: const Color(0xff5137dc), fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campusRail(BuildContext context) {
    final campuses = const [
      ['All Campuses', '🎓'],
      ['UWI Mona', '🇯🇲'],
      ['UWI Cave Hill', '🇧🇧'],
      ['UWI St. Augustine', '🇹🇹'],
      ['Univ. Of Guyana', '🇬🇾'],
      ['Univ. Of The Bahamas', '🇧🇸'],
    ];
    return SizedBox(
      height: _ui(context, 38),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: campuses.length,
        separatorBuilder: (_, __) => SizedBox(width: _ui(context, 8)),
        itemBuilder: (context, index) {
          final campus = campuses[index][0];
          final active = _selectedCampus == campus;
          return _pill(context, '${campuses[index][1]} $campus', active, () => setState(() => _selectedCampus = campus));
        },
      ),
    );
  }

  Widget _typeRail(BuildContext context) {
    final types = const [
      ['All', Icons.grid_view_rounded],
      ['Events', Icons.event_note_outlined],
      ['Parties', Icons.celebration_outlined],
      ['Campus Life', Icons.apartment_outlined],
      ['Clubs', Icons.groups_outlined],
      ['Food', Icons.restaurant_outlined],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: _ui(context, 6)),
        SizedBox(
          height: _ui(context, 38),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: types.length,
            separatorBuilder: (_, __) => SizedBox(width: _ui(context, 8)),
            itemBuilder: (context, index) {
              final type = types[index][0] as String;
              final active = _selectedType == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: Container(
                  height: _ui(context, 34),
                  padding: EdgeInsets.symmetric(horizontal: _ui(context, 13)),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xff2f9bef) : Colors.white,
                    borderRadius: BorderRadius.circular(_ui(context, 18)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Icon(types[index][1] as IconData, color: active ? Colors.white : const Color(0xff475569), size: _ui(context, 17)),
                      SizedBox(width: _ui(context, 6)),
                      Text(type, style: TextStyle(color: active ? Colors.white : const Color(0xff26364d), fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: _ui(context, 12), top: _ui(context, 7)),
          child: Container(
            width: _ui(context, 264),
            height: _ui(context, 5),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.60), borderRadius: BorderRadius.circular(_ui(context, 5))),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _selectedType == 'All' ? 0.44 : 0.70,
              child: Container(decoration: BoxDecoration(color: const Color(0xff98c5f4), borderRadius: BorderRadius.circular(_ui(context, 5)))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(BuildContext context, String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: _ui(context, 32),
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 13)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withOpacity(0.20),
          borderRadius: BorderRadius.circular(_ui(context, 18)),
          border: Border.all(
            color: active ? Colors.white : Colors.white.withOpacity(0.36),
            width: active ? 1.2 : 1,
          ),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? const Color(0xff4f39dd) : Colors.white,
            fontSize: _font(context, 13),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 10), _ui(context, 12), _ui(context, 12)),
      padding: EdgeInsets.all(_ui(context, 18)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 20))),
      child: Column(
        children: [
          Icon(Icons.school_outlined, color: const Color(0xff8b5cf6), size: _ui(context, 34)),
          SizedBox(height: _ui(context, 8)),
          Text('No U Vibes here yet', style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 17), fontWeight: FontWeight.w900)),
          SizedBox(height: _ui(context, 4)),
          Text('Change the campus or type filter.', textAlign: TextAlign.center, style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _postCard(BuildContext context, _UPost post) {
    return Container(
      margin: EdgeInsets.fromLTRB(_ui(context, 12), 0, _ui(context, 12), _ui(context, 12)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 18)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 9, offset: const Offset(0, 4))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_ui(context, 18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 10), _ui(context, 12), _ui(context, 8)),
              child: Row(
                children: [
                  Container(
                    width: _ui(context, 42),
                    height: _ui(context, 42),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: post.logoColor, borderRadius: BorderRadius.circular(_ui(context, 11))),
                    child: Text(post.flag, style: TextStyle(fontSize: _font(context, 18))),
                  ),
                  SizedBox(width: _ui(context, 10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(post.campus, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 14), fontWeight: FontWeight.w900))),
                            SizedBox(width: _ui(context, 4)),
                            Icon(Icons.verified, color: const Color(0xff2f9bef), size: _ui(context, 15)),
                          ],
                        ),
                        SizedBox(height: _ui(context, 2)),
                        Text('${post.author} · ${post.time}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff7d8ba5), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: _ui(context, 10), vertical: _ui(context, 6)),
                    decoration: BoxDecoration(color: const Color(0xfff0ecff), borderRadius: BorderRadius.circular(_ui(context, 14))),
                    child: Text(post.type, style: TextStyle(color: const Color(0xff5936de), fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
            if (post.imageUrl != null)
              AspectRatio(
                aspectRatio: 1.92,
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, event) => event == null ? child : _imageFallback(context, post),
                  errorBuilder: (_, __, ___) => _imageFallback(context, post),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 12), _ui(context, 12), _ui(context, 4)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 18), height: 1.12, fontWeight: FontWeight.w900)),
                  ),
                  if (post.price != null) ...[
                    SizedBox(width: _ui(context, 8)),
                    Text('💸 ${post.price}', style: TextStyle(color: const Color(0xff059669), fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(_ui(context, 12), 0, _ui(context, 12), _ui(context, 12)),
              child: Text(post.body, style: TextStyle(color: const Color(0xff475569), fontSize: _font(context, 13), height: 1.35, fontWeight: FontWeight.w500)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(_ui(context, 12), 0, _ui(context, 12), _ui(context, 12)),
              child: Row(
                children: [
                  _action(context, Icons.favorite_border, post.likes),
                  SizedBox(width: _ui(context, 15)),
                  _action(context, Icons.chat_bubble_outline, post.comments),
                  SizedBox(width: _ui(context, 15)),
                  Icon(Icons.share_outlined, color: const Color(0xff64748b), size: _ui(context, 20)),
                  const Spacer(),
                  if (post.onVibes)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: _ui(context, 12), vertical: _ui(context, 8)),
                      decoration: BoxDecoration(color: const Color(0xffdffcef), borderRadius: BorderRadius.circular(_ui(context, 18))),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: const Color(0xff008f5a), size: _ui(context, 17)),
                          SizedBox(width: _ui(context, 4)),
                          Text('On Vibes', style: TextStyle(color: const Color(0xff008f5a), fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
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

  Widget _imageFallback(BuildContext context, _UPost post) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [post.logoColor.withOpacity(0.90), const Color(0xff7c3aed)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Icon(Icons.school_outlined, color: Colors.white.withOpacity(0.86), size: _ui(context, 56)),
    );
  }

  Widget _action(BuildContext context, IconData icon, String text) {
    return Row(children: [Icon(icon, color: const Color(0xff64748b), size: _ui(context, 20)), SizedBox(width: _ui(context, 5)), Text(text, style: TextStyle(color: const Color(0xff475569), fontSize: _font(context, 12), fontWeight: FontWeight.w800))]);
  }

  void _showPostSheet(BuildContext context) {
    String campus = '🇯🇲 UWI Mona';
    String type = 'Events';
    bool alsoOnVibes = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(top: _ui(context, 72), bottom: bottomInset),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24))),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(_ui(context, 16), _ui(context, 18), _ui(context, 16), _ui(context, 18)),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xff2f9bef), Color(0xff218fe9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24))),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.school_outlined, color: Colors.white, size: _ui(context, 22)),
                              SizedBox(width: _ui(context, 8)),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Post to U Vibe', style: TextStyle(color: Colors.white, fontSize: _font(context, 24), fontWeight: FontWeight.w900, height: 1)),
                                  SizedBox(height: _ui(context, 6)),
                                  Text('Share parties, events and campus life across universities.', style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                                ]),
                              ),
                              IconButton(onPressed: () => Navigator.of(sheetContext).pop(), icon: Icon(Icons.close, color: Colors.white, size: _ui(context, 28))),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(_ui(context, 16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel(context, 'YOUR CAMPUS'),
                              _selectBox(context, campus, ['🇯🇲 UWI Mona', '🇧🇧 UWI Cave Hill', '🇹🇹 UWI St. Augustine', '🇬🇾 Univ. Of Guyana', '🇧🇸 Univ. Of The Bahamas'], (v) => setModalState(() => campus = v)),
                              SizedBox(height: _ui(context, 16)),
                              _fieldLabel(context, 'TYPE'),
                              _selectBox(context, type, ['Events', 'Parties', 'Campus Life', 'Clubs', 'Food'], (v) => setModalState(() => type = v)),
                              SizedBox(height: _ui(context, 14)),
                              _inputBox(context, hint: 'Title (e.g. Campus Culture Night)', height: _ui(context, 50)),
                              SizedBox(height: _ui(context, 12)),
                              _inputBox(context, hint: 'What’s happening on campus?', height: _ui(context, 88), maxLines: 3),
                              SizedBox(height: _ui(context, 12)),
                              Container(
                                height: _ui(context, 64),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(_ui(context, 14)),
                                  border: Border.all(color: const Color(0xffc4b5fd), width: 1.6, style: BorderStyle.solid),
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image_outlined, color: const Color(0xff5137dc), size: _ui(context, 18)), SizedBox(width: _ui(context, 6)), Text('Add a photo', style: TextStyle(color: const Color(0xff5137dc), fontSize: _font(context, 15), fontWeight: FontWeight.w900))]),
                              ),
                              SizedBox(height: _ui(context, 12)),
                              _inputBox(context, hint: 'Entry price USD (optional, info only)', height: _ui(context, 50), keyboardType: TextInputType.number),
                              SizedBox(height: _ui(context, 12)),
                              GestureDetector(
                                onTap: () => setModalState(() => alsoOnVibes = !alsoOnVibes),
                                child: Container(
                                  padding: EdgeInsets.all(_ui(context, 12)),
                                  decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(_ui(context, 14))),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text('Also post on Vibes', style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
                                          SizedBox(height: _ui(context, 4)),
                                          Text('Appears in the main Vibes feed', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                                        ]),
                                      ),
                                      Container(
                                        width: _ui(context, 22),
                                        height: _ui(context, 22),
                                        decoration: BoxDecoration(color: alsoOnVibes ? const Color(0xff2f9bef) : Colors.white, borderRadius: BorderRadius.circular(_ui(context, 5)), border: Border.all(color: const Color(0xffcbd5e1))),
                                        child: alsoOnVibes ? Icon(Icons.check, color: Colors.white, size: _ui(context, 18)) : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: _ui(context, 14)),
                              SizedBox(
                                width: double.infinity,
                                height: _ui(context, 54),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(sheetContext).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: const Color(0xff2f9bef),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_ui(context, 16))),
                                  ),
                                  child: Text('Post to U Vibe', style: TextStyle(color: Colors.white, fontSize: _font(context, 17), fontWeight: FontWeight.w900)),
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
        );
      },
    );
  }

  Widget _fieldLabel(BuildContext context, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: _ui(context, 7)),
      child: Text(label, style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
    );
  }

  Widget _selectBox(BuildContext context, String value, List<String> options, ValueChanged<String> onChanged) {
    return Container(
      height: _ui(context, 50),
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xffe2e8f0), width: 1.3), borderRadius: BorderRadius.circular(_ui(context, 14))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(_ui(context, 14)),
          icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xff111827), size: _ui(context, 22)),
          items: options.map((item) => DropdownMenuItem<String>(value: item, child: Text(item, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 16), fontWeight: FontWeight.w900)))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _inputBox(BuildContext context, {required String hint, required double height, int maxLines = 1, TextInputType? keyboardType}) {
    return SizedBox(
      height: height,
      child: TextField(
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 15), fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: const Color(0xff9aa6b8), fontSize: _font(context, 15), fontWeight: FontWeight.w700),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: _ui(context, 16), vertical: _ui(context, 14)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 14)), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 14)), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 14)), borderSide: const BorderSide(color: Color(0xff2f9bef), width: 1.6)),
        ),
      ),
    );
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
                if (item[1] == 'Vibes') Get.to(() => const VibesPage());
                if (item[1] == 'Eats') Get.to(() => const EatsPage());
                if (item[1] == 'Live') Get.to(() => const LivePage());
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

class _UPost {
  final String campus;
  final String flag;
  final String author;
  final String time;
  final String type;
  final String title;
  final String body;
  final String? imageUrl;
  final String likes;
  final String comments;
  final String? price;
  final bool onVibes;
  final Color logoColor;

  const _UPost({
    required this.campus,
    required this.flag,
    required this.author,
    required this.time,
    required this.type,
    required this.title,
    required this.body,
    required this.likes,
    required this.comments,
    required this.logoColor,
    this.imageUrl,
    this.price,
    this.onVibes = false,
  });

  static List<_UPost> seed() => const [
        _UPost(
          campus: 'UWI St. Augustine',
          flag: '🇹🇹',
          author: 'Carnival Committee',
          time: '2h ago',
          type: 'Parties',
          title: 'Campus Carnival Fete 🎭',
          body: 'J’ouvert vibes, soca trucks & a steelpan set this Friday at the SAC quad. All campuses welcome!',
          imageUrl: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=900&q=75',
          likes: '214',
          comments: '28',
          price: r'$30',
          onVibes: true,
          logoColor: Color(0xffdc2626),
        ),
        _UPost(
          campus: 'Univ. Of The Bahamas',
          flag: '🇧🇸',
          author: 'UB Student Union',
          time: '4h ago',
          type: 'Student Union',
          title: 'Student Union elections — meet the candidates',
          body: 'Town hall Thursday 5pm in the Harry C. Moore Library. Bring your questions on tuition, housing & campus Wi-Fi.',
          likes: '88',
          comments: '12',
          logoColor: Color(0xff0891b2),
        ),
        _UPost(
          campus: 'UWI Mona',
          flag: '🇯🇲',
          author: 'Caribbean Students Assoc.',
          time: '7h ago',
          type: 'Clubs',
          title: 'Club fair on the lawns',
          body: 'Meet 30+ clubs, grab free merch, and sign up for semester projects. Food vendors open from noon.',
          imageUrl: 'https://images.unsplash.com/photo-1523580846011-d3a5bc25702b?w=900&q=75',
          likes: '156',
          comments: '20',
          logoColor: Color(0xff111827),
        ),
        _UPost(
          campus: 'Univ. Of Guyana',
          flag: '🇬🇾',
          author: 'Faculty of Tech',
          time: '1d ago',
          type: 'Events',
          title: 'Caribbean Tech & Innovation Expo',
          body: 'Student startups pitch live. Guest judges from across the region. Recruiters attending.',
          imageUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=900&q=75',
          likes: '132',
          comments: '17',
          onVibes: true,
          logoColor: Color(0xff16a34a),
        ),
        _UPost(
          campus: 'UWI Cave Hill',
          flag: '🇧🇧',
          author: 'Campus Life',
          time: '1d ago',
          type: 'Campus Life',
          title: 'Late-night study shuttle schedule',
          body: 'Library shuttle now runs until 1am during midterms. Bring your student ID for pickup.',
          likes: '64',
          comments: '8',
          logoColor: Color(0xff7c3aed),
        ),
        _UPost(
          campus: 'UWI Mona',
          flag: '🇯🇲',
          author: 'Food Court',
          time: '2d ago',
          type: 'Food',
          title: 'Patty pop-up near lecture theatre 2',
          body: 'Hot patties, cocoa bread and sorrel. Student discount before 2pm.',
          imageUrl: 'https://images.unsplash.com/photo-1562967914-608f82629710?w=900&q=75',
          likes: '97',
          comments: '14',
          logoColor: Color(0xfff59e0b),
        ),
      ];
}
