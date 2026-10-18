import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:link_up/get_controller/events_controller.dart';
import 'package:link_up/model/event_booking_model.dart';
import 'package:link_up/model/linkup_event.dart';
import 'package:link_up/ui/profile/profile_page.dart';
import 'package:link_up/widgets/linkup_location_sheet.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:link_up/events/BuyTicket.dart';
import 'package:link_up/ui/events/event_booking_ticket_page.dart';
import 'package:link_up/ui/events/event_detail_screen.dart';
import 'package:link_up/ui/chat_home_page.dart';
import 'package:link_up/ui/eats_page.dart';
import 'package:link_up/ui/home_page.dart';
import 'package:link_up/ui/live_page.dart';
import 'package:link_up/ui/notification_page.dart';
import 'package:link_up/ui/vibes_page.dart';
import 'package:link_up/ui/wallet_page.dart';
import 'package:link_up/get_controller/home_controller.dart';
import 'package:link_up/theme/linkup_text_styles.dart';

class AllEvents extends StatefulWidget {
  final String? country;
  final String initialTab;

  const AllEvents({Key? key, this.country, this.initialTab = 'Event'})
      : super(key: key);

  @override
  State<AllEvents> createState() => _AllEventsState();
}

class _AllEventsState extends State<AllEvents> {
  final EventsController eventsController = Get.find<EventsController>();
  final HomeController homeController = Get.find(tag: HomeController().toString());
  
  String _selectedTab = 'Event';
  String _selectedCategory = 'All';
  final Set<int> _expandedBookingIds = <int>{};
  
  // Track controllers for each section
  final Map<String, ScrollController> _scrollControllers = {};

  final List<String> _tabs = const [
    'Event',
    'Booking',
    'Canceled',
    'Favorite',
    'Wallet',
  ];

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.90, 1.08).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    eventsController.fetchEvents();
    if (_selectedTab == 'Booking') {
      eventsController.fetchBookings();
    } else if (_selectedTab == 'Canceled') {
      eventsController.fetchBookings(canceled: true);
    } else if (_selectedTab == 'Favorite') {
      eventsController.fetchFavorites();
    }
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  ScrollController _getController(String key) {
    if (!_scrollControllers.containsKey(key)) {
      _scrollControllers[key] = ScrollController();
    }
    return _scrollControllers[key]!;
  }

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
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff2f9bef),
                      Color(0xff466df0),
                      Color(0xff7f24e5),
                      Color(0xff9917d9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Obx(() {
                  final loadingEvents = eventsController.isLoading.value;
                  final loadingFavorites = eventsController.isFavoritesLoading.value;
                  final loadingBookings = eventsController.isBookingsLoading.value;
                  eventsController.favoriteEvents.length;
                  eventsController.bookings.length;
                  eventsController.canceledBookings.length;
                  if (_selectedTab == 'Event' && loadingEvents) {
                    return _loadingStrip(context);
                  }
                  if (_selectedTab == 'Favorite' &&
                      loadingFavorites &&
                      eventsController.favoriteEvents.isEmpty) {
                    return _loadingStrip(context);
                  }
                  if (_selectedTab == 'Booking' &&
                      loadingBookings &&
                      eventsController.bookings.isEmpty) {
                    return _loadingStrip(context);
                  }
                  if (_selectedTab == 'Canceled' &&
                      loadingBookings &&
                      eventsController.canceledBookings.isEmpty) {
                    return _loadingStrip(context);
                  }

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      _ui(context, 12),
                      _ui(context, 12),
                      _ui(context, 12),
                      _ui(context, 26),
                    ),
                    children: [
                      _pageTitle(context),
                      SizedBox(height: _ui(context, 14)),
                      _statusTabs(context),
                      if (_selectedTab == 'Event' ||
                          _selectedTab == 'Favorite') ...[
                        SizedBox(height: _ui(context, 12)),
                        _categoryRail(context),
                        SizedBox(height: _ui(context, 12)),
                        _askAiBar(context),
                      ],
                      SizedBox(height: _ui(context, 14)),
                      if (_selectedTab == 'Event')
                        ..._eventContent(context)
                      else if (_selectedTab == 'Favorite')
                        ..._favoriteContent(context)
                      else if (_selectedTab == 'Booking')
                        ..._bookingContent(context, canceled: false)
                      else if (_selectedTab == 'Canceled')
                        ..._bookingContent(context, canceled: true)
                      else
                        _tabPlaceholder(context),
                    ],
                  );
                }),
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _eventContent(BuildContext context) {
    final response = eventsController.eventsResponse.value;
    final List<Widget> sections = [];

    // Fixed order as per requirements
    final order = [
      'new_providence',
      'event_low_cost',
      'free_events',
      'jamaica_event',
      'events',
    ];

    final titles = {
      'new_providence': 'Top Trending Events',
      'event_low_cost': 'Event 30\$ and under',
      'free_events': 'Free Events',
      'jamaica_event': 'Events in BS',
      'events': 'More Events',
    };

    for (final key in order) {
      final events = response.sections[key] ?? [];

      if (key == 'free_events') {
        sections.add(
          _eventSection(
            context,
            title: titles[key]!,
            events: events,
            controller: _getController(key),
            showEmptyPlaceholder: true,
          ),
        );
        sections.add(SizedBox(height: _ui(context, 18)));
        continue;
      }

      if (events.isEmpty) continue;

      List<LinkupEvent> filteredEvents = events;
      if (_selectedCategory != 'All') {
        filteredEvents = events
            .where((e) => e.categoryName
                .toLowerCase()
                .contains(_selectedCategory.toLowerCase()))
            .toList();
      }

      if (filteredEvents.isEmpty) continue;

      sections.add(
        _eventSection(
          context,
          title: titles[key]!,
          events: filteredEvents,
          controller: _getController(key),
        ),
      );
      sections.add(SizedBox(height: _ui(context, 18)));
    }

    if (sections.isEmpty) {
      sections.add(
        Center(
          child: Padding(
            padding: EdgeInsets.only(top: _ui(context, 40)),
            child: const Text(
              'No events found in this category.',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return sections;
  }

  List<Widget> _favoriteContent(BuildContext context) {
    var events = eventsController.favoriteEvents.toList();
    if (_selectedCategory != 'All') {
      events = events
          .where((e) => e.categoryName
              .toLowerCase()
              .contains(_selectedCategory.toLowerCase()))
          .toList();
    }

    if (events.isEmpty) {
      return [_tabPlaceholder(context)];
    }

    return [
      _eventSection(
        context,
        title: 'Favorite Events',
        events: events,
        controller: _getController('favorites'),
      ),
    ];
  }

  List<Widget> _bookingContent(BuildContext context, {required bool canceled}) {
    var items = canceled
        ? eventsController.canceledBookings.toList()
        : eventsController.bookings.toList();
    if (_selectedCategory != 'All') {
      items = items
          .where((booking) => booking.ticketType
              .toLowerCase()
              .contains(_selectedCategory.toLowerCase()))
          .toList();
    }
    final groups = groupEventBookings(items);

    if (groups.isEmpty) {
      return [_tabPlaceholder(context)];
    }

    return [
      ...List.generate(groups.length, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: _ui(context, 14)),
          child: _bookingGroupCard(context, groups[index]),
        );
      }),
    ];
  }

  Widget _bookingGroupCard(BuildContext context, EventBookingGroup group) {
    final expanded = _expandedBookingIds.contains(group.eventId);
    final event = group.event;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: _ui(context, 16),
            offset: Offset(0, _ui(context, 8)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 2.05,
                child: event.imageUrl.isEmpty
                    ? Container(color: const Color(0xffdbeafe))
                    : Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: const Color(0xffdbeafe)),
                      ),
              ),
              Positioned(
                left: _ui(context, 10),
                bottom: _ui(context, 10),
                child: _bookingBadge(
                  context,
                  group.latest.date.isNotEmpty
                      ? group.latest.date
                      : group.latest.eventDateLabel,
                  Colors.white,
                  const Color(0xff1f2937),
                ),
              ),
              Positioned(
                right: _ui(context, 9),
                top: _ui(context, 9),
                child: _bookingBadge(
                  context,
                  group.ticketsBadge,
                  const Color(0xff2f6fff),
                  Colors.white,
                ),
              ),
            ],
          ),
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
                  event.title.isEmpty ? 'Event' : event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: _font(context, 18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (group.subtitle.isNotEmpty) ...[
                  SizedBox(height: _ui(context, 3)),
                  Text(
                    group.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xff8ba0bb),
                      fontSize: _font(context, 13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                SizedBox(height: _ui(context, 10)),
                _bookingSummaryLine(
                  context,
                  'Total Purchases:',
                  '${group.purchaseCount}',
                ),
                _bookingSummaryLine(
                  context,
                  'Total Tickets:',
                  '${group.ticketCount}',
                ),
                _bookingSummaryLine(
                  context,
                  'Total Paid:',
                  group.paidLabel,
                  valueColor: const Color(0xff08a66d),
                ),
                SizedBox(height: _ui(context, 12)),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (expanded) {
                        _expandedBookingIds.remove(group.eventId);
                      } else {
                        _expandedBookingIds.add(group.eventId);
                      }
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    height: _ui(context, 42),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xfff3f4f6),
                      borderRadius: BorderRadius.circular(_ui(context, 12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Show All Purchases',
                          style: TextStyle(
                            color: const Color(0xff4b5563),
                            fontSize: _font(context, 13),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: _ui(context, 4)),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xff4b5563),
                          size: _ui(context, 20),
                        ),
                      ],
                    ),
                  ),
                ),
                if (expanded) ...[
                  SizedBox(height: _ui(context, 8)),
                  ...group.purchases.map(
                    (purchase) => _purchaseRow(context, purchase),
                  ),
                ],
                SizedBox(height: _ui(context, 8)),
                GestureDetector(
                  onTap: () => Get.to(
                    () => EventBookingTicketPage(booking: group.latest),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: _ui(context, 46),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xff2563eb),
                      borderRadius: BorderRadius.circular(_ui(context, 12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          color: Colors.white,
                          size: _ui(context, 20),
                        ),
                        SizedBox(width: _ui(context, 8)),
                        Text(
                          'View Latest Ticket',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _purchaseRow(BuildContext context, EventBooking purchase) {
    return GestureDetector(
      onTap: () => Get.to(() => EventBookingTicketPage(booking: purchase)),
      child: Container(
        margin: EdgeInsets.only(bottom: _ui(context, 8)),
        padding: EdgeInsets.symmetric(
          horizontal: _ui(context, 12),
          vertical: _ui(context, 10),
        ),
        decoration: BoxDecoration(
          color: const Color(0xfff8fafc),
          borderRadius: BorderRadius.circular(_ui(context, 12)),
          border: Border.all(color: const Color(0xffe5edf6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purchase.ticketName.isEmpty
                        ? 'Ticket'
                        : purchase.ticketName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xff142033),
                      fontSize: _font(context, 13),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: _ui(context, 2)),
                  Text(
                    '${purchase.date} · ${purchase.ticketCount} ticket${purchase.ticketCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: const Color(0xff7a8aa0),
                      fontSize: _font(context, 11),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              purchase.paidLabel,
              style: TextStyle(
                color: const Color(0xff08a66d),
                fontSize: _font(context, 13),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingSummaryLine(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: _ui(context, 4)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xff687892),
                fontSize: _font(context, 13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black,
              fontSize: _font(context, 13),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingBadge(
    BuildContext context,
    String text,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _ui(context, 8),
        vertical: _ui(context, 5),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(_ui(context, 10)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: _font(context, 11),
          fontWeight: FontWeight.w900,
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
              Text(
                'ü',
                style: LinkUpTextStyles.openSansStyle(
                  color: const Color(0xff9edb2f),
                  fontSize: _font(context, 24),
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(width: _ui(context, 8)),
              Text(
                'Link',
                style: LinkUpTextStyles.openSansStyle(
                  color: Colors.white,
                  fontSize: _font(context, 27),
                  fontWeight: FontWeight.w900,
                  height: 1,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
              Text(
                'üp',
                style: LinkUpTextStyles.openSansStyle(
                  color: const Color(0xffffe14d),
                  fontSize: _font(context, 24),
                  fontWeight: FontWeight.w900,
                  height: 1,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
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
                  Icon(Icons.monetization_on_outlined,
                      color: Colors.white, size: _ui(context, 16)),
                  SizedBox(width: _ui(context, 6)),
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
            iconSize: _ui(context, 25),
            badgeSize: _ui(context, 19),
            badgeFontSize: 10,
          ),
          SizedBox(width: _ui(context, 12)),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
            child: CircleAvatar(
              radius: _ui(context, 16),
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: _ui(context, 14),
                backgroundImage: const AssetImage('assets/profile2.jpg'),
              ),
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
      textColor: const Color(0xff26364d),
      changeColor: const Color(0xff168eea),
      iconColor: const Color(0xff2f9bef),
    );
  }

  Widget _pageTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedTab == 'Booking' || _selectedTab == 'Canceled'
                    ? 'My Bookings'
                    : '🎉 Events',
                style: LinkUpTextStyles.openSansStyle(
                  color: Colors.white,
                  fontSize: _font(context, 25),
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              SizedBox(height: _ui(context, 4)),
              Text(
                _selectedTab == 'Booking' || _selectedTab == 'Canceled'
                    ? 'Your confirmed ticket purchases, grouped by event'
                    : 'Fêtes, spas, cookouts & more near you',
                style: LinkUpTextStyles.openSansStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: _font(context, 12),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: _ui(context, 36),
          height: _ui(context, 36),
          decoration: BoxDecoration(
            color: const Color(0xffff7d95),
            borderRadius: BorderRadius.circular(_ui(context, 9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: _ui(context, 14),
                offset: Offset(0, _ui(context, 8)),
              ),
            ],
          ),
          child: Icon(Icons.confirmation_number_rounded,
              color: Colors.white, size: _ui(context, 19)),
        ),
      ],
    );
  }

  Widget _statusTabs(BuildContext context) {
    return SizedBox(
      height: _ui(context, 38),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => SizedBox(width: _ui(context, 8)),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final selected = tab == _selectedTab;
          return GestureDetector(
            onTap: () {
              if (tab == 'Wallet') {
                Get.to(() => const WalletPage());
                return;
              }
              setState(() => _selectedTab = tab);
              if (tab == 'Favorite') {
                eventsController.fetchFavorites();
              } else if (tab == 'Booking') {
                eventsController.fetchBookings();
              } else if (tab == 'Canceled') {
                eventsController.fetchBookings(canceled: true);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 18)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? const Color(0xffffe14d) : Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(_ui(context, 20)),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: selected ? const Color(0xff0f172a) : Colors.white,
                  fontSize: _font(context, 13),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryRail(BuildContext context) {
    final response = eventsController.eventsResponse.value;
    final Set<String> distinctCategories = {'All'};
    response.sections.forEach((key, events) {
      for (final e in events) {
        if (e.categoryName.isNotEmpty) distinctCategories.add(e.categoryName);
      }
    });
    final categoryList = distinctCategories.toList()..sort((a, b) => a == 'All' ? -1 : b == 'All' ? 1 : a.compareTo(b));

    return Column(
      children: [
        SizedBox(
          height: _ui(context, 46),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categoryList.length,
            separatorBuilder: (_, __) => SizedBox(width: _ui(context, 9)),
            itemBuilder: (context, index) {
              final catName = categoryList[index];
              final selected = catName == _selectedCategory;
              
              IconData icon = Icons.grid_view_rounded;
              if (catName.toLowerCase().contains('music')) icon = Icons.music_note_rounded;
              else if (catName.toLowerCase().contains('food')) icon = Icons.local_fire_department_rounded;
              else if (catName.toLowerCase().contains('art')) icon = Icons.palette_rounded;
              else if (catName.toLowerCase().contains('travel')) icon = Icons.public_rounded;
              else if (catName.toLowerCase().contains('wellness')) icon = Icons.spa_rounded;

              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = catName),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.only(
                    left: _ui(context, 9),
                    right: _ui(context, 14),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_ui(context, 22)),
                    border: Border.all(
                      color: selected ? const Color(0xffffe14d) : Colors.transparent,
                      width: _ui(context, 2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: _ui(context, 12),
                        offset: Offset(0, _ui(context, 5)),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: _ui(context, 29),
                        height: _ui(context, 29),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xffffe14d).withOpacity(0.38)
                              : const Color(0xffeaf4fe),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon,
                            color: const Color(0xff2f9bef), size: _ui(context, 17)),
                      ),
                      SizedBox(width: _ui(context, 8)),
                      Text(
                        catName,
                        style: TextStyle(
                          color: const Color(0xff26364d),
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
      ],
    );
  }

  Widget _askAiBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showAiPopup(context),
            child: Container(
              height: _ui(context, 39),
              padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_ui(context, 22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: _ui(context, 12),
                    offset: Offset(0, _ui(context, 5)),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: const Color(0xff7c3aed), size: _ui(context, 18)),
                  SizedBox(width: _ui(context, 8)),
                  const Expanded(
                    child: Text(
                      'Ask AI: free fêtes this weekend...',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xff9aa9bd),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: _ui(context, 9)),
        GestureDetector(
          onTap: () => _showAiPopup(context),
          child: Container(
            height: _ui(context, 39),
            padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
            decoration: BoxDecoration(
              color: const Color(0xffffe14d),
              borderRadius: BorderRadius.circular(_ui(context, 13)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: _ui(context, 12),
                  offset: Offset(0, _ui(context, 5)),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: const Color(0xff111827), size: _ui(context, 17)),
                SizedBox(width: _ui(context, 5)),
                const Text(
                  'AI',
                  style: TextStyle(
                    color: Color(0xff111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _loadingStrip(BuildContext context) {
    return Container(
      height: _ui(context, 152),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _tabPlaceholder(BuildContext context) {
    final title = _selectedTab == 'Booking'
        ? 'Your bookings will appear here.'
        : _selectedTab == 'Canceled'
            ? 'Canceled events will appear here.'
            : 'Favorite events will appear here.';

    final subtitle = _selectedTab == 'Booking'
        ? 'Buy a ticket from any event card to start building this list.'
        : _selectedTab == 'Canceled'
            ? 'We will keep your canceled tickets organized by date.'
            : 'Tap the heart on an event to save it for later.';

    return Container(
      margin: EdgeInsets.only(top: _ui(context, 8)),
      padding: EdgeInsets.all(_ui(context, 18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 24)),
      ),
      child: Column(
        children: [
          Container(
            width: _ui(context, 54),
            height: _ui(context, 54),
            decoration: BoxDecoration(
              color: const Color(0xffeaf4fe),
              borderRadius: BorderRadius.circular(_ui(context, 18)),
            ),
            child: Icon(
              _selectedTab == 'Favorite'
                  ? Icons.favorite_rounded
                  : Icons.confirmation_number_outlined,
              color: const Color(0xff2f9bef),
              size: _ui(context, 27),
            ),
          ),
          SizedBox(height: _ui(context, 14)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xff142033),
              fontSize: _font(context, 17),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: _ui(context, 6)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xff7a8aa0),
              fontSize: _font(context, 12),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventSection(
    BuildContext context, {
    required String title,
    required List<LinkupEvent> events,
    required ScrollController controller,
    bool showEmptyPlaceholder = false,
  }) {
    if (events.isEmpty && !showEmptyPlaceholder) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _font(context, 20),
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            if (events.isNotEmpty) ...[
              _roundRailButton(
                context,
                Icons.chevron_left_rounded,
                () => _scrollRail(context, controller, -1),
              ),
              SizedBox(width: _ui(context, 7)),
              _roundRailButton(
                context,
                Icons.chevron_right_rounded,
                () => _scrollRail(context, controller, 1),
              ),
            ],
          ],
        ),
        SizedBox(height: _ui(context, 11)),
        if (events.isEmpty && showEmptyPlaceholder)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: _ui(context, 20)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_ui(context, 14)),
            ),
            child: Text(
              'No Free Events found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: _font(context, 14),
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          SizedBox(
            height: _ui(context, 166),
            child: ListView.separated(
              controller: controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, __) => SizedBox(width: _ui(context, 10)),
              itemBuilder: (context, index) {
                return _eventCard(context, events[index]);
              },
            ),
          ),
      ],
    );
  }

  void _scrollRail(BuildContext context, ScrollController controller, int direction) {
    if (!controller.hasClients) return;
    final distance = _ui(context, 181);
    final target = (controller.offset + (distance * direction))
        .clamp(0.0, controller.position.maxScrollExtent)
        .toDouble();
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _roundRailButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _ui(context, 30),
        height: _ui(context, 30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.24),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: _ui(context, 21)),
      ),
    );
  }

  Widget _eventCard(BuildContext context, LinkupEvent event) {
    final width = _ui(context, 171);
    final imageHeight = _ui(context, 116);

    return GestureDetector(
      onTap: () => _openEvent(event),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: _ui(context, 16),
              offset: Offset(0, _ui(context, 8)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_ui(context, 14)),
          child: Column(
            children: [
              SizedBox(
                height: imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _eventCover(context, event.imageUrl),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.06),
                            Colors.black.withOpacity(0.70),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      top: _ui(context, 6),
                      left: _ui(context, 6),
                      right: _ui(context, 40),
                      child: Row(
                        children: [
                          _dateBadge(context, event.month, event.day),
                          SizedBox(width: _ui(context, 5)),
                          Flexible(child: _categoryBadge(context, event.categoryName)),
                        ],
                      ),
                    ),
                    Positioned(
                      top: _ui(context, 6),
                      right: _ui(context, 6),
                      child: _heartButton(context, event),
                    ),
                    Positioned(
                      left: _ui(context, 9),
                      right: _ui(context, 9),
                      bottom: _ui(context, 8),
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _font(context, 15),
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _ui(context, 9),
                    _ui(context, 8),
                    _ui(context, 8),
                    _ui(context, 7),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          '${event.city}, ${event.country}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xff94a3b8),
                            fontSize: _font(context, 11),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: _ui(context, 6)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _ui(context, 8),
                          vertical: _ui(context, 5),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff5c6cf5),
                          borderRadius: BorderRadius.circular(_ui(context, 14)),
                        ),
                        child: Text(
                          event.isFree ? 'FREE' : '\$30+',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _font(context, 10),
                            fontWeight: FontWeight.w900,
                          ),
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
    );
  }

  Widget _eventCover(BuildContext context, String url) {
    if (url.isEmpty) {
      return Container(color: Colors.grey.shade300);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.black.withOpacity(0.05),
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
      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
    );
  }

  Widget _dateBadge(BuildContext context, String month, String day) {
    return Container(
      width: _ui(context, 30),
      height: _ui(context, 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: _ui(context, 2)),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_ui(context, 6)),
                topRight: Radius.circular(_ui(context, 6)),
              ),
            ),
            child: Text(
              month.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  color: Color(0xff111827),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heartButton(BuildContext context, LinkupEvent event) {
    final size = _ui(context, 28);
    return GestureDetector(
      onTap: () => eventsController.toggleFavorite(event),
      child: Obx(() {
        final favourite =
            eventsController.favouriteFlags[event.id] ?? event.isFavourite;
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: favourite ? Colors.white : Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(
            favourite ? Icons.favorite : Icons.favorite_border,
            color: favourite ? Colors.red : Colors.white,
            size: _ui(context, 16),
          ),
        );
      }),
    );
  }

  Widget _categoryBadge(BuildContext context, String category) {
    final label = category.trim().isEmpty ? 'Event' : category;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: _ui(context, 96)),
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
      decoration: BoxDecoration(
        color: const Color(0xff09aa7a),
        borderRadius: BorderRadius.circular(10),
      ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  void _openEvent(LinkupEvent event) {
    Get.to(() => EventDetailScreen(slug: event.slug));
  }

  void _showAiPopup(BuildContext context) {
    // AI Popup implementation same as before
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
                if (item[1] == 'Home') Get.off(() => HomePage());
                if (item[1] == 'Vibes') Get.off(() => const VibesPage());
                if (item[1] == 'Eats') Get.off(() => const EatsPage());
                if (item[1] == 'Live') Get.off(() => const LivePage());
                if (item[1] == 'LinkUp') Get.off(() => ChatHomePage());
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
                      size: _ui(context, 24),
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
