import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/user_model.dart';
import '../../get_controller/social_controller.dart';
import '../../mappers/api_user_mapper.dart';
import '../../services/linkup_api_service.dart';

class LinkUpWebProfilePage extends StatefulWidget {
  final UserModel user;
  final double Function(BuildContext, double) ui;
  final double Function(BuildContext, double) font;
  final double Function(BuildContext, double) icon;
  final String countryText;

  const LinkUpWebProfilePage({
    required this.user,
    required this.ui,
    required this.font,
    required this.icon,
    required this.countryText,
    super.key,
  });

  @override
  State<LinkUpWebProfilePage> createState() => _LinkUpWebProfilePageState();
}

class _LinkUpWebProfilePageState extends State<LinkUpWebProfilePage> {
  int _photoIndex = 0;
  bool _busy = false;

  int? get _userId =>
      widget.user.laravelId ?? int.tryParse(widget.user.uid ?? '');

  String get _coinsLine {
    final raw = widget.user.popularityLevel?.toString().trim();
    final display = (raw == null || raw.isEmpty) ? '1,240' : raw;
    final coins = int.tryParse(display.replaceAll(',', '')) ?? 1240;
    final dollars = (coins / 100).toStringAsFixed(2);
    return '🪙 $display coins earned · ~\$$dollars';
  }

  List<String> get _photos {
    final avatar = ApiUserMapper.resolveMediaUrl(widget.user.avatar);
    final more = widget.user.morePhotos
        .map(ApiUserMapper.resolveMediaUrl)
        .where((p) => p.isNotEmpty && p != avatar);
    return [
      if (avatar.isNotEmpty) avatar,
      ...more,
      if (avatar.isEmpty && more.isEmpty)
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=900&q=70',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ui = widget.ui;
    final font = widget.font;
    final icon = widget.icon;
    final name = widget.user.firstName.trim().isEmpty ? 'LinkUp' : widget.user.firstName.trim();
    final age = widget.user.age ?? 25;

    return Scaffold(
      backgroundColor: const Color(0xffeaf4fc),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(ui(context, 10), ui(context, 10), ui(context, 10), ui(context, 26)),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: ui(context, 34),
                    height: ui(context, 34),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.arrow_back, color: const Color(0xff10182b), size: icon(context, 20)),
                  ),
                ),
                SizedBox(width: ui(context, 10)),
                CircleAvatar(
                  radius: ui(context, 21),
                  backgroundColor: Colors.white,
                  backgroundImage: _photos.isNotEmpty && _photos.first.startsWith('http') ? NetworkImage(_photos.first) : null,
                ),
                SizedBox(width: ui(context, 9)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$name, $age', style: TextStyle(fontSize: font(context, 17), fontWeight: FontWeight.w900, color: const Color(0xff10182b), height: 1.0)),
                      SizedBox(height: ui(context, 3)),
                      Text('📍 ${widget.countryText} · ${widget.user.distance ?? '858 km'} away', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: font(context, 12), color: const Color(0xff2589df), fontWeight: FontWeight.w800)),
                      Text(_coinsLine, style: TextStyle(fontSize: font(context, 11), color: const Color(0xffd97706), fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ui(context, 10)),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _busy ? null : _sendFriendRequest,
                    child: _profileAction(
                      context,
                      'Send Friend Request',
                      const Color(0xffc9ea17),
                      Colors.black,
                    ),
                  ),
                ),
                SizedBox(width: widget.ui(context, 6)),
                GestureDetector(
                  onTap: _busy ? null : _blockUser,
                  child: _profileAction(
                    context,
                    'Block',
                    const Color(0xffff3f67),
                    Colors.white,
                    compact: true,
                  ),
                ),
                SizedBox(width: widget.ui(context, 6)),
                GestureDetector(
                  onTap: _busy ? null : _reportUser,
                  child: _profileAction(
                    context,
                    'Report',
                    const Color(0xff2f9bef),
                    Colors.white,
                    compact: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: ui(context, 12)),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(ui(context, 18))),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1.06,
                        child: _photos.isNotEmpty
                            ? Image.network(
                                _photos[_photoIndex],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)),
                              )
                            : Container(color: Colors.grey.shade200),
                      ),
                      Positioned(
                        top: ui(context, 10),
                        left: ui(context, 10),
                        child: _photoBadge(context, '✔️ Verified Photos'),
                      ),
                      Positioned(
                        bottom: ui(context, 10),
                        right: ui(context, 10),
                        child: _photoBadge(context, '${_photoIndex + 1}/${_photos.length}', dark: true),
                      ),
                      Positioned(
                        top: ui(context, 10),
                        right: ui(context, 10),
                        child: Row(
                          children: [
                            _photoArrow(context, Icons.chevron_left, -1),
                            SizedBox(width: ui(context, 5)),
                            _photoArrow(context, Icons.chevron_right, 1),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_photos.length > 1)
                    SizedBox(
                      height: ui(context, 64),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.all(ui(context, 8)),
                        itemCount: _photos.length,
                        separatorBuilder: (_, __) => SizedBox(width: ui(context, 7)),
                        itemBuilder: (_, index) {
                          final selected = index == _photoIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _photoIndex = index),
                            child: Container(
                              width: ui(context, 50),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(ui(context, 10)),
                                border: Border.all(color: selected ? const Color(0xff2f9bef) : Colors.transparent, width: 2),
                                image: DecorationImage(
                                  image: NetworkImage(_photos[index]),
                                  fit: BoxFit.cover,
                                  onError: (error, stackTrace) {},
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: ui(context, 10)),
            _sectionCard(context, 'About Me', 'Bio', [
              Text(widget.user.aboutMe.isNotEmpty ? widget.user.aboutMe : 'No bio provided.', style: TextStyle(fontSize: font(context, 14), color: const Color(0xff39465d), height: 1.35)),
            ]),
            _sectionCard(context, 'Interests', 'Lifestyle', [
              Wrap(
                spacing: ui(context, 7),
                runSpacing: ui(context, 7),
                children: (widget.user.interests.isNotEmpty ? widget.user.interests : ['✨ Caribbean Culture'])
                    .map((x) => _pill(context, x.startsWith('✨') ? x : '✨ $x'))
                    .toList(),
              ),
            ]),
            _sectionCard(context, 'Looking for', 'Intent', [_pill(context, '📍 ${widget.user.whyarewehere}', blue: true)]),
            _sectionCard(context, 'Basics', 'Details', [
              _infoRow(context, 'Work', widget.user.job.isNotEmpty ? widget.user.job : 'Entrepreneur'),
              _infoRow(context, 'University', '🎓 ${widget.user.university.isNotEmpty ? widget.user.university : "American University of Antigua"}', highlight: true),
              _infoRow(context, 'Languages', widget.user.language),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Get.find<SocialController>().sendFriendRequest(
        name: widget.user.firstName,
        uid: widget.user.uid ?? widget.user.laravelId?.toString() ?? '',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _blockUser() async {
    final id = _userId;
    if (id == null) {
      Get.snackbar('Error', 'Unable to block this user');
      return;
    }
    final name = widget.user.firstName.trim().isEmpty ? 'this user' : widget.user.firstName.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block user?'),
        content: Text('You will no longer see $name.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Block')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await LinkupApiService.blockUser(blockedUserId: id);
      Get.snackbar('Blocked', '$name has been blocked');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Get.snackbar('Error', 'Failed to block user');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reportUser() async {
    final id = _userId;
    if (id == null) {
      Get.snackbar('Error', 'Unable to report this user');
      return;
    }
    const reasons = [
      'Inappropriate content',
      'Harassment',
      'Spam',
      'Fake profile',
      'Other',
    ];
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Report user'),
        children: [
          for (final item in reasons)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, item),
              child: Text(item),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      await LinkupApiService.reportUser(
        reportedUserId: id,
        message: reason,
        reason: reason,
        selectedReason: [reason],
      );
      Get.snackbar('Report submitted', 'Thank you. We will review this profile.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit report');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _profileAction(BuildContext context, String label, Color bg, Color fg, {bool compact = false}) {
    return Container(
      height: widget.ui(context, 39),
      padding: EdgeInsets.symmetric(horizontal: widget.ui(context, compact ? 16 : 12)),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(widget.ui(context, 22))),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w900,
            fontSize: widget.font(context, compact ? 12 : 13),
          ),
        ),
      ),
    );
  }

  Widget _photoBadge(BuildContext context, String text, {bool dark = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: widget.ui(context, 9), vertical: widget.ui(context, 5)),
      decoration: BoxDecoration(color: dark ? Colors.black.withOpacity(0.75) : Colors.white, borderRadius: BorderRadius.circular(widget.ui(context, 12))),
      child: Text(text, style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: widget.font(context, 11))),
    );
  }

  Widget _photoArrow(BuildContext context, IconData iconData, int direction) {
    return GestureDetector(
      onTap: () => setState(() => _photoIndex = (_photoIndex + direction + _photos.length) % _photos.length),
      child: Container(
        width: widget.ui(context, 30),
        height: widget.ui(context, 30),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.72), borderRadius: BorderRadius.circular(widget.ui(context, 8))),
        child: Icon(iconData, color: Colors.white, size: widget.icon(context, 18)),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, String title, String tag, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: widget.ui(context, 10)),
      padding: EdgeInsets.all(widget.ui(context, 14)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(widget.ui(context, 18))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(fontSize: widget.font(context, 18), fontWeight: FontWeight.w900, color: Colors.black)),
              const Spacer(),
              Text(tag, style: TextStyle(fontSize: widget.font(context, 11), fontWeight: FontWeight.w900, color: const Color(0xff8b99b2))),
            ],
          ),
          SizedBox(height: widget.ui(context, 9)),
          ...children,
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String text, {bool blue = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: widget.ui(context, 11), vertical: widget.ui(context, 7)),
      decoration: BoxDecoration(color: blue ? const Color(0xffeaf4ff) : const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(widget.ui(context, 14))),
      child: Text(text, style: TextStyle(color: blue ? const Color(0xff2589df) : Colors.black, fontSize: widget.font(context, 12), fontWeight: FontWeight.w900)),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.ui(context, 8)),
      child: Row(
        children: [
          SizedBox(width: widget.ui(context, 96), child: Text(label, style: TextStyle(color: const Color(0xff8798b2), fontWeight: FontWeight.w900, fontSize: widget.font(context, 13)))),
          Expanded(
            child: Container(
              padding: highlight ? EdgeInsets.symmetric(horizontal: widget.ui(context, 9), vertical: widget.ui(context, 5)) : EdgeInsets.zero,
              decoration: highlight ? BoxDecoration(color: const Color(0xffefe7ff), borderRadius: BorderRadius.circular(widget.ui(context, 12))) : null,
              child: Text(value, style: TextStyle(color: highlight ? const Color(0xff6d28d9) : Colors.black, fontWeight: FontWeight.w900, fontSize: widget.font(context, 13))),
            ),
          ),
        ],
      ),
    );
  }
}
