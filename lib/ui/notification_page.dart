import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/notifications_controller.dart';
import 'package:link_up/model/notification_model.dart';
import 'package:link_up/theme/linkup_colors.dart';
import 'DrawerScreen.dart';

Future<void> showLinkUpNotificationsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => const _LinkUpNotificationSheet(),
  );
}

class LinkUpNotificationBell extends StatelessWidget {
  const LinkUpNotificationBell({
    super.key,
    this.iconColor = Colors.white,
    this.iconSize = 26,
    this.badgeSize,
    this.badgeFontSize,
    this.icon = Icons.notifications_none_rounded,
  });

  final Color iconColor;
  final double iconSize;
  final double? badgeSize;
  final double? badgeFontSize;
  final IconData icon;

  NotificationsController get _controller {
    if (Get.isRegistered<NotificationsController>()) {
      return Get.find<NotificationsController>();
    }
    return Get.put(NotificationsController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final double resolvedBadge =
        badgeSize ?? (iconSize * 0.72).clamp(16.0, 26.0).toDouble();
    final double resolvedFont =
        badgeFontSize ?? (resolvedBadge * 0.48).clamp(8.0, 14.0).toDouble();
    return GestureDetector(
      onTap: () => showLinkUpNotificationsSheet(context),
      child: Obx(() {
        final count = controller.unreadTotal.value;
        final label = count > 99 ? '99+' : '$count';
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: iconColor, size: iconSize),
            if (count > 0)
              Positioned(
                right: -resolvedBadge * 0.28,
                top: -resolvedBadge * 0.32,
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: resolvedBadge,
                    minHeight: resolvedBadge,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: count > 9 ? resolvedBadge * 0.18 : 0,
                  ),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xffff3f67),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: resolvedFont,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeaf6ff),
      appBar: AppBar(
        backgroundColor: LinkUpColors.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: _font(context, 21),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      drawer: Drawer(child: DrawerScreen()),
      body: const SafeArea(
        top: false,
        child: _NotificationPanelBody(standalone: true),
      ),
    );
  }
}

class _LinkUpNotificationSheet extends StatelessWidget {
  const _LinkUpNotificationSheet();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.92),
        child: const _NotificationPanelBody(standalone: false),
      ),
    );
  }
}

class _NotificationPanelBody extends StatefulWidget {
  const _NotificationPanelBody({required this.standalone});

  final bool standalone;

  @override
  State<_NotificationPanelBody> createState() => _NotificationPanelBodyState();
}

class _NotificationPanelBodyState extends State<_NotificationPanelBody> {
  late final NotificationsController _controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<NotificationsController>()) {
      Get.put(NotificationsController());
    }
    _controller = Get.find<NotificationsController>();
    _controller.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.standalone ? 0.0 : _ui(context, 24);
    final panel = Container(
      decoration: BoxDecoration(
        color: const Color(0xfff7fbff),
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        boxShadow: widget.standalone
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ],
      ),
      child: Obx(() {
        final unreadCount = _controller.unreadCount;
        final items = _controller.items.toList();
        return Column(
          mainAxisSize: widget.standalone ? MainAxisSize.max : MainAxisSize.min,
          children: [
            _header(context, unreadCount),
            _tabsRail(context),
            Expanded(child: _listBody(context, items)),
          ],
        );
      }),
    );

    if (widget.standalone) return panel;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        child: panel,
      ),
    );
  }

  Widget _listBody(BuildContext context, List<LinkUpNotificationItem> filtered) {
    if (_controller.isLoading.value && _controller.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error.value != null && _controller.items.isEmpty) {
      return _errorState(context);
    }

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _controller.fetchNotifications(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: _ui(context, 80)),
            _emptyState(context),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _controller.fetchNotifications(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          _ui(context, 14),
          _ui(context, 9),
          _ui(context, 14),
          _ui(context, 16) + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => SizedBox(height: _ui(context, 10)),
        itemBuilder: (context, index) {
          final item = filtered[index];
          return _notificationCard(context, item);
        },
      ),
    );
  }

  Widget _header(BuildContext context, int unreadCount) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _ui(context, 18),
        _ui(context, 16),
        _ui(context, 13),
        _ui(context, 16),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff2f9bef), Color(0xff248fe8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: _font(context, 25),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          SizedBox(width: _ui(context, 9)),
          if (unreadCount > 0)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _ui(context, 9),
                vertical: _ui(context, 4),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.23),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$unreadCount new',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _font(context, 12),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: _controller.markAllRead,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _ui(context, 13),
                vertical: _ui(context, 9),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _font(context, 12),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(width: _ui(context, 10)),
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(_ui(context, 3)),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: _ui(context, 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabsRail(BuildContext context) {
    final filters = NotificationsController.filters;
    final selectedType = _controller.selectedType.value;
    return Container(
      color: const Color(0xffffffff),
      padding: EdgeInsets.only(top: _ui(context, 12), bottom: _ui(context, 7)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: _ui(context, 15)),
            child: Row(
              children: List.generate(filters.length, (index) {
                final filter = filters[index];
                final selected = selectedType == filter.type;
                return Padding(
                  padding: EdgeInsets.only(right: _ui(context, 8)),
                  child: GestureDetector(
                    onTap: () => _controller.selectType(filter.type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: _ui(context, 15),
                        vertical: _ui(context, 10),
                      ),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xff2f9bef) : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? const Color(0xff2f9bef)
                              : const Color(0xffd9e4f2),
                          width: 1.3,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: const Color(0xff2f9bef).withOpacity(0.22),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        filter.label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xff334155),
                          fontSize: _font(context, 13),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: _ui(context, 8)),
          Container(
            margin: EdgeInsets.only(left: _ui(context, 15)),
            width: _ui(context, 205),
            height: _ui(context, 5),
            decoration: BoxDecoration(
              color: const Color(0xffbfd9f0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(
    BuildContext context,
    LinkUpNotificationItem item,
  ) {
    final color = _avatarColor(item.tab);
    final tagColor = _tagColor(item.tab);
    return GestureDetector(
      onTap: () => _controller.markRead(item.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(_ui(context, 13)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 15)),
          border: Border.all(
            color: item.unread ? const Color(0xff9bcbff) : const Color(0xffe8eef6),
            width: item.unread ? 1.35 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(context, item, color),
            SizedBox(width: _ui(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.isEmpty ? 'Notification' : item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xff0f172a),
                      fontSize: _font(context, 17),
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: _ui(context, 4)),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xff53647d),
                      fontSize: _font(context, 14),
                      fontWeight: FontWeight.w500,
                      height: 1.22,
                    ),
                  ),
                  SizedBox(height: _ui(context, 9)),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _ui(context, 8),
                          vertical: _ui(context, 4),
                        ),
                        decoration: BoxDecoration(
                          color: tagColor.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.tab,
                          style: TextStyle(
                            color: tagColor,
                            fontSize: _font(context, 10.5),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(width: _ui(context, 8)),
                      Text(
                        item.timeLabel,
                        style: TextStyle(
                          color: const Color(0xff8a99ad),
                          fontSize: _font(context, 12),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: _ui(context, 7)),
            Column(
              children: [
                if (item.unread)
                  Container(
                    width: _ui(context, 9),
                    height: _ui(context, 9),
                    decoration: const BoxDecoration(
                      color: Color(0xff347df2),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (_trailingColor(item.tab) != null) ...[
                  SizedBox(height: _ui(context, 17)),
                  _trailingPreview(context, _trailingColor(item.tab)!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(
    BuildContext context,
    LinkUpNotificationItem item,
    Color color,
  ) {
    final url = item.avatarUrl;
    return Container(
      width: _ui(context, 48),
      height: _ui(context, 48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [color, color.withOpacity(0.72)]),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.24),
            blurRadius: 11,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isNotEmpty
          ? Image.network(
              url,
              width: _ui(context, 48),
              height: _ui(context, 48),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                item.initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _font(context, 14),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Text(
              item.initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: _font(context, 14),
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }

  Widget _trailingPreview(BuildContext context, Color color) {
    return Container(
      width: _ui(context, 46),
      height: _ui(context, 46),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_ui(context, 12)),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color.withOpacity(0.45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_ui(context, 28)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: const Color(0xff2f9bef),
              size: _ui(context, 38),
            ),
            SizedBox(height: _ui(context, 15)),
            Text(
              'Could not load notifications',
              style: TextStyle(
                color: const Color(0xff0f172a),
                fontSize: _font(context, 18),
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: _ui(context, 10)),
            TextButton(
              onPressed: () => _controller.fetchNotifications(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_ui(context, 28)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: _ui(context, 74),
              height: _ui(context, 74),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xff2f9bef).withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: const Color(0xff2f9bef),
                size: _ui(context, 38),
              ),
            ),
            SizedBox(height: _ui(context, 15)),
            Text(
              'No notifications here',
              style: TextStyle(
                color: const Color(0xff0f172a),
                fontSize: _font(context, 20),
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: _ui(context, 6)),
            Text(
              'Try another filter or check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xff74839a),
                fontSize: _font(context, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _avatarColor(String tag) {
  switch (tag) {
    case 'Matches':
      return const Color(0xffe23c88);
    case 'Orders':
      return const Color(0xffd97706);
    case 'Gifts':
      return const Color(0xff8b5cf6);
    case 'Requests':
      return const Color(0xff2563eb);
    case 'Payments':
      return const Color(0xff1e3a8a);
    case 'Eats':
      return const Color(0xff15803d);
    case 'Events':
      return const Color(0xffff8a00);
    case 'System':
      return const Color(0xff475569);
    case 'Priority':
      return const Color(0xff7c3aed);
    default:
      return const Color(0xff2f9bef);
  }
}

Color _tagColor(String tag) {
  switch (tag) {
    case 'Matches':
      return const Color(0xffe23c88);
    case 'Orders':
      return const Color(0xff079669);
    case 'Gifts':
      return const Color(0xffd97706);
    case 'Requests':
      return const Color(0xff64748b);
    case 'Payments':
      return const Color(0xff2f9bef);
    case 'Eats':
      return const Color(0xff16a34a);
    case 'Events':
      return const Color(0xffff8a00);
    case 'System':
      return const Color(0xff475569);
    case 'Priority':
      return const Color(0xff7c3aed);
    default:
      return const Color(0xff2563eb);
  }
}

Color? _trailingColor(String tag) {
  switch (tag) {
    case 'Payments':
      return const Color(0xff2f9bef);
    case 'Orders':
      return const Color(0xff14b8a6);
    case 'Gifts':
      return const Color(0xfff97316);
    case 'Events':
      return const Color(0xffff8a00);
    case 'Eats':
      return const Color(0xff22c55e);
    default:
      return null;
  }
}

double _ui(BuildContext context, double value) {
  final width = MediaQuery.of(context).size.width;
  return value * (width / 430).clamp(0.86, 1.08).toDouble();
}

double _font(BuildContext context, double value) => _ui(context, value);
