import 'dart:async';

import 'package:link_up/ui/eats_page.dart';
import 'package:link_up/ui/live_page.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:link_up/ui/profile/profile_page.dart';
import 'package:link_up/widgets/linkup_location_sheet.dart';
import '../widgets/linkup_current_user.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/home_controller.dart';
import 'package:link_up/ui/wallet_page.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/introscreens/screensix.dart';
import 'package:link_up/ui/chat_home_page.dart';
import 'package:link_up/ui/home_page.dart';
import 'package:link_up/ui/notification_page.dart';
import 'package:link_up/ui/widgets/vibes_reference_ui.dart';
import 'package:share_plus/share_plus.dart';

class VibesPage extends StatefulWidget {
  final bool showComposer;
  const VibesPage({Key? key, this.showComposer = false}) : super(key: key);

  @override
  State<VibesPage> createState() => _VibesPageState();
}

class _VibesPageState extends State<VibesPage> {
  final HomeController homeController = Get.find(tag: HomeController().toString());
  final AuthController authController = Get.find(tag: AuthController().toString());
  final ScrollController _scrollController = ScrollController();
  final List<_VibePost> _posts = _VibePost.seed();
  final List<_StoryItem> _stories = _StoryItem.seed();
  final TextEditingController _storyCaptionController = TextEditingController();
  final Set<String> _likedPosts = <String>{};
  final Set<String> _savedPosts = <String>{};
  final Set<String> _repostedPosts = <String>{};
  final Map<String, List<_VibeComment>> _extraComments = <String, List<_VibeComment>>{};
  final Map<String, int> _bigUpBonus = <String, int>{};

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.9, 1.08).toDouble();
  }

  @override
  void initState() {
    super.initState();
    if (widget.showComposer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showNewVibeComposer(context);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _storyCaptionController.dispose();
    super.dispose();
  }

  String _postKey(_VibePost post) => '${post.user}|${post.caption}|${post.imageUrl}';

  void _runAfterSheetClosed(VoidCallback action) {
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      action();
    });
  }

  void _safeSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _closeSheet<T extends Object?>(BuildContext sheetContext, [T? result]) {
    FocusManager.instance.primaryFocus?.unfocus();
    final nav = Navigator.of(sheetContext);
    if (nav.canPop()) nav.pop<T>(result);
  }

  String _shareText(_VibePost post) {
    final tags = post.tags.isEmpty ? '' : ' ${post.tags.map((tag) => '#$tag').join(' ')}';
    return 'Check this LinkUp Vibe from ${post.user}: ${post.caption}$tags';
  }

  String _metricWithDelta(String base, int delta) {
    if (delta <= 0) return base;
    return base.endsWith('+') ? base : '$base+';
  }

  List<_VibeComment> _commentsFor(_VibePost post) {
    final key = _postKey(post);
    return <_VibeComment>[
      const _VibeComment('LO', '@olopie_25', 'This is everything 🔥 Caribbean to the world 🌎', '4d', likes: 4),
      const _VibeComment('PA', '@paul_notch', 'Big vibes! Love to see it 🙌', '4d', likes: 2),
      ...(_extraComments[key] ?? const <_VibeComment>[]),
    ];
  }

  ImageProvider _avatarProvider() => LinkUpCurrentUser.avatarProvider();

  @override
  Widget build(BuildContext context) {
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
                  SliverToBoxAdapter(child: _vibesHeaderStories(context)),
                  SliverToBoxAdapter(child: _composer(context)),
                  SliverList.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) => _postCard(context, _posts[index]),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: _ui(context, 12))),
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
      padding: EdgeInsets.only(
        top: topPad,
        left: _ui(context, 18),
        right: _ui(context, 14),
      ),
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
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(_ui(context, 24)),
              ),
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

  Widget _vibesHeaderStories(BuildContext context) {
    final heroHeight = _ui(context, 104);
    final storyTop = _ui(context, 86);
    final storyHeight = _ui(context, 102);
    final totalHeight = _ui(context, 198);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Container(
              padding: EdgeInsets.fromLTRB(_ui(context, 14), _ui(context, 12), _ui(context, 14), _ui(context, 12)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff6d3df4), Color(0xff2498ef), Color(0xffec4899)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(_ui(context, 26)),
                  bottomRight: Radius.circular(_ui(context, 26)),
                ),
              ),
              child: _heroContent(context),
            ),
          ),
          Positioned(
            top: storyTop,
            left: _ui(context, 9),
            right: _ui(context, 9),
            height: storyHeight,
            child: _storyRailCard(context),
          ),
          Positioned(
            top: storyTop + storyHeight + _ui(context, 5),
            left: _ui(context, 12),
            width: _ui(context, 204),
            height: _ui(context, 4),
            child: _storyProgress(context),
          ),
        ],
      ),
    );
  }

  Widget _heroContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: _ui(context, 5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✨ Vibes', style: TextStyle(color: Colors.white, fontSize: _font(context, 25), height: 1, fontWeight: FontWeight.w900)),
                SizedBox(height: _ui(context, 4)),
                Text('Photos, reels & shoppable moments', style: TextStyle(color: Colors.white.withOpacity(0.94), fontSize: _font(context, 11), fontWeight: FontWeight.w700, height: 1.15)),
              ],
            ),
          ),
        ),
        _heroIcon(context, Icons.search, () => _showSearchPeopleSheet(context)),
        SizedBox(width: _ui(context, 8)),
        _heroIcon(context, Icons.movie_creation_outlined, () => _showReelsViewer(context)),
        SizedBox(width: _ui(context, 8)),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _heroIcon(context, Icons.favorite_border, () => _showActivitySheet(context)),
            Positioned(
              right: -2,
              top: -6,
              child: Container(
                width: _ui(context, 18),
                height: _ui(context, 18),
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xffff3f72), shape: BoxShape.circle),
                child: Text('3', style: TextStyle(color: Colors.white, fontSize: _font(context, 9), fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
        SizedBox(width: _ui(context, 8)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showNewVibeComposer(context),
          child: Container(
            height: _ui(context, 37),
            padding: EdgeInsets.symmetric(horizontal: _ui(context, 13)),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(_ui(context, 24))),
            child: Row(children: [Icon(Icons.add, color: Colors.white, size: _ui(context, 17)), Text(' Post', style: TextStyle(color: Colors.white, fontSize: _font(context, 12), fontWeight: FontWeight.w900))]),
          ),
        ),
      ],
    );
  }

  Widget _heroIcon(BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: _ui(context, 36),
        height: _ui(context, 36),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: _ui(context, 20)),
      ),
    );
  }



  void _showSearchPeopleSheet(BuildContext context) {
    final searchController = TextEditingController();
    String query = '';
    final people = _VibePerson.seed();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final filtered = people.where((person) {
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return true;
              return person.handle.toLowerCase().contains(q) ||
                  person.name.toLowerCase().contains(q) ||
                  person.country.toLowerCase().contains(q) ||
                  person.place.toLowerCase().contains(q);
            }).toList();
            return SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.88),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 22))),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 26, offset: const Offset(0, -7))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(_ui(context, 13), _ui(context, 12), _ui(context, 8), _ui(context, 12)),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff4667f2), Color(0xff2f9bef), Color(0xffec4899)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 22))),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.search, color: Colors.white, size: _ui(context, 20)),
                                SizedBox(width: _ui(context, 8)),
                                Expanded(child: Text('Search people', style: TextStyle(color: Colors.white, fontSize: _font(context, 18), fontWeight: FontWeight.w900))),
                                IconButton(
                                  onPressed: () => _closeSheet(sheetContext),
                                  icon: Icon(Icons.close, color: Colors.white, size: _ui(context, 24)),
                                ),
                              ],
                            ),
                            SizedBox(height: _ui(context, 8)),
                            Container(
                              height: _ui(context, 40),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 22))),
                              child: TextField(
                                controller: searchController,
                                autofocus: false,
                                onChanged: (value) => setSheetState(() => query = value),
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.search, color: const Color(0xff8291a8), size: _ui(context, 19)),
                                  hintText: 'Search by name, @handle or place',
                                  hintStyle: TextStyle(color: const Color(0xff8a98ad), fontSize: _font(context, 13), fontWeight: FontWeight.w700),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.only(top: _ui(context, 10), right: _ui(context, 14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: _ui(context, 56),
                                      height: _ui(context, 56),
                                      decoration: const BoxDecoration(color: Color(0xffeef2ff), shape: BoxShape.circle),
                                      child: Icon(Icons.person_search_outlined, color: const Color(0xff6366f1), size: _ui(context, 28)),
                                    ),
                                    SizedBox(height: _ui(context, 10)),
                                    Text('No people found', style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 15), fontWeight: FontWeight.w900)),
                                    SizedBox(height: _ui(context, 3)),
                                    Text('Try another handle, name or island.', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 12), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 10), _ui(context, 12), _ui(context, 14)),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => SizedBox(height: _ui(context, 4)),
                                itemBuilder: (context, index) {
                                  final person = filtered[index];
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(_ui(context, 16)),
                                    onTap: () => _showVibeProfileSheet(sheetContext, person),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: _ui(context, 4), vertical: _ui(context, 7)),
                                      child: Row(
                                        children: [
                                          _personAvatar(context, person, size: 42),
                                          SizedBox(width: _ui(context, 11)),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(child: Text(person.handle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 13), fontWeight: FontWeight.w900))),
                                                    if (person.verified) ...[
                                                      SizedBox(width: _ui(context, 4)),
                                                      Icon(Icons.verified, color: const Color(0xff2f9bef), size: _ui(context, 14)),
                                                    ],
                                                  ],
                                                ),
                                                SizedBox(height: _ui(context, 2)),
                                                Text('${person.name} · ${person.country}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff617089), fontSize: _font(context, 11), fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right, color: const Color(0xffcbd5e1), size: _ui(context, 22)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(searchController.dispose);
  }

  void _showVibeProfileSheet(BuildContext context, _VibePerson person) {
    bool following = person.following;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) => SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(_ui(context, 16), _ui(context, 14), _ui(context, 16), _ui(context, 18)),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24)))) ,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _personAvatar(context, person, size: 64),
                      SizedBox(width: _ui(context, 13)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Flexible(child: Text(person.handle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 17), fontWeight: FontWeight.w900))),
                              if (person.verified) ...[SizedBox(width: _ui(context, 4)), Icon(Icons.verified, color: const Color(0xff2f9bef), size: _ui(context, 16))],
                            ]),
                            SizedBox(height: _ui(context, 3)),
                            Text('${person.name} · ${person.country}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 12), fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => _closeSheet(sheetContext), icon: Icon(Icons.close, color: const Color(0xff111827), size: _ui(context, 24))),
                    ],
                  ),
                  SizedBox(height: _ui(context, 15)),
                  Row(
                    children: [
                      _profileMetric(context, 'Vibes', person.vibes),
                      _profileMetric(context, 'Followers', person.followers),
                      _profileMetric(context, 'Big Ups', person.bigUps),
                    ],
                  ),
                  SizedBox(height: _ui(context, 14)),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => following = !following),
                          child: Container(
                            height: _ui(context, 44),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: following ? null : const LinearGradient(colors: [Color(0xff2f9bef), Color(0xff7c3aed)]),
                              color: following ? const Color(0xffeef2ff) : null,
                              borderRadius: BorderRadius.circular(_ui(context, 15)),
                            ),
                            child: Text(following ? 'Following' : 'Follow', style: TextStyle(color: following ? const Color(0xff4f46e5) : Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                      SizedBox(width: _ui(context, 10)),
                      Expanded(
                        child: Container(
                          height: _ui(context, 44),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: const Color(0xfff8fafc), border: Border.all(color: const Color(0xffe2e8f0)), borderRadius: BorderRadius.circular(_ui(context, 15))),
                          child: Text('Message', style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _ui(context, 14)),
                  GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: _ui(context, 6),
                    crossAxisSpacing: _ui(context, 6),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(6, (index) => ClipRRect(
                      borderRadius: BorderRadius.circular(_ui(context, 10)),
                      child: Image.network('https://picsum.photos/seed/${person.handle}-$index/300/300', fit: BoxFit.cover),
                    )),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _profileMetric(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 17), fontWeight: FontWeight.w900)),
          SizedBox(height: _ui(context, 2)),
          Text(label, style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 10), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _personAvatar(BuildContext context, _VibePerson person, {double size = 42}) {
    final scaled = _ui(context, size);
    return Container(
      width: scaled,
      height: scaled,
      padding: EdgeInsets.all(_ui(context, 1.7)),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xffff8a00), Color(0xffec4899), Color(0xff6366f1)])),
      child: ClipOval(
        child: person.imageUrl != null
            ? Image.network(person.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _personInitials(context, person.initials))
            : _personInitials(context, person.initials),
      ),
    );
  }

  Widget _personInitials(BuildContext context, String initials) {
    return Container(
      alignment: Alignment.center,
      color: const Color(0xff334155),
      child: Text(initials, style: TextStyle(color: Colors.white, fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
    );
  }

  void _showReelsViewer(BuildContext context) {
    final reels = _ReelItem.seed();
    final pageController = PageController();
    int currentPage = 0;
    bool muted = true;
    final followed = <String>{};

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close reels',
      barrierColor: Colors.black.withOpacity(0.62),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final reel = reels[currentPage];
            return SafeArea(
              top: false,
              bottom: false,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: _ui(context, 6), vertical: _ui(context, 10)),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(_ui(context, 20))),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Container(
                            height: MediaQuery.of(dialogContext).padding.top + _ui(context, 46),
                            padding: EdgeInsets.only(top: MediaQuery.of(dialogContext).padding.top, left: _ui(context, 13), right: _ui(context, 7)),
                            color: Colors.black,
                            child: Row(
                              children: [
                                Icon(Icons.movie_creation_outlined, color: Colors.white, size: _ui(context, 20)),
                                SizedBox(width: _ui(context, 7)),
                                Expanded(child: Text('Reels', style: TextStyle(color: Colors.white, fontSize: _font(context, 18), fontWeight: FontWeight.w900))),
                                IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: Icon(Icons.close, color: Colors.white, size: _ui(context, 24))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: PageView.builder(
                              controller: pageController,
                              scrollDirection: Axis.vertical,
                              itemCount: reels.length,
                              onPageChanged: (value) => setDialogState(() => currentPage = value),
                              itemBuilder: (context, index) {
                                final item = reels[index];
                                return _reelViewerPage(
                                  context,
                                  item,
                                  muted: muted,
                                  following: followed.contains(item.handle),
                                  onMute: () => setDialogState(() => muted = !muted),
                                  onFollow: () => setDialogState(() {
                                    if (followed.contains(item.handle)) {
                                      followed.remove(item.handle);
                                    } else {
                                      followed.add(item.handle);
                                    }
                                  }),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: _ui(context, 6),
                        top: MediaQuery.of(dialogContext).size.height * 0.16,
                        bottom: MediaQuery.of(dialogContext).size.height * 0.16,
                        child: Container(
                          width: _ui(context, 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(_ui(context, 8))),
                        ),
                      ),
                      Positioned(
                        right: _ui(context, 6),
                        top: MediaQuery.of(dialogContext).size.height * (0.16 + (currentPage / math.max(1, reels.length - 1)) * 0.56),
                        child: Container(width: _ui(context, 4), height: _ui(context, 46), decoration: BoxDecoration(color: Colors.white.withOpacity(0.30), borderRadius: BorderRadius.circular(_ui(context, 8)))),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(pageController.dispose);
  }

  Widget _reelViewerPage(BuildContext context, _ReelItem reel, {required bool muted, required bool following, required VoidCallback onMute, required VoidCallback onFollow}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(reel.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xff111827))),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.black.withOpacity(0.20), Colors.transparent, Colors.black.withOpacity(0.82)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
        ),
        Positioned(
          left: _ui(context, 13),
          top: _ui(context, 12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: _ui(context, 10), vertical: _ui(context, 6)),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.34), borderRadius: BorderRadius.circular(_ui(context, 18))),
            child: Row(children: [Icon(Icons.movie_creation_outlined, color: Colors.white, size: _ui(context, 14)), SizedBox(width: _ui(context, 5)), Text('Reels', style: TextStyle(color: Colors.white, fontSize: _font(context, 11), fontWeight: FontWeight.w900))]),
          ),
        ),
        Positioned(
          right: _ui(context, 14),
          top: _ui(context, 14),
          child: GestureDetector(
            onTap: onMute,
            child: Container(
              width: _ui(context, 37),
              height: _ui(context, 37),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.36), shape: BoxShape.circle),
              child: Icon(muted ? Icons.volume_off_outlined : Icons.volume_up_outlined, color: Colors.white, size: _ui(context, 20)),
            ),
          ),
        ),
        if (muted)
          Center(
            child: GestureDetector(
              onTap: onMute,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: _ui(context, 13), vertical: _ui(context, 8)),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.42), borderRadius: BorderRadius.circular(_ui(context, 20))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volume_off_outlined, color: Colors.white, size: _ui(context, 17)),
                    SizedBox(width: _ui(context, 6)),
                    Text('Tap to unmute', style: TextStyle(color: Colors.white, fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: _ui(context, 14),
          bottom: _ui(context, 128),
          child: Column(
            children: [
              _reelAction(context, Icons.favorite_border, reel.likes, Colors.white),
              SizedBox(height: _ui(context, 16)),
              _reelAction(context, Icons.chat_bubble_outline, reel.comments, Colors.white),
              SizedBox(height: _ui(context, 16)),
              _reelAction(context, Icons.monetization_on_outlined, reel.bigUps, const Color(0xffff8a00), label: 'Big Up'),
              SizedBox(height: _ui(context, 16)),
              _reelAction(context, Icons.send_outlined, '', Colors.white),
            ],
          ),
        ),
        Positioned(
          left: _ui(context, 13),
          right: _ui(context, 74),
          bottom: _ui(context, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: _ui(context, 35),
                    height: _ui(context, 35),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xff334155), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.4)),
                    child: Text(reel.initials, style: TextStyle(color: Colors.white, fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
                  ),
                  SizedBox(width: _ui(context, 8)),
                  Text(reel.handle, style: TextStyle(color: Colors.white, fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
                  SizedBox(width: _ui(context, 8)),
                  GestureDetector(
                    onTap: onFollow,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: _ui(context, 9), vertical: _ui(context, 5)),
                      decoration: BoxDecoration(color: following ? Colors.white.withOpacity(0.18) : Colors.white, borderRadius: BorderRadius.circular(_ui(context, 14)), border: Border.all(color: Colors.white.withOpacity(0.68))),
                      child: Text(following ? 'Following' : 'Follow', style: TextStyle(color: following ? Colors.white : const Color(0xff111827), fontSize: _font(context, 9.5), fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _ui(context, 10)),
              Text(reel.caption, style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w800, height: 1.2)),
              SizedBox(height: _ui(context, 7)),
              Row(children: [Icon(Icons.music_note, color: Colors.white, size: _ui(context, 13)), SizedBox(width: _ui(context, 5)), Expanded(child: Text(reel.music, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: _font(context, 11), fontWeight: FontWeight.w700)))]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reelAction(BuildContext context, IconData icon, String value, Color accent, {String? label}) {
    final isBigUp = label != null;
    return Column(
      children: [
        Container(
          width: _ui(context, 42),
          height: _ui(context, 42),
          decoration: BoxDecoration(
            color: isBigUp ? null : Colors.black.withOpacity(0.34),
            gradient: isBigUp ? const LinearGradient(colors: [Color(0xffff8a00), Color(0xffec4899)]) : null,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: _ui(context, 23)),
        ),
        if (value.isNotEmpty) ...[
          SizedBox(height: _ui(context, 4)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
        ],
        if (label != null) Text(label, style: TextStyle(color: Colors.white, fontSize: _font(context, 9), fontWeight: FontWeight.w900)),
      ],
    );
  }

  void _showActivitySheet(BuildContext context) {
    int selectedTab = 0;
    final tabs = ['All', 'People you follow', 'Comments'];
    final activities = _ActivityItem.seed();
    final followed = <String>{};

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final visible = activities.where((item) {
              if (selectedTab == 1) return item.fromFollowing;
              if (selectedTab == 2) return item.type == 'comment';
              return true;
            }).toList();
            final today = visible.where((item) => item.group == 'Today').toList();
            final yesterday = visible.where((item) => item.group == 'Yesterday').toList();
            return SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.86),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 22))), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 24, offset: const Offset(0, -8))]),
                  child: Column(
                    children: [
                      Container(
                        height: _ui(context, 62),
                        padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xffedf2f7)))),
                        child: Row(
                          children: [
                            Icon(Icons.favorite_border, color: const Color(0xffff3f72), size: _ui(context, 22)),
                            SizedBox(width: _ui(context, 8)),
                            Expanded(child: Text('Activity', style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 22), fontWeight: FontWeight.w900))),
                            IconButton(onPressed: () => _closeSheet(sheetContext), icon: Icon(Icons.close, color: const Color(0xff111827), size: _ui(context, 24))),
                          ],
                        ),
                      ),
                      Container(
                        height: _ui(context, 58),
                        padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
                        decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xffedf2f7)))),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: tabs.length,
                          separatorBuilder: (_, __) => SizedBox(width: _ui(context, 8)),
                          itemBuilder: (context, index) {
                            final selected = selectedTab == index;
                            return Center(
                              child: GestureDetector(
                                onTap: () => setSheetState(() => selectedTab = index),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: _ui(context, 14), vertical: _ui(context, 9)),
                                  decoration: BoxDecoration(color: selected ? const Color(0xffeef6ff) : const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(_ui(context, 18))),
                                  child: Text(tabs[index], style: TextStyle(color: selected ? const Color(0xff1985ff) : const Color(0xff45546b), fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(_ui(context, 14), _ui(context, 12), _ui(context, 12), _ui(context, 18)),
                          children: [
                            if (today.isNotEmpty) _activityGroup(context, 'Today', today, followed, setSheetState),
                            if (yesterday.isNotEmpty) _activityGroup(context, 'Yesterday', yesterday, followed, setSheetState),
                            if (visible.isEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: _ui(context, 88)),
                                child: Column(
                                  children: [
                                    Icon(Icons.favorite_border, color: const Color(0xffcbd5e1), size: _ui(context, 44)),
                                    SizedBox(height: _ui(context, 10)),
                                    Text('No activity here yet', style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 15), fontWeight: FontWeight.w900)),
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
            );
          },
        );
      },
    );
  }

  Widget _activityGroup(BuildContext context, String title, List<_ActivityItem> items, Set<String> followed, StateSetter setSheetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: _ui(context, 6), bottom: _ui(context, 8)),
          child: Text(title, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
        ),
        ...items.map((item) => _activityRow(context, item, followed, setSheetState)),
        SizedBox(height: _ui(context, 8)),
      ],
    );
  }

  Widget _activityRow(BuildContext context, _ActivityItem item, Set<String> followed, StateSetter setSheetState) {
    final isFollowed = followed.contains(item.actor);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _ui(context, 7)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(radius: _ui(context, 21), backgroundImage: NetworkImage(item.avatarUrl)),
          SizedBox(width: _ui(context, 10)),
          Expanded(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(color: const Color(0xff26364d), fontSize: _font(context, 13), height: 1.18, fontWeight: FontWeight.w600),
                children: [
                  TextSpan(text: item.actor, style: const TextStyle(fontWeight: FontWeight.w900)),
                  TextSpan(text: ' ${item.message} '),
                  TextSpan(text: item.time, style: const TextStyle(color: Color(0xff94a3b8))),
                ],
              ),
            ),
          ),
          SizedBox(width: _ui(context, 8)),
          if (item.showFollow)
            GestureDetector(
              onTap: () => setSheetState(() {
                if (isFollowed) {
                  followed.remove(item.actor);
                } else {
                  followed.add(item.actor);
                }
              }),
              child: Container(
                height: _ui(context, 30),
                padding: EdgeInsets.symmetric(horizontal: _ui(context, 13)),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: isFollowed ? const Color(0xffeef2ff) : const Color(0xff2f9bef), borderRadius: BorderRadius.circular(_ui(context, 10))),
                child: Text(isFollowed ? 'Following' : 'Follow', style: TextStyle(color: isFollowed ? const Color(0xff4f46e5) : Colors.white, fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(_ui(context, 8)),
              child: Image.network(item.thumbUrl, width: _ui(context, 42), height: _ui(context, 42), fit: BoxFit.cover),
            ),
        ],
      ),
    );
  }

  Widget _storyRailCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(_ui(context, 10), _ui(context, 8), _ui(context, 10), _ui(context, 6)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 22)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 14, offset: const Offset(0, 7))],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _stories.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: _ui(context, 12)),
        itemBuilder: (context, index) {
          if (index == 0) return _storyBubble(context, _stories.first);
          if (index == 1) return _addStory(context);
          return _storyBubble(context, _stories[index - 1]);
        },
      ),
    );
  }

  Widget _storyProgress(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_ui(context, 8)),
      child: Container(color: const Color(0xffa9cdf1)),
    );
  }

  Widget _storyBubble(BuildContext context, _StoryItem story) {
    final isMine = story.label == 'Your story';
    return SizedBox(
      width: _ui(context, 62),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showStoryViewer(context, story),
        child: Column(
          children: [
            Container(
              width: _ui(context, 60),
              height: _ui(context, 60),
              padding: EdgeInsets.all(_ui(context, isMine ? 2.2 : 2.5)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isMine
                      ? const [Color(0xff00c2b8), Color(0xff2f9bef), Color(0xff7c3aed)]
                      : const [Color(0xfffb923c), Color(0xffec4899), Color(0xff6366f1)],
                ),
              ),
              child: story.imageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        story.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _storyInitials(context, story.initials),
                      ),
                    )
                  : _storyInitials(context, story.initials),
            ),
            SizedBox(height: _ui(context, 6)),
            Text(story.label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: const Color(0xff1b2434), fontSize: _font(context, 9), fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _storyInitials(BuildContext context, String initials) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xff334155), shape: BoxShape.circle),
      child: Text(initials, style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
    );
  }

  Widget _addStory(BuildContext context) {
    return SizedBox(
      width: _ui(context, 62),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showStoryMediaSheet(context),
        child: Column(
          children: [
            Container(
              width: _ui(context, 60),
              height: _ui(context, 60),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: CustomPaint(
                painter: _DashedCirclePainter(color: const Color(0xffb9c7d8), strokeWidth: _ui(context, 1.6)),
                child: Icon(Icons.add, color: const Color(0xff94a3b8), size: _ui(context, 25)),
              ),
            ),
            SizedBox(height: _ui(context, 6)),
            Text('Add', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 9), fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _composer(BuildContext context) {
    return Container(
      height: _ui(context, 48),
      margin: EdgeInsets.fromLTRB(_ui(context, 8), _ui(context, 5), _ui(context, 8), _ui(context, 12)),
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 18)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))]),
        child: Row(
          children: [
            CircleAvatar(radius: _ui(context, 17), backgroundImage: _avatarProvider()),
            SizedBox(width: _ui(context, 10)),
            Expanded(
              child: Container(
                height: _ui(context, 34),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
                decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(_ui(context, 18))),
                child: Text('Share a vibe...', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 13), fontWeight: FontWeight.w600)),
              ),
            ),
            SizedBox(width: _ui(context, 10)),
            GestureDetector(
              onTap: () => _showStoryMediaSheet(context),
              child: Container(
                width: _ui(context, 36),
                height: _ui(context, 36),
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xff7c3aed), Color(0xffec4899)])),
                child: Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: _ui(context, 20)),
              ),
            ),
          ],
        ),
      );
  }

  Future<void> _showStoryMediaSheet(BuildContext context) async {
    _storyCaptionController.clear();
    String selectedType = 'Image';
    String draftMediaUrl = _storyMediaUrl('Image', 0);
    bool mediaSelected = false;

    final createdStory = await showModalBottomSheet<_StoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.88;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(top: _ui(context, 52), bottom: bottomInset),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 26))),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 28, offset: const Offset(0, -8))],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(_ui(context, 18), _ui(context, 18), _ui(context, 8), _ui(context, 18)),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xff7c3aed), Color(0xff2f9bef), Color(0xffec4899)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 26))),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: _ui(context, 38),
                                    height: _ui(context, 38),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), borderRadius: BorderRadius.circular(_ui(context, 13))),
                                    child: Icon(Icons.auto_awesome, color: Colors.white, size: _ui(context, 20)),
                                  ),
                                  SizedBox(width: _ui(context, 10)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Add to Story', style: TextStyle(color: Colors.white, fontSize: _font(context, 21), fontWeight: FontWeight.w900, height: 1)),
                                        SizedBox(height: _ui(context, 3)),
                                        Text('Post an image, video or audio vibe.', style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: _font(context, 12), fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _closeSheet(sheetContext),
                                    icon: Icon(Icons.close, color: Colors.white, size: _ui(context, 24)),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(_ui(context, 16), _ui(context, 16), _ui(context, 16), _ui(context, 18)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _mediaPostOption(
                                            context,
                                            icon: Icons.image_outlined,
                                            label: 'Image',
                                            sub: 'Photo / gallery',
                                            selected: selectedType == 'Image',
                                            colors: const [Color(0xffa855f7), Color(0xffec4899)],
                                            onTap: () => setSheetState(() {
                                              selectedType = 'Image';
                                              mediaSelected = false;
                                              draftMediaUrl = _storyMediaUrl('Image', 0);
                                            }),
                                          ),
                                        ),
                                        SizedBox(width: _ui(context, 10)),
                                        Expanded(
                                          child: _mediaPostOption(
                                            context,
                                            icon: Icons.videocam_outlined,
                                            label: 'Video',
                                            sub: 'Reel or clip',
                                            selected: selectedType == 'Video',
                                            colors: const [Color(0xff2f9bef), Color(0xff06b6d4)],
                                            onTap: () => setSheetState(() {
                                              selectedType = 'Video';
                                              mediaSelected = false;
                                              draftMediaUrl = _storyMediaUrl('Video', 0);
                                            }),
                                          ),
                                        ),
                                        SizedBox(width: _ui(context, 10)),
                                        Expanded(
                                          child: _mediaPostOption(
                                            context,
                                            icon: Icons.graphic_eq,
                                            label: 'Audio',
                                            sub: 'Voice / song',
                                            selected: selectedType == 'Audio',
                                            colors: const [Color(0xffff8a00), Color(0xffef4444)],
                                            onTap: () => setSheetState(() {
                                              selectedType = 'Audio';
                                              mediaSelected = false;
                                              draftMediaUrl = _storyMediaUrl('Audio', 0);
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: _ui(context, 14)),
                                    _storyDraftPreview(
                                      context,
                                      selectedType,
                                      draftMediaUrl,
                                      mediaSelected,
                                      () {
                                        setSheetState(() {
                                          mediaSelected = true;
                                          draftMediaUrl = _storyMediaUrl(selectedType, DateTime.now().millisecondsSinceEpoch);
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('$selectedType selected for story', style: TextStyle(fontWeight: FontWeight.w800, fontSize: _font(context, 13))),
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(milliseconds: 900),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: _ui(context, 15)),
                                    Text('CAPTION', style: TextStyle(color: const Color(0xff7b8aa2), fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
                                    SizedBox(height: _ui(context, 8)),
                                    TextField(
                                      controller: _storyCaptionController,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        hintText: 'Write a caption... #carnival #island',
                                        hintStyle: TextStyle(color: const Color(0xff9aa6b8), fontSize: _font(context, 13), fontWeight: FontWeight.w600),
                                        filled: true,
                                        fillColor: const Color(0xfff8fafc),
                                        contentPadding: EdgeInsets.all(_ui(context, 14)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 16)), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 16)), borderSide: const BorderSide(color: Color(0xff2f9bef), width: 1.5)),
                                      ),
                                    ),
                                    SizedBox(height: _ui(context, 12)),
                                    Row(
                                      children: [
                                        Expanded(child: _storyControlPill(context, Icons.location_on_outlined, 'The Valley')),
                                        SizedBox(width: _ui(context, 10)),
                                        Expanded(child: _storyControlPill(context, Icons.monetization_on_outlined, 'Big Up on')),
                                      ],
                                    ),
                                    SizedBox(height: _ui(context, 14)),
                                    Container(
                                      width: double.infinity,
                                      height: _ui(context, 50),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xff7c3aed), Color(0xff2f9bef), Color(0xffec4899)]),
                                        borderRadius: BorderRadius.circular(_ui(context, 16)),
                                        boxShadow: [BoxShadow(color: const Color(0xff7c3aed).withOpacity(0.24), blurRadius: 16, offset: const Offset(0, 8))],
                                      ),
                                      child: TextButton(
                                        onPressed: () {
                                          final caption = _storyCaptionController.text.trim().isEmpty ? 'New island story ✨' : _storyCaptionController.text.trim();
                                          final finalMediaUrl = draftMediaUrl;
                                          _closeSheet(sheetContext, _StoryItem(
                                            'Your story',
                                            'YO',
                                            imageUrl: finalMediaUrl,
                                            mediaUrl: finalMediaUrl,
                                            mediaType: selectedType,
                                            caption: caption,
                                            owner: 'You',
                                            location: 'The Valley',
                                            postedAgo: 'now',
                                          ));
                                        },
                                        child: Text('Post Story', style: TextStyle(color: Colors.white, fontSize: _font(context, 16), fontWeight: FontWeight.w900)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted || createdStory == null) return;
    setState(() => _stories[0] = createdStory);
    _safeSnack('Story posted');
  }

  Widget _storyDraftPreview(BuildContext context, String selectedType, String mediaUrl, bool mediaSelected, VoidCallback onTap) {
    final isImage = selectedType == 'Image';
    final isVideo = selectedType == 'Video';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: _ui(context, 132),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_ui(context, 18)),
          border: Border.all(color: isImage ? const Color(0xffc4b5fd) : Colors.transparent, width: 1.5),
          gradient: isImage
              ? null
              : LinearGradient(
                  colors: isVideo ? const [Color(0xff0ea5e9), Color(0xff7c3aed)] : const [Color(0xffff8a00), Color(0xffec4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          image: isImage
              ? DecorationImage(
                  image: NetworkImage(mediaUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Container(
          padding: EdgeInsets.all(_ui(context, 13)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_ui(context, 18)),
            gradient: isImage
                ? LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.54)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                : null,
          ),
          child: isImage
              ? Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(mediaSelected ? 'Image selected' : 'Tap to choose image', style: TextStyle(color: Colors.white, fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isVideo ? Icons.play_circle_fill_rounded : Icons.graphic_eq, color: Colors.white, size: _ui(context, 40)),
                    SizedBox(height: _ui(context, 7)),
                    Text(mediaSelected ? '$selectedType selected' : (isVideo ? 'Tap to choose video' : 'Tap to record or choose audio'), textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
                    SizedBox(height: _ui(context, 3)),
                    Text(isVideo ? 'Reel / clip preview' : 'Voice note / song preview', style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      ),
    );
  }

  void _postStory(String mediaType, {String? mediaUrl, bool mediaSelected = false}) {
    final caption = _storyCaptionController.text.trim().isEmpty ? 'New island story ✨' : _storyCaptionController.text.trim();
    final finalMediaUrl = mediaUrl ?? _storyMediaUrl(mediaType, DateTime.now().millisecondsSinceEpoch);
    setState(() {
      _stories[0] = _StoryItem(
        'Your story',
        'YO',
        imageUrl: finalMediaUrl,
        mediaUrl: finalMediaUrl,
        mediaType: mediaType,
        caption: caption,
        owner: 'You',
        location: 'The Valley',
        postedAgo: 'now',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mediaSelected ? 'Story posted with $mediaType' : 'Story posted', style: TextStyle(fontWeight: FontWeight.w800, fontSize: _font(context, 13))),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  String _storyMediaUrl(String mediaType, [int seed = 0]) {
    final suffix = seed == 0 ? 'default' : seed.toString();
    if (mediaType == 'Video') return 'https://picsum.photos/seed/linkup-story-video-$suffix/900/1400';
    if (mediaType == 'Audio') return 'https://picsum.photos/seed/linkup-story-audio-$suffix/900/1400';
    return 'https://picsum.photos/seed/linkup-story-image-$suffix/900/1400';
  }

  Widget _mediaPostOption(BuildContext context, {required IconData icon, required String label, required String sub, required bool selected, required List<Color> colors, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: _ui(context, 88),
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 6), vertical: _ui(context, 7)),
        decoration: BoxDecoration(
          color: selected ? const Color(0xfff5f3ff) : const Color(0xfff8fafc),
          border: Border.all(color: selected ? const Color(0xff8b5cf6) : const Color(0xffe2e8f0), width: selected ? 2 : 1.3),
          borderRadius: BorderRadius.circular(_ui(context, 18)),
          boxShadow: selected ? [BoxShadow(color: const Color(0xff8b5cf6).withOpacity(0.16), blurRadius: 12, offset: const Offset(0, 5))] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: _ui(context, 30),
              height: _ui(context, 30),
              decoration: BoxDecoration(gradient: LinearGradient(colors: colors), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: _ui(context, 16)),
            ),
            SizedBox(height: _ui(context, 5)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
            ),
            SizedBox(height: _ui(context, 1)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(sub, maxLines: 1, style: TextStyle(color: const Color(0xff8a98ad), fontSize: _font(context, 8.5), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryViewer(BuildContext context, _StoryItem story) {
    int ownerIndex = _stories.indexOf(story);
    if (ownerIndex < 0) ownerIndex = 0;
    int frameIndex = 0;
    bool isStoryVideoPlaying = false;
    bool isStoryLiked = false;
    double storyProgress = 0.0;
    Timer? storyTimer;
    DateTime lastTick = DateTime.now();
    int tickingOwnerIndex = -1;
    int tickingFrameIndex = -1;
    bool dialogOpen = true;

    List<_StoryFrame> framesFor(_StoryItem owner) {
      return owner.frames.isEmpty
          ? <_StoryFrame>[_StoryFrame(mediaUrl: owner.mediaUrl ?? owner.imageUrl, mediaType: owner.mediaType, caption: owner.caption, location: owner.location, postedAgo: owner.postedAgo)]
          : owner.frames;
    }

    Duration durationFor(_StoryFrame frame) {
      if (frame.mediaType == 'Video') return const Duration(seconds: 8);
      if (frame.mediaType == 'Audio') return const Duration(seconds: 7);
      return const Duration(seconds: 5);
    }

    void resetStoryClock() {
      storyProgress = 0.0;
      lastTick = DateTime.now();
      tickingOwnerIndex = ownerIndex;
      tickingFrameIndex = frameIndex;
    }

    void goPrevious(StateSetter setDialogState) {
      if (frameIndex > 0) {
        setDialogState(() {
          frameIndex--;
          isStoryVideoPlaying = false;
          resetStoryClock();
        });
        return;
      }
      if (ownerIndex > 0) {
        final previousOwnerIndex = ownerIndex - 1;
        final previousFrames = _stories[previousOwnerIndex].frames;
        setDialogState(() {
          ownerIndex = previousOwnerIndex;
          frameIndex = previousFrames.isEmpty ? 0 : previousFrames.length - 1;
          isStoryVideoPlaying = false;
          resetStoryClock();
        });
      }
    }

    void goNext(BuildContext dialogContext, StateSetter setDialogState) {
      final owner = _stories[ownerIndex];
      final frameCount = framesFor(owner).length;
      if (frameIndex < frameCount - 1) {
        setDialogState(() {
          frameIndex++;
          isStoryVideoPlaying = false;
          resetStoryClock();
        });
        return;
      }
      if (ownerIndex < _stories.length - 1) {
        setDialogState(() {
          ownerIndex++;
          frameIndex = 0;
          isStoryVideoPlaying = false;
          resetStoryClock();
        });
      } else {
        Navigator.of(dialogContext).pop();
      }
    }

    void ensureStoryTimer(BuildContext dialogContext, StateSetter setDialogState, _StoryFrame activeFrame) {
      if (tickingOwnerIndex != ownerIndex || tickingFrameIndex != frameIndex) {
        resetStoryClock();
      }
      if (storyTimer?.isActive == true) return;
      storyTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
        if (!dialogOpen) return;
        final owner = _stories[ownerIndex];
        final frames = framesFor(owner);
        if (frames.isEmpty) return;
        if (frameIndex >= frames.length) frameIndex = frames.length - 1;
        final frame = frames[frameIndex];

        // Video story progress should not run while the video is paused.
        if (frame.mediaType == 'Video' && !isStoryVideoPlaying) {
          lastTick = DateTime.now();
          return;
        }

        final now = DateTime.now();
        final elapsed = now.difference(lastTick);
        lastTick = now;
        final totalMs = durationFor(frame).inMilliseconds.clamp(1, 999999);
        storyProgress = (storyProgress + elapsed.inMilliseconds / totalMs).clamp(0.0, 1.0);

        if (storyProgress >= 1.0) {
          storyProgress = 0.0;
          lastTick = DateTime.now();
          goNext(dialogContext, setDialogState);
        } else {
          setDialogState(() {});
        }
      });
    }

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close story',
      barrierColor: Colors.black.withOpacity(0.92),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final activeOwner = _stories[ownerIndex];
            final frames = framesFor(activeOwner);
            final safeFrameIndex = frameIndex.clamp(0, frames.length - 1).toInt();
            final activeFrame = frames[safeFrameIndex];
            if (safeFrameIndex != frameIndex) {
              frameIndex = safeFrameIndex;
              resetStoryClock();
            }
            ensureStoryTimer(dialogContext, setDialogState, activeFrame);

            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Stack(
                  children: [
                    _storyViewerPage(
                      context,
                      activeOwner,
                      activeFrame,
                      isVideoPlaying: isStoryVideoPlaying,
                      isLiked: isStoryLiked,
                      onToggleVideo: () => setDialogState(() {
                        isStoryVideoPlaying = !isStoryVideoPlaying;
                        lastTick = DateTime.now();
                      }),
                      onToggleLike: () => setDialogState(() => isStoryLiked = !isStoryLiked),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 10), _ui(context, 8), _ui(context, 12)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.black.withOpacity(0.64), Colors.black.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: List.generate(frames.length, (index) {
                                final fill = index < safeFrameIndex
                                    ? 1.0
                                    : index == safeFrameIndex
                                        ? storyProgress.clamp(0.0, 1.0)
                                        : 0.0;
                                return Expanded(
                                  child: Container(
                                    height: _ui(context, 3.5),
                                    margin: EdgeInsets.symmetric(horizontal: _ui(context, 2)),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.30),
                                      borderRadius: BorderRadius.circular(_ui(context, 10)),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: fill,
                                        heightFactor: 1,
                                        child: Container(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: _ui(context, 12)),
                            Row(
                              children: [
                                _storyViewerAvatar(context, activeOwner),
                                SizedBox(width: _ui(context, 9)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(child: Text(activeOwner.owner, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w900))),
                                          if (frames.length > 1) ...[
                                            SizedBox(width: _ui(context, 7)),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: _ui(context, 7), vertical: _ui(context, 2)),
                                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(_ui(context, 10))),
                                              child: Text('${safeFrameIndex + 1}/${frames.length}', style: TextStyle(color: Colors.white, fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text('${activeFrame.location} · ${activeFrame.postedAgo}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: _font(context, 11), fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  icon: Icon(Icons.close, color: Colors.white, size: _ui(context, 28)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: _ui(context, 96),
                      bottom: _ui(context, 150),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 34,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () => goPrevious(setDialogState),
                              onHorizontalDragEnd: (details) {
                                if ((details.primaryVelocity ?? 0) > 120) goPrevious(setDialogState);
                              },
                            ),
                          ),
                          const Expanded(flex: 32, child: SizedBox.expand()),
                          Expanded(
                            flex: 34,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () => goNext(dialogContext, setDialogState),
                              onHorizontalDragEnd: (details) {
                                if ((details.primaryVelocity ?? 0) < -120) goNext(dialogContext, setDialogState);
                              },
                            ),
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
    ).whenComplete(() {
      dialogOpen = false;
      storyTimer?.cancel();
    });
  }

  Widget _storyViewerPage(
    BuildContext context,
    _StoryItem story,
    _StoryFrame frame, {
    required bool isVideoPlaying,
    required bool isLiked,
    required VoidCallback onToggleVideo,
    required VoidCallback onToggleLike,
  }) {
    final isAudio = frame.mediaType == 'Audio';
    final isVideo = frame.mediaType == 'Video';
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isAudio)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xffff8a00), Color(0xffec4899), Color(0xff7c3aed)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.graphic_eq, color: Colors.white, size: _ui(context, 88)),
                  SizedBox(height: _ui(context, 12)),
                  Text('Audio Story', style: TextStyle(color: Colors.white, fontSize: _font(context, 28), fontWeight: FontWeight.w900)),
                  SizedBox(height: _ui(context, 8)),
                  Container(
                    width: _ui(context, 220),
                    height: _ui(context, 44),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(_ui(context, 24))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: _ui(context, 28)),
                      SizedBox(width: _ui(context, 8)),
                      Text('0:12 / 0:30', style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w900)),
                    ]),
                  ),
                ],
              ),
            ),
          )
        else
          Image.network(
            frame.mediaUrl ?? story.mediaUrl ?? story.imageUrl ?? 'https://picsum.photos/seed/linkup-story-fallback/900/1400',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xff111827)),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.black.withOpacity(0.62), Colors.transparent, Colors.black.withOpacity(0.78)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
        ),
        if (isVideo)
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleVideo,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: _ui(context, 74),
                height: _ui(context, 74),
                decoration: BoxDecoration(color: Colors.black.withOpacity(isVideoPlaying ? 0.18 : 0.42), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.86), width: 1.6)),
                child: Icon(isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: _ui(context, 48)),
              ),
            ),
          ),
        Positioned(
          left: _ui(context, 18),
          right: _ui(context, 18),
          bottom: _ui(context, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (frame.caption.isNotEmpty)
                Text(frame.caption, style: TextStyle(color: Colors.white, fontSize: _font(context, 20), fontWeight: FontWeight.w900, height: 1.18)),
              SizedBox(height: _ui(context, 16)),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply box selected'))),
                      child: Container(
                        height: _ui(context, 44),
                        padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(_ui(context, 24)), border: Border.all(color: Colors.white.withOpacity(0.28))),
                        child: Text('Send message', style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: _font(context, 14), fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  SizedBox(width: _ui(context, 10)),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onToggleLike,
                    child: Container(width: _ui(context, 44), height: _ui(context, 44), decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle), child: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? const Color(0xffec4899) : Colors.white, size: _ui(context, 22))),
                  ),
                  SizedBox(width: _ui(context, 8)),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story shared'))),
                    child: Container(width: _ui(context, 44), height: _ui(context, 44), decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle), child: Icon(Icons.send_outlined, color: Colors.white, size: _ui(context, 22))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _storyViewerAvatar(BuildContext context, _StoryItem story) {
    return Container(
      width: _ui(context, 38),
      height: _ui(context, 38),
      padding: EdgeInsets.all(_ui(context, 2)),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xffff8a00), Color(0xffec4899), Color(0xff6366f1)])),
      child: ClipOval(
        child: story.imageUrl != null
            ? Image.network(story.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _storyInitials(context, story.initials))
            : _storyInitials(context, story.initials),
      ),
    );
  }

  Widget _storyControlPill(BuildContext context, IconData icon, String label) {
    return Container(
      height: _ui(context, 42),
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        border: Border.all(color: const Color(0xffe2e8f0)),
        borderRadius: BorderRadius.circular(_ui(context, 15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff2f9bef), size: _ui(context, 17)),
          SizedBox(width: _ui(context, 8)),
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff334155), fontSize: _font(context, 12), fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  Widget _postCard(BuildContext context, _VibePost post) {
    final key = _postKey(post);
    final liked = _likedPosts.contains(key);
    final saved = _savedPosts.contains(key);
    final reposted = _repostedPosts.contains(key);
    final commentDelta = _extraComments[key]?.length ?? 0;
    final bigUpDelta = _bigUpBonus[key] ?? 0;

    return Container(
      margin: EdgeInsets.fromLTRB(_ui(context, 8), 0, _ui(context, 8), _ui(context, 12)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 18)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_ui(context, 18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(_ui(context, 11), _ui(context, 10), _ui(context, 11), _ui(context, 8)),
              child: Row(
                children: [
                  Container(
                    width: _ui(context, 43),
                    height: _ui(context, 43),
                    padding: EdgeInsets.all(_ui(context, 2)),
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xfff59e0b), Color(0xffec4899), Color(0xff6366f1)])),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Color(0xff1e293b), shape: BoxShape.circle),
                      child: Text(post.initials, style: TextStyle(color: Colors.white, fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
                    ),
                  ),
                  SizedBox(width: _ui(context, 8)),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(post.user, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
                      SizedBox(height: _ui(context, 2)),
                      Row(children: [
                        Icon(Icons.location_on, color: const Color(0xffef4444), size: _ui(context, 10)),
                        Text(' ${post.location} · ', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: _ui(context, 5), vertical: _ui(context, 1.5)),
                          decoration: BoxDecoration(color: const Color(0xffeef2ff), borderRadius: BorderRadius.circular(_ui(context, 6))),
                          child: Text(post.kind, style: TextStyle(color: const Color(0xff4f46e5), fontSize: _font(context, 8), fontWeight: FontWeight.w900)),
                        ),
                      ]),
                    ]),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showPostMoreSheet(context, post),
                    child: Icon(Icons.more_horiz, color: const Color(0xff94a3b8), size: _ui(context, 22)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () => setState(() => _likedPosts.add(key)),
              child: AspectRatio(
                aspectRatio: 1.03,
                child: Image.network(
                  post.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(color: const Color(0xffe2e8f0), alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2));
                  },
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xffdbeafe), alignment: Alignment.center, child: Icon(Icons.image_outlined, color: const Color(0xff2f9bef), size: _ui(context, 42))),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 9), _ui(context, 12), _ui(context, 0)),
              child: Row(
                children: [
                  _postAction(
                    context,
                    liked ? Icons.favorite : Icons.favorite_border,
                    post.likes,
                    selected: liked,
                    color: const Color(0xffff3f72),
                    onTap: () => setState(() {
                      liked ? _likedPosts.remove(key) : _likedPosts.add(key);
                    }),
                  ),
                  SizedBox(width: _ui(context, 10)),
                  _postAction(
                    context,
                    Icons.chat_bubble_outline,
                    _metricWithDelta(post.comments, commentDelta),
                    onTap: () => _showCommentsSheet(context, post),
                  ),
                  SizedBox(width: _ui(context, 10)),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showRepostSheet(context, post),
                    child: Icon(Icons.repeat, color: reposted ? const Color(0xff06a77d) : const Color(0xff0f172a), size: _ui(context, 20)),
                  ),
                  SizedBox(width: _ui(context, 12)),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showShareSheet(context, post),
                    child: Icon(Icons.send_outlined, color: const Color(0xff0f172a), size: _ui(context, 20)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showBigUpSheet(context, post),
                    child: Container(
                      height: _ui(context, 28),
                      padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xffff8a00), Color(0xffec4899)]),
                        borderRadius: BorderRadius.circular(_ui(context, 18)),
                      ),
                      child: Row(children: [
                        Icon(Icons.monetization_on_outlined, color: Colors.white, size: _ui(context, 15)),
                        SizedBox(width: _ui(context, 5)),
                        Text('Big Up', style: TextStyle(color: Colors.white, fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
                        SizedBox(width: _ui(context, 8)),
                        Text(_metricWithDelta(post.coins, bigUpDelta), style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  ),
                  SizedBox(width: _ui(context, 12)),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      saved ? _savedPosts.remove(key) : _savedPosts.add(key);
                    }),
                    child: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: saved ? const Color(0xff5b35f5) : const Color(0xff0f172a), size: _ui(context, 21)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 7), _ui(context, 12), _ui(context, 2)),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 13), height: 1.15),
                  children: [
                    TextSpan(text: post.user, style: const TextStyle(fontWeight: FontWeight.w900)),
                    TextSpan(text: ' ${post.caption} '),
                    ...post.tags.map((tag) => TextSpan(text: '#$tag ', style: const TextStyle(color: Color(0xff4f46e5), fontWeight: FontWeight.w800))),
                  ],
                ),
              ),
            ),
            if (commentDelta > 0)
              Padding(
                padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 2), _ui(context, 12), _ui(context, 3)),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showCommentsSheet(context, post),
                  child: Text('View ${_extraComments[key]!.length} new comment${_extraComments[key]!.length == 1 ? '' : 's'}', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 11), fontWeight: FontWeight.w800)),
                ),
              ),
            if (post.music != null)
              Padding(
                padding: EdgeInsets.fromLTRB(_ui(context, 12), 0, _ui(context, 12), _ui(context, 8)),
                child: Row(children: [Icon(Icons.music_note, size: _ui(context, 12), color: const Color(0xff64748b)), Text(post.music!, style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 10), fontWeight: FontWeight.w600))]),
              ),
            if (post.product != null)
              Container(
                height: _ui(context, 38),
                margin: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 5), _ui(context, 12), _ui(context, 10)),
                padding: EdgeInsets.symmetric(horizontal: _ui(context, 12)),
                decoration: BoxDecoration(color: const Color(0xff0f172a), borderRadius: BorderRadius.circular(_ui(context, 14))),
                child: Row(children: [
                  Icon(Icons.shopping_bag_outlined, color: Colors.white, size: _ui(context, 16)),
                  SizedBox(width: _ui(context, 8)),
                  Expanded(child: Text(post.product!, style: TextStyle(color: Colors.white, fontSize: _font(context, 11), fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: _ui(context, 11), vertical: _ui(context, 5)),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(_ui(context, 12))),
                    child: Text('Shop', style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _postAction(
    BuildContext context,
    IconData icon,
    String value, {
    VoidCallback? onTap,
    bool selected = false,
    Color color = const Color(0xff0f172a),
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(children: [
        Icon(icon, color: selected ? color : const Color(0xff0f172a), size: _ui(context, 20)),
        SizedBox(width: _ui(context, 4)),
        Text(value, style: TextStyle(color: const Color(0xff0f172a), fontSize: _font(context, 11), fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _sheetGrabber(BuildContext context) {
    return Center(
      child: Container(
        width: _ui(context, 42),
        height: _ui(context, 4),
        margin: EdgeInsets.only(top: _ui(context, 8), bottom: _ui(context, 7)),
        decoration: BoxDecoration(color: const Color(0xffd8e0ea), borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, _VibePost post) {
    final inputController = TextEditingController();
    final key = _postKey(post);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final comments = _commentsFor(post);
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
                child: Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.74),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24)))),
                  child: Column(
                    children: [
                      _sheetGrabber(context),
                      Padding(
                        padding: EdgeInsets.fromLTRB(_ui(context, 14), 0, _ui(context, 10), _ui(context, 10)),
                        child: Row(
                          children: [
                            Expanded(child: Text('Comments', textAlign: TextAlign.center, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 18), fontWeight: FontWeight.w900))),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _closeSheet(sheetContext);
                                Future<void>.delayed(const Duration(milliseconds: 380), () {
                                  if (!mounted) return;
                                  _showShareSheet(context, post);
                                });
                              },
                              child: Icon(Icons.send_outlined, color: const Color(0xff475569), size: _ui(context, 24)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xffedf2f7)),
                      Expanded(
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 12), _ui(context, 12), _ui(context, 8)),
                          itemCount: comments.length,
                          separatorBuilder: (_, __) => SizedBox(height: _ui(context, 14)),
                          itemBuilder: (_, index) {
                            final c = comments[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: _ui(context, 18), backgroundColor: const Color(0xff26364d), child: Text(c.initials, style: TextStyle(color: Colors.white, fontSize: _font(context, 10), fontWeight: FontWeight.w900))),
                                SizedBox(width: _ui(context, 10)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 13), height: 1.18),
                                          children: [
                                            TextSpan(text: c.handle, style: const TextStyle(fontWeight: FontWeight.w900)),
                                            TextSpan(text: '  ${c.time}', style: const TextStyle(color: Color(0xff94a3b8), fontWeight: FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: _ui(context, 3)),
                                      Text(c.text, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 13), fontWeight: FontWeight.w500, height: 1.2)),
                                      SizedBox(height: _ui(context, 6)),
                                      Text('Reply', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 11), fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                                SizedBox(width: _ui(context, 8)),
                                Column(
                                  children: [
                                    Icon(Icons.favorite_border, color: const Color(0xff94a3b8), size: _ui(context, 18)),
                                    SizedBox(height: _ui(context, 3)),
                                    Text('${c.likes}', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 9), fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 6), _ui(context, 12), _ui(context, 12) + MediaQuery.of(sheetContext).padding.bottom * 0.25),
                        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xffedf2f7)))),
                        child: Column(
                          children: [
                            Row(
                              children: ['❤️', '🙌', '🔥', '👏', '🥲', '😍', '😮', '😂'].map((emoji) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    inputController.text = inputController.text + emoji;
                                    inputController.selection = TextSelection.collapsed(offset: inputController.text.length);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.only(right: _ui(context, 10), bottom: _ui(context, 7)),
                                    child: Text(emoji, style: TextStyle(fontSize: _font(context, 22))),
                                  ),
                                );
                              }).toList(),
                            ),
                            Row(
                              children: [
                                CircleAvatar(radius: _ui(context, 18), backgroundImage: _avatarProvider()),
                                SizedBox(width: _ui(context, 8)),
                                Expanded(
                                  child: Container(
                                    height: _ui(context, 42),
                                    decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(_ui(context, 22))),
                                    child: TextField(
                                      controller: inputController,
                                      decoration: InputDecoration(
                                        hintText: 'Add a comment for ${post.user}...',
                                        hintStyle: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 12), fontWeight: FontWeight.w600),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: _ui(context, 14), vertical: _ui(context, 10)),
                                      ),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final text = inputController.text.trim();
                                    if (text.isEmpty) return;
                                    _extraComments.putIfAbsent(key, () => <_VibeComment>[]).add(_VibeComment('CS', '@cassiusstuart', text, 'now'));
                                    inputController.clear();
                                    setSheetState(() {});
                                  },
                                  child: Text('Post', style: TextStyle(color: const Color(0xff5b35f5), fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      inputController.dispose();
    });
  }

  void _showRepostSheet(BuildContext context, _VibePost post) {
    final key = _postKey(post);
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(_ui(context, 16), _ui(context, 18), _ui(context, 16), _ui(context, 18) + MediaQuery.of(sheetContext).padding.bottom),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24)))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _repostOption(context, Icons.repeat, _repostedPosts.contains(key) ? 'Remove repost' : 'Repost', () => _closeSheet(sheetContext, 'repost')),
            const Divider(height: 1, color: Color(0xffedf2f7)),
            _repostOption(context, Icons.add_circle_outline, 'Add to story', () => _closeSheet(sheetContext, 'story')),
          ],
        ),
      ),
    ).then((action) {
      if (!mounted || action == null) return;
      if (action == 'repost') {
        final shouldAdd = !_repostedPosts.contains(key);
        setState(() {
          shouldAdd ? _repostedPosts.add(key) : _repostedPosts.remove(key);
        });
        _safeSnack(shouldAdd ? 'Reposted' : 'Repost removed');
      } else if (action == 'story') {
        setState(() {
          _stories[0] = _StoryItem(
            'Your story',
            'YO',
            imageUrl: post.imageUrl,
            mediaUrl: post.imageUrl,
            caption: '${post.user} ${post.caption}',
            owner: 'You',
            location: post.location,
            postedAgo: 'now',
          );
        });
        _safeSnack('Added to your story');
      }
    });
  }

  Widget _repostOption(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: _ui(context, 54),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xff0f172a), size: _ui(context, 24)),
            SizedBox(width: _ui(context, 14)),
            Text(title, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 19), fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Future<void> _showShareSheet(BuildContext context, _VibePost post) async {
    final text = _shareText(post);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(_ui(context, 16), _ui(context, 18), _ui(context, 16), _ui(context, 18) + MediaQuery.of(sheetContext).padding.bottom),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24)))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.send_outlined, color: const Color(0xff5b35f5), size: _ui(context, 22)),
                SizedBox(width: _ui(context, 9)),
                Expanded(child: Text('Share Vibe', style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 19), fontWeight: FontWeight.w900))),
                IconButton(onPressed: () => _closeSheet(sheetContext), icon: Icon(Icons.close, color: const Color(0xff111827), size: _ui(context, 22))),
              ],
            ),
            SizedBox(height: _ui(context, 8)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(_ui(context, 12)),
              decoration: BoxDecoration(color: const Color(0xfff8fafc), borderRadius: BorderRadius.circular(_ui(context, 14)), border: Border.all(color: const Color(0xffe2e8f0))),
              child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff334155), fontSize: _font(context, 12), fontWeight: FontWeight.w700, height: 1.25)),
            ),
            SizedBox(height: _ui(context, 12)),
            _repostOption(context, Icons.copy_rounded, 'Copy link', () => _closeSheet(sheetContext, 'copy')),
            const Divider(height: 1, color: Color(0xffedf2f7)),
            _repostOption(context, Icons.chat_bubble_outline, 'Send in LinkUp chat', () => _closeSheet(sheetContext, 'chat')),
            const Divider(height: 1, color: Color(0xffedf2f7)),
            _repostOption(context, Icons.add_circle_outline, 'Add to story', () => _closeSheet(sheetContext, 'story')),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'story') {
      setState(() {
        _stories[0] = _StoryItem(
          'Your story',
          'YO',
          imageUrl: post.imageUrl,
          mediaUrl: post.imageUrl,
          caption: '${post.user} ${post.caption}',
          owner: 'You',
          location: post.location,
          postedAgo: 'now',
        );
      });
      _safeSnack('Added to your story');
    } else if (action == 'chat') {
      _safeSnack('Ready to send in LinkUp chat');
    } else {
      _safeSnack('Link copied');
    }
  }

  void _showPostMoreSheet(BuildContext context, _VibePost post) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(_ui(context, 16), _ui(context, 18), _ui(context, 16), _ui(context, 18) + MediaQuery.of(sheetContext).padding.bottom),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24)))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _repostOption(context, Icons.person_outline, 'View profile', () => _closeSheet(sheetContext)),
            const Divider(height: 1, color: Color(0xffedf2f7)),
            _repostOption(context, Icons.flag_outlined, 'Report vibe', () => _closeSheet(sheetContext)),
          ],
        ),
      ),
    );
  }

  void _showBigUpSheet(BuildContext context, _VibePost post) {
    final gifts = const [
      ['🤙', 'Likkle Up', 'A little big up', '10', '≈ USD 0.10'],
      ['🙌', 'Big Up', 'Big up yuhself!', '25', '≈ USD 0.25'],
      ['✊', 'Respect', 'Respect due', '50', '≈ USD 0.50'],
      ['🙏', 'Bless Up', 'Blessings on yuh', '75', '≈ USD 0.75'],
      ['💯', 'Nuff Respect', 'Nuff respect, star', '100', '≈ USD 1.00'],
      ['🕊️', 'Blessings', 'Blessings upon you', '150', '≈ USD 1.50'],
      ['❤️', 'One Love', 'One love, always', '200', '≈ USD 2.00'],
      ['😇', 'God Bless You', 'God bless you', '250', '≈ USD 2.50'],
      ['💞', 'Love & Respect', 'Love an’ respect', '350', '≈ USD 3.50'],
      ['🔥', 'Big Tings', 'Big tings a gwaan', '500', '≈ USD 5.00'],
      ['👑', 'Caribbean Crown', 'King/Queen ting', '1000', '≈ USD 10.00'],
    ];
    showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.82),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24)))),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(_ui(context, 15), _ui(context, 15), _ui(context, 8), _ui(context, 12)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xffff8a00), Color(0xffec4899)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.monetization_on_outlined, color: Colors.white, size: _ui(context, 21)),
                    SizedBox(width: _ui(context, 9)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Send a Big Up', style: TextStyle(color: Colors.white, fontSize: _font(context, 18), fontWeight: FontWeight.w900)),
                          SizedBox(height: _ui(context, 2)),
                          Text('Show ${post.user} some love · balance 37,005', style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: _font(context, 11), fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => _closeSheet(sheetContext), icon: Icon(Icons.close, color: Colors.white, size: _ui(context, 22))),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(_ui(context, 12), _ui(context, 12), _ui(context, 12), _ui(context, 14)),
                  itemCount: gifts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: _ui(context, 8), crossAxisSpacing: _ui(context, 8), childAspectRatio: 0.88),
                  itemBuilder: (context, index) {
                    final gift = gifts[index];
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _closeSheet(sheetContext, gift),
                      child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(_ui(context, 6)),
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xffe2e8f0), width: 1.3), borderRadius: BorderRadius.circular(_ui(context, 14))),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(gift[0], style: TextStyle(fontSize: _font(context, 22))),
                          SizedBox(height: _ui(context, 4)),
                          Text(gift[1], textAlign: TextAlign.center, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
                          SizedBox(height: _ui(context, 1)),
                          Text(gift[2], textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 8), fontWeight: FontWeight.w700)),
                          SizedBox(height: _ui(context, 5)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: _ui(context, 8), vertical: _ui(context, 3)),
                            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xffff8a00), Color(0xffec4899)]), borderRadius: BorderRadius.circular(_ui(context, 12))),
                            child: Text('🪙 ${gift[3]}', style: TextStyle(color: Colors.white, fontSize: _font(context, 9), fontWeight: FontWeight.w900)),
                          ),
                          SizedBox(height: _ui(context, 2)),
                          Text(gift[4], style: TextStyle(color: const Color(0xff059669), fontSize: _font(context, 9), fontWeight: FontWeight.w900)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((gift) {
      if (!mounted || gift == null) return;
      final postKey = _postKey(post);
      final giftTitle = gift[1];
      setState(() => _bigUpBonus[postKey] = (_bigUpBonus[postKey] ?? 0) + 1);
      _safeSnack('$giftTitle sent to ${post.user}');
    });
  }

  Future<void> showNewVibeComposer(BuildContext context) async {
    final captionController = TextEditingController();
    final locationController = TextEditingController(text: 'The Valley');
    String postAs = 'Myself';
    String mediaMode = 'Gallery';
    bool allowBigUp = true;
    bool selectedMedia = false;
    String previewUrl = 'https://picsum.photos/seed/new-vibe-preview/900/900';

    final createdPost = await showModalBottomSheet<_VibePost>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) => SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.86),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 24)))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(_ui(context, 14), _ui(context, 13), _ui(context, 8), _ui(context, 10)),
                      child: Row(
                        children: [
                          Expanded(child: Text('New Vibe', style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 20), fontWeight: FontWeight.w900))),
                          IconButton(onPressed: () => _closeSheet(sheetContext), icon: Icon(Icons.close, color: const Color(0xff111827), size: _ui(context, 23))),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xffedf2f7)),
                    Flexible(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(_ui(context, 14), _ui(context, 15), _ui(context, 14), _ui(context, 14)),
                        children: [
                          Text('POST AS', style: TextStyle(color: const Color(0xff64748b), fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
                          SizedBox(height: _ui(context, 8)),
                          Row(children: [
                            Expanded(child: _composerChoice(context, '👤 Myself', postAs == 'Myself', () => setSheetState(() => postAs = 'Myself'))),
                            SizedBox(width: _ui(context, 8)),
                            Expanded(child: _composerChoice(context, '🏢 Organization / Group', postAs != 'Myself', () => setSheetState(() => postAs = 'Organization'))),
                          ]),
                          SizedBox(height: _ui(context, 14)),
                          Row(children: [
                            Expanded(child: _composerMediaButton(context, Icons.camera_alt_outlined, 'Take Photo', const Color(0xff2f9bef), mediaMode == 'Take Photo', () => setSheetState(() { mediaMode = 'Take Photo'; selectedMedia = true; previewUrl = 'https://picsum.photos/seed/vibe-camera-${DateTime.now().millisecondsSinceEpoch}/900/900'; }))),
                            SizedBox(width: _ui(context, 8)),
                            Expanded(child: _composerMediaButton(context, Icons.videocam_outlined, 'Record Video', const Color(0xffff3366), mediaMode == 'Record Video', () => setSheetState(() { mediaMode = 'Record Video'; selectedMedia = true; previewUrl = 'https://picsum.photos/seed/vibe-video-${DateTime.now().millisecondsSinceEpoch}/900/900'; }))),
                            SizedBox(width: _ui(context, 8)),
                            Expanded(child: _composerMediaButton(context, Icons.image_outlined, 'Gallery', const Color(0xff5b35f5), mediaMode == 'Gallery', () => setSheetState(() { mediaMode = 'Gallery'; selectedMedia = true; previewUrl = 'https://picsum.photos/seed/vibe-gallery-${DateTime.now().millisecondsSinceEpoch}/900/900'; }))),
                          ]),
                          SizedBox(height: _ui(context, 10)),
                          Text('Snap a photo, record a video, or pick from your gallery (select multiple for a carousel)', textAlign: TextAlign.center, style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 10), fontWeight: FontWeight.w700)),
                          if (selectedMedia) ...[
                            SizedBox(height: _ui(context, 12)),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(_ui(context, 16)),
                              child: Stack(children: [
                                AspectRatio(aspectRatio: 1.75, child: Image.network(previewUrl, fit: BoxFit.cover)),
                                Positioned(left: _ui(context, 10), bottom: _ui(context, 10), child: Container(padding: EdgeInsets.symmetric(horizontal: _ui(context, 9), vertical: _ui(context, 5)), decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(_ui(context, 12))), child: Text(mediaMode, style: TextStyle(color: Colors.white, fontSize: _font(context, 10), fontWeight: FontWeight.w900)))),
                              ]),
                            ),
                          ],
                          SizedBox(height: _ui(context, 14)),
                          TextField(
                            controller: captionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Write a caption... #carnival #island',
                              hintStyle: TextStyle(color: const Color(0xff9aa6b8), fontSize: _font(context, 13), fontWeight: FontWeight.w600),
                              contentPadding: EdgeInsets.all(_ui(context, 13)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 15)), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 15)), borderSide: const BorderSide(color: Color(0xff2f9bef), width: 1.5)),
                            ),
                          ),
                          SizedBox(height: _ui(context, 10)),
                          TextField(
                            controller: locationController,
                            decoration: InputDecoration(
                              hintText: 'The Valley',
                              contentPadding: EdgeInsets.symmetric(horizontal: _ui(context, 13), vertical: _ui(context, 12)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 15)), borderSide: const BorderSide(color: Color(0xffe2e8f0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 15)), borderSide: const BorderSide(color: Color(0xff2f9bef), width: 1.5)),
                            ),
                          ),
                          SizedBox(height: _ui(context, 10)),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setSheetState(() => allowBigUp = !allowBigUp),
                            child: Container(
                              padding: EdgeInsets.all(_ui(context, 12)),
                              decoration: BoxDecoration(color: const Color(0xfffffbeb), borderRadius: BorderRadius.circular(_ui(context, 14))),
                              child: Row(children: [
                                Expanded(child: Text('🪙 Allow Big Up coin gifts', style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 13), fontWeight: FontWeight.w900))),
                                Icon(allowBigUp ? Icons.check_box : Icons.check_box_outline_blank, color: const Color(0xff1985ff), size: _ui(context, 23)),
                              ]),
                            ),
                          ),
                          SizedBox(height: _ui(context, 10)),
                          Container(
                            padding: EdgeInsets.all(_ui(context, 12)),
                            decoration: BoxDecoration(border: Border.all(color: const Color(0xffe2e8f0)), borderRadius: BorderRadius.circular(_ui(context, 15))),
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('🛍️ Tag a product (shoppable)', style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 13), fontWeight: FontWeight.w900)),
                                SizedBox(height: _ui(context, 4)),
                                Text('Feature a Marketplace product so viewers can buy it directly from your vibe.', style: TextStyle(color: const Color(0xff94a3b8), fontSize: _font(context, 10), fontWeight: FontWeight.w700, height: 1.2)),
                              ])),
                              Container(padding: EdgeInsets.symmetric(horizontal: _ui(context, 12), vertical: _ui(context, 8)), decoration: BoxDecoration(color: const Color(0xff2f9bef), borderRadius: BorderRadius.circular(_ui(context, 14))), child: Text('Tag Product', style: TextStyle(color: Colors.white, fontSize: _font(context, 11), fontWeight: FontWeight.w900))),
                            ]),
                          ),
                          SizedBox(height: _ui(context, 14)),
                          SizedBox(
                            height: _ui(context, 50),
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2f9bef), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_ui(context, 14))), elevation: 0),
                              onPressed: () {
                                final caption = captionController.text.trim().isEmpty ? 'New island vibe ✨' : captionController.text.trim();
                                final location = locationController.text.trim().isEmpty ? 'The Valley' : locationController.text.trim();
                                final mode = mediaMode;
                                final url = selectedMedia ? previewUrl : 'https://picsum.photos/seed/vibe-post-${DateTime.now().millisecondsSinceEpoch}/900/900';
                                final bigUpEnabled = allowBigUp;
                                _closeSheet(sheetContext, _VibePost(
                                  user: '@cassiusstuart',
                                  initials: 'CS',
                                  location: location,
                                  kind: mode == 'Record Video' ? 'Reel' : 'Photo',
                                  imageUrl: url,
                                  likes: '0',
                                  comments: '0',
                                  coins: bigUpEnabled ? '0' : 'Off',
                                  caption: caption,
                                  tags: _extractTags(caption),
                                  music: mode == 'Record Video' ? 'New Reel Audio' : null,
                                ));
                              },
                              child: Text('Share Vibe', style: TextStyle(color: Colors.white, fontSize: _font(context, 15), fontWeight: FontWeight.w900)),
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
    captionController.dispose();
    locationController.dispose();
    if (!mounted || createdPost == null) return;
    setState(() => _posts.insert(0, createdPost));
    _safeSnack('Vibe posted');
  }

  List<String> _extractTags(String text) {
    final tags = RegExp(r'#([A-Za-z0-9_]+)').allMatches(text).map((m) => m.group(1) ?? '').where((e) => e.isNotEmpty).toList();
    return tags.isEmpty ? <String>[] : tags;
  }

  Widget _composerChoice(BuildContext context, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: _ui(context, 43),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xffeff6ff) : Colors.white,
          border: Border.all(color: selected ? const Color(0xff2f9bef) : const Color(0xffe2e8f0), width: selected ? 1.7 : 1.1),
          borderRadius: BorderRadius.circular(_ui(context, 14)),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 12), fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _composerMediaButton(BuildContext context, IconData icon, String label, Color color, bool selected, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: _ui(context, 78),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : const Color(0xfff8fafc),
          border: Border.all(color: selected ? color : const Color(0xffe2e8f0), width: selected ? 1.7 : 1.1),
          borderRadius: BorderRadius.circular(_ui(context, 14)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: _ui(context, 24)),
          SizedBox(height: _ui(context, 8)),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: const Color(0xff111827), fontSize: _font(context, 10), fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final items = [
      [Icons.home_outlined, 'Home', false],
      [Icons.image_outlined, 'Vibes', true],
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
                if (item[1] == 'Eats') Get.to(() => const EatsPage());
                if (item[1] == 'LinkUp') Get.off(() => ChatHomePage());
                if (item[1] == 'Live') Get.to(() => const LivePage());
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

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedCirclePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    const dashCount = 18;
    const gap = 0.11;
    final sweep = (math.pi * 2 / dashCount) - gap;
    for (var i = 0; i < dashCount; i++) {
      final start = i * math.pi * 2 / dashCount;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}


class _VibeComment {
  final String initials;
  final String handle;
  final String text;
  final String time;
  final int likes;

  const _VibeComment(this.initials, this.handle, this.text, this.time, {this.likes = 0});
}

class _VibePerson {
  final String handle;
  final String name;
  final String country;
  final String place;
  final String initials;
  final String? imageUrl;
  final bool verified;
  final bool following;
  final String vibes;
  final String followers;
  final String bigUps;

  _VibePerson({
    required this.handle,
    required this.name,
    required this.country,
    required this.place,
    required this.initials,
    this.imageUrl,
    this.verified = false,
    this.following = false,
    this.vibes = '128',
    this.followers = '4.2k',
    this.bigUps = '9.8k',
  });

  static List<_VibePerson> seed() => [
        _VibePerson(handle: '@aaliyah', name: 'Aaliyah', country: '🇹🇹 Trinidad & Tobago', place: 'Trinidad', initials: 'AA', imageUrl: 'https://picsum.photos/seed/aaliyah/200/200', following: true, followers: '8.1k'),
        _VibePerson(handle: '@simone', name: 'Simone', country: '🇯🇲 Jamaica', place: 'Kingston', initials: 'SI', imageUrl: 'https://picsum.photos/seed/simone/200/200', followers: '12.4k'),
        _VibePerson(handle: '@gabriela', name: 'Gabriela', country: '🇧🇷 Brazil', place: 'Rio', initials: 'GA', imageUrl: 'https://picsum.photos/seed/gabriela/200/200', verified: true, followers: '31.9k'),
        _VibePerson(handle: '@renee', name: 'Renee', country: '🇧🇸 Bahamas', place: 'Nassau', initials: 'RE', imageUrl: 'https://picsum.photos/seed/renee/200/200', following: true, followers: '5.8k'),
        _VibePerson(handle: '@marcusjohnson', name: 'Marcus Johnson', country: '🇯🇲 Jamaica', place: 'Montego Bay', initials: 'MJ', imageUrl: 'https://picsum.photos/seed/marcus/200/200', followers: '18.3k'),
        _VibePerson(handle: '@noumanzakir', name: 'Nouman Zakir', country: '🇧🇸 Bahamas', place: 'The Valley', initials: 'NZ', imageUrl: 'https://picsum.photos/seed/nouman/200/200', followers: '2.1k'),
        _VibePerson(handle: '@marissabain', name: 'Marissa Bain', country: '🇧🇸 Bahamas', place: 'Freeport', initials: 'MB', imageUrl: 'https://picsum.photos/seed/marissa/200/200', verified: true, followers: '14.7k'),
        _VibePerson(handle: '@trevanmitchel', name: 'Trevan Mitchel', country: '🇱🇨 Saint Lucia', place: 'Castries', initials: 'TM', imageUrl: 'https://picsum.photos/seed/trevan/200/200', followers: '6.5k'),
        _VibePerson(handle: '@amarajean', name: 'Amara Jean', country: '🇧🇧 Barbados', place: 'Bridgetown', initials: 'AJ', imageUrl: 'https://picsum.photos/seed/amara/200/200', followers: '7.2k'),
        _VibePerson(handle: '@tyeshabrice', name: 'Tyesha Brice', country: '🇧🇸 Bahamas', place: 'Nassau', initials: 'TB', imageUrl: 'https://picsum.photos/seed/tyesha/200/200', followers: '3.9k'),
        _VibePerson(handle: '@islandvibez', name: 'Island Vibez', country: '🇯🇲 Jamaica', place: 'Kingston', initials: 'IS', verified: true, followers: '48.2k'),
        _VibePerson(handle: '@gabis', name: 'Gabis', country: '🇧🇷 Brazil', place: 'Bahia', initials: 'GA', followers: '73.4k'),
      ];
}

class _ReelItem {
  final String handle;
  final String initials;
  final String imageUrl;
  final String caption;
  final String music;
  final String likes;
  final String comments;
  final String bigUps;

  _ReelItem({required this.handle, required this.initials, required this.imageUrl, required this.caption, required this.music, required this.likes, required this.comments, required this.bigUps});

  static List<_ReelItem> seed() => [
        _ReelItem(handle: '@islandvibez', initials: 'IS', imageUrl: 'https://picsum.photos/seed/v1/900/1400', caption: 'Carnival prep 🔥 #fete #jamaica', music: 'Soca Anthem 2026', likes: '48.2k', comments: '1.8k', bigUps: '9.8k'),
        _ReelItem(handle: '@gabis', initials: 'GA', imageUrl: 'https://picsum.photos/seed/v2/900/1400', caption: 'Açaí bowl recipe 🍇 made in 30 seconds', music: 'Bahia Beat', likes: '73.4k', comments: '3.0k', bigUps: '15.6k'),
        _ReelItem(handle: '@tanyab', initials: 'TA', imageUrl: 'https://picsum.photos/seed/v3/900/1400', caption: 'Sunset in Maracas 🌅', music: 'Island Sunset', likes: '22.1k', comments: '640', bigUps: '3.4k'),
      ];
}

class _ActivityItem {
  final String group;
  final String actor;
  final String message;
  final String time;
  final String avatarUrl;
  final String thumbUrl;
  final String type;
  final bool fromFollowing;
  final bool showFollow;

  _ActivityItem({required this.group, required this.actor, required this.message, required this.time, required this.avatarUrl, required this.thumbUrl, required this.type, this.fromFollowing = false, this.showFollow = false});

  static List<_ActivityItem> seed() => [
        _ActivityItem(group: 'Today', actor: 'kristian_r', message: 'haleyyyfox and 6 others liked your photo', time: '5m', avatarUrl: 'https://picsum.photos/seed/activity1/200/200', thumbUrl: 'https://picsum.photos/seed/activity-thumb1/160/160', type: 'like', fromFollowing: true),
        _ActivityItem(group: 'Today', actor: 'islandvibez', message: 'liked your reel', time: '3h', avatarUrl: 'https://picsum.photos/seed/activity2/200/200', thumbUrl: 'https://picsum.photos/seed/activity-thumb2/160/160', type: 'like', fromFollowing: true),
        _ActivityItem(group: 'Today', actor: 'tanyab', message: 'commented: 🔥🔥 love this fit!', time: '3h', avatarUrl: 'https://picsum.photos/seed/activity3/200/200', thumbUrl: 'https://picsum.photos/seed/activity-thumb3/160/160', type: 'comment', fromFollowing: true),
        _ActivityItem(group: 'Today', actor: 'kerian_w', message: 'jsapph_ and 9 others liked your photo', time: '5h', avatarUrl: 'https://picsum.photos/seed/activity4/200/200', thumbUrl: 'https://picsum.photos/seed/activity-thumb4/160/160', type: 'like'),
        _ActivityItem(group: 'Today', actor: 'lil_blondiee_', message: 'mentioned you in a Vibe ✨', time: '8h', avatarUrl: 'https://picsum.photos/seed/activity5/200/200', thumbUrl: 'https://picsum.photos/seed/activity-thumb5/160/160', type: 'mention'),
        _ActivityItem(group: 'Yesterday', actor: 'kamiaa_amoree', message: 'tnb_kenny and 133 others liked your photo', time: '15h', avatarUrl: 'https://picsum.photos/seed/activity6/200/200', thumbUrl: 'https://picsum.photos/seed/activity-thumb6/160/160', type: 'like'),
        _ActivityItem(group: 'Yesterday', actor: 'mooi.246', message: 'started following you', time: '1d', avatarUrl: 'https://picsum.photos/seed/activity7/200/200', thumbUrl: 'https://picsum.photos/seed/activity-thumb7/160/160', type: 'follow', showFollow: true),
        _ActivityItem(group: 'Yesterday', actor: 'mooi.246', message: 'merlinemapp and 7 others liked your reel', time: '1d', avatarUrl: 'https://picsum.photos/seed/activity8/200/200', thumbUrl: 'https://picsum.photos/seed/activity-thumb8/160/160', type: 'like'),
        _ActivityItem(group: 'Yesterday', actor: 'reneeb', message: 'sent you a Rose 🌹 (+120 coins)', time: '1d', avatarUrl: 'https://picsum.photos/seed/activity9/200/200', thumbUrl: 'https://picsum.photos/seed/activity-thumb9/160/160', type: 'gift', fromFollowing: true),
      ];
}

class _StoryFrame {
  final String? mediaUrl;
  final String mediaType;
  final String caption;
  final String location;
  final String postedAgo;

  const _StoryFrame({
    this.mediaUrl,
    this.mediaType = 'Image',
    this.caption = '',
    this.location = 'The Valley',
    this.postedAgo = '12m',
  });
}

class _StoryItem {
  final String label;
  final String initials;
  final String? imageUrl;
  final String? mediaUrl;
  final String mediaType;
  final String caption;
  final String owner;
  final String location;
  final String postedAgo;
  final List<_StoryFrame> frames;

  _StoryItem(
    this.label,
    this.initials, {
    this.imageUrl,
    this.mediaUrl,
    this.mediaType = 'Image',
    this.caption = '',
    String? owner,
    this.location = 'The Valley',
    this.postedAgo = '12m',
    List<_StoryFrame>? frames,
  })  : owner = owner ?? label,
        frames = frames ??
            [
              _StoryFrame(
                mediaUrl: mediaUrl ?? imageUrl,
                mediaType: mediaType,
                caption: caption,
                location: location,
                postedAgo: postedAgo,
              ),
            ];

  static List<_StoryItem> seed() => [
        _StoryItem(
          'Your story',
          'YO',
          imageUrl: 'https://images.unsplash.com/photo-1505228395891-9a51e7e86bf6?w=300&q=70',
          mediaUrl: 'https://images.unsplash.com/photo-1505228395891-9a51e7e86bf6?w=900&q=80',
          caption: 'Island day in The Valley ✨',
          owner: 'You',
          postedAgo: 'now',
          frames: const [
            _StoryFrame(mediaUrl: 'https://images.unsplash.com/photo-1505228395891-9a51e7e86bf6?w=900&q=80', caption: 'Island day in The Valley ✨', location: 'The Valley', postedAgo: 'now'),
            _StoryFrame(mediaUrl: 'https://picsum.photos/seed/my-story-food/900/1400', caption: 'Quick stop before tonight’s lime 🍹', location: 'The Valley', postedAgo: 'now'),
            _StoryFrame(mediaUrl: 'https://picsum.photos/seed/my-story-music/900/1400', mediaType: 'Audio', caption: 'Soca voice note for later 🎶', location: 'The Valley', postedAgo: 'now'),
          ],
        ),
        _StoryItem(
          '@tanyab',
          'TB',
          caption: 'Beach walk before the fete 🌊',
          location: 'Barbados',
          postedAgo: '8m',
          frames: const [
            _StoryFrame(mediaUrl: 'https://picsum.photos/seed/story-tanya-1/900/1400', caption: 'Beach walk before the fete 🌊', location: 'Barbados', postedAgo: '8m'),
            _StoryFrame(mediaUrl: 'https://picsum.photos/seed/story-tanya-2/900/1400', caption: 'Outfit check before the party', location: 'Barbados', postedAgo: '7m'),
          ],
        ),
        _StoryItem(
          '@islandvi...',
          'IV',
          mediaType: 'Video',
          caption: 'Carnival warmup tonight 🔥',
          location: 'Jamaica',
          postedAgo: '14m',
          frames: const [
            _StoryFrame(mediaUrl: 'https://picsum.photos/seed/story-island-1/900/1400', mediaType: 'Video', caption: 'Carnival warmup tonight 🔥', location: 'Jamaica', postedAgo: '14m'),
            _StoryFrame(mediaUrl: 'https://picsum.photos/seed/story-island-2/900/1400', caption: 'Pull up early. Line already long.', location: 'Jamaica', postedAgo: '12m'),
            _StoryFrame(mediaUrl: 'https://picsum.photos/seed/story-island-3/900/1400', mediaType: 'Video', caption: 'DJ just dropped the anthem', location: 'Jamaica', postedAgo: '10m'),
          ],
        ),
        _StoryItem(
          '@reneeb',
          'RB',
          caption: 'Market finds and good food',
          location: 'Bahamas',
          postedAgo: '24m',
          frames: const [
            _StoryFrame(mediaUrl: 'https://picsum.photos/seed/story-renee-1/900/1400', caption: 'Market finds and good food', location: 'Bahamas', postedAgo: '24m'),
            _StoryFrame(mediaUrl: 'https://picsum.photos/seed/story-renee-2/900/1400', caption: 'Fresh conch salad stop', location: 'Bahamas', postedAgo: '22m'),
          ],
        ),
        _StoryItem('@carlosmx', 'CM', mediaType: 'Audio', caption: 'New soca mix preview', location: 'Trinidad', postedAgo: '31m', frames: const [
          _StoryFrame(mediaUrl: 'https://picsum.photos/seed/story-carlos-1/900/1400', mediaType: 'Audio', caption: 'New soca mix preview', location: 'Trinidad', postedAgo: '31m'),
          _StoryFrame(mediaUrl: 'https://picsum.photos/seed/story-carlos-2/900/1400', caption: 'Studio until sunrise', location: 'Trinidad', postedAgo: '28m'),
        ]),
        _StoryItem('@gabis', 'GS', caption: 'Açaí stop after class', location: 'Brazil', postedAgo: '45m', frames: const [
          _StoryFrame(mediaUrl: 'https://picsum.photos/seed/story-gabis-1/900/1400', caption: 'Açaí stop after class', location: 'Brazil', postedAgo: '45m'),
        ]),
      ];
}

class _VibePost {
  final String user;
  final String initials;
  final String location;
  final String kind;
  final String imageUrl;
  final String likes;
  final String comments;
  final String coins;
  final String caption;
  final List<String> tags;
  final String? music;
  final String? product;

  _VibePost({
    required this.user,
    required this.initials,
    required this.location,
    required this.kind,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.coins,
    required this.caption,
    required this.tags,
    this.music,
    this.product,
  });

  static List<_VibePost> seed() => [
        _VibePost(
          user: '@islandvibez',
          initials: 'IS',
          location: 'Jamaica',
          kind: 'Reel',
          imageUrl: 'https://picsum.photos/seed/v1/900/900',
          likes: '48.2k',
          comments: '1.8k',
          coins: '9.8k',
          caption: 'Carnival prep 🔥',
          tags: ['fete', 'jamaica'],
          music: 'Soca Anthem 2026',
        ),
        _VibePost(
          user: '@gabis',
          initials: 'GA',
          location: 'Brazil',
          kind: 'Photo',
          imageUrl: 'https://picsum.photos/seed/v2/900/900',
          likes: '73.4k',
          comments: '3.0k',
          coins: '15.6k',
          caption: 'Açaí bowl recipe 🍇',
          tags: [],
          product: 'Açaí Kit · \$34.99',
        ),
        _VibePost(
          user: '@tanyab',
          initials: 'TA',
          location: 'Trinidad',
          kind: 'Reel',
          imageUrl: 'https://picsum.photos/seed/v3/900/900',
          likes: '22.1k',
          comments: '640',
          coins: '3.4k',
          caption: 'Sunset in Maracas 🌅',
          tags: [],
          music: 'Island Sunset',
        ),
        _VibePost(
          user: '@reneeb',
          initials: 'RE',
          location: 'Bahamas',
          kind: 'Carousel',
          imageUrl: 'https://picsum.photos/seed/v4/900/900',
          likes: '9.8k',
          comments: '310',
          coins: '1.4k',
          caption: 'Craft market finds 🛍️',
          tags: ['shoplocal'],
          product: 'Straw Bag · \$108.11',
        ),
      ];
}
