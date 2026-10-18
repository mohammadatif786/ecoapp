import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:link_up/get_controller/events_controller.dart';
import 'package:link_up/model/event_detail_model.dart';
import 'package:link_up/model/linkup_event.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:link_up/element/full_screen_image.dart';

import 'package:link_up/get_controller/event_booking_controller.dart';
import 'package:link_up/get_controller/auth_controller.dart';
import 'package:link_up/get_controller/ChatController.dart';

class EventDetailScreen extends StatefulWidget {
  final String slug;

  const EventDetailScreen({super.key, required this.slug});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventsController eventsController = Get.find<EventsController>();
  final EventBookingController bookingController = Get.find<EventBookingController>();
  final AuthController authController = Get.find(tag: AuthController().toString());

  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmitting = false;
  Review? _editingReview;
  GoogleMapController? _pinMapController;

  @override
  void initState() {
    super.initState();
    eventsController.fetchEventDetail(widget.slug);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _pinMapController?.dispose();
    super.dispose();
  }

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) {
    return _ui(context, value * 0.9);
  }

  String _formatReviewDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy · hh:mm a').format(dateTime);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          if (eventsController.isDetailLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail = eventsController.eventDetail.value;
          if (detail == null) {
            return const Center(child: Text('Failed to load event details.'));
          }

          return _buildContent(context, detail.data);
        }),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EventData data) {
    final event = data.event;

    return Column(
      children: [
        _buildHeader(context, event),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroImage(context, event),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: _ui(context, 20), vertical: _ui(context, 16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(context, event),
                      SizedBox(height: _ui(context, 16)),
                      _buildStatsRow(context, event, data.attendees.length),
                      SizedBox(height: _ui(context, 20)),
                      _buildActionButtons(context, event),
                      SizedBox(height: _ui(context, 24)),
                      _buildAboutSection(context, event),
                      _buildDisclaimerSection(context, event),
                      
                      if (event.eventDetails.imageGallery.isNotEmpty) ...[
                        _buildGallerySection(context, event.eventDetails.imageGallery),
                        SizedBox(height: _ui(context, 24)),
                      ],

                      _buildOrganizerSection(context, data.organizerStats),
                      _buildEventFactsSection(context, event),
                      _buildLocationSection(context, data),
                      
                      if (data.sponsors.isNotEmpty) ...[
                        _buildSponsorsSection(context, data.sponsors),
                        SizedBox(height: _ui(context, 24)),
                      ],

                      if (data.attendees.isNotEmpty) ...[
                        _buildAttendeesSection(context, data.attendees),
                      ],
                      _buildReviewsSection(context, event),
                      _buildMoreEventsSection(context, data.otherEvents),
                      SizedBox(height: _ui(context, 40)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, EventDetail event) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _ui(context, 16), vertical: _ui(context, 12)),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xfff1f5f9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: _font(context, 18), fontWeight: FontWeight.w900, color: const Color(0xff0f172a)),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xfff1f5f9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.close, size: 14),
                  SizedBox(width: 4),
                  Text('Close', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, EventDetail event) {
    final height = _ui(context, 220);
    if (event.imageUrl.isEmpty) {
      return Container(
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.event, color: Colors.grey, size: 48),
      );
    }
    return Image.network(
      event.imageUrl,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height,
          color: Colors.grey[100],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, EventDetail event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: TextStyle(fontSize: _font(context, 24), fontWeight: FontWeight.w900, color: const Color(0xff0f172a)),
        ),
        const SizedBox(height: 4),
        Text(
          _eventDateLabel(event),
          style: TextStyle(fontSize: _font(context, 14), color: const Color(0xff94a3b8), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xffeef6ff),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            event.categoryName,
            style: TextStyle(color: const Color(0xff2563eb), fontSize: _font(context, 12), fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, EventDetail event, int attendeeCount) {
    return Row(
      children: [
        _buildStatBox(context, 'TYPE', event.type.toLowerCase()),
        SizedBox(width: _ui(context, 8)),
        _buildStatBox(context, 'GOING', event.likesCount.toString()),
        SizedBox(width: _ui(context, 8)),
        _buildStatBox(context, 'ATTENDEES', attendeeCount.toString()),
        SizedBox(width: _ui(context, 8)),
        _buildStatBox(context, 'REVIEWS', event.reviewsCount.toString()),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffdbe5f0)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xff8fa0b6), fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xff0f172a))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EventDetail event) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _btn(
            context,
            label: 'Buy Tickets',
            icon: Icons.confirmation_number_outlined,
            filled: true,
            onTap: () => _showBookingDialog(context, event),
          ),
        ),
        SizedBox(width: _ui(context, 8)),
        Expanded(
          flex: 2,
          child: _btn(
            context,
            label: 'Save',
            onTap: () {},
          ),
        ),
        SizedBox(width: _ui(context, 8)),
        Expanded(
          flex: 2,
          child: _btn(
            context,
            label: 'Share',
            onTap: () {
              Share.share('Check out ${event.title} on LinkUp!\nhttps://linkupvibes.com/events/${event.slug}');
            },
          ),
        ),
      ],
    );
  }

  Widget _btn(
    BuildContext context, {
    required String label,
    IconData? icon,
    required VoidCallback onTap,
    bool filled = false,
    bool enabled = true,
  }) {
    return SizedBox(
      height: 44,
      child: filled
          ? ElevatedButton.icon(
              onPressed: enabled ? onTap : null,
              icon: Icon(icon, size: 16),
              label: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled
                    ? const Color(0xff2f9cec)
                    : const Color(0xff94a3b8),
                disabledBackgroundColor: const Color(0xff94a3b8),
                disabledForegroundColor: Colors.white,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )
          : OutlinedButton(
              onPressed: enabled ? onTap : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff0f172a),
                side: const BorderSide(color: Color(0xffdbe5f0), width: 1.5),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 12)),
            ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: _font(context, 16), fontWeight: FontWeight.w900, color: const Color(0xff0f172a))),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: content,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, EventDetail event) {
    return _buildSection('About Event', Text(event.description, style: const TextStyle(color: Color(0xff64748b), height: 1.4)));
  }

  Widget _buildDisclaimerSection(BuildContext context, EventDetail event) {
    final text = _stripHtml(event.disclaimer);
    if (text.isEmpty) return const SizedBox();
    return _buildSection(
      'Disclaimer',
      Text(text, style: const TextStyle(color: Color(0xff64748b), height: 1.4)),
    );
  }

  Widget _buildGallerySection(BuildContext context, List<dynamic> gallery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Media Gallery', style: TextStyle(fontSize: _font(context, 16), fontWeight: FontWeight.w900, color: const Color(0xff0f172a))),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gallery.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              final url = gallery[index].toString();
              return GestureDetector(
                onTap: () => Get.to(() => FullScreenImage(imageURL: url, tag: url)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(url, fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOrganizerSection(BuildContext context, OrganizerStats stats) {
    final organizerId = stats.organizerId > 0
        ? stats.organizerId
        : eventsController.eventDetail.value?.data.event.organizerId ?? 0;
    final toggling = eventsController.isTogglingOrganizerFollow.value;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xffe2e8f0),
                backgroundImage: stats.organizerAvatar.isNotEmpty
                    ? NetworkImage(stats.organizerAvatar)
                    : null,
                child: stats.organizerAvatar.isEmpty
                    ? Text(
                        stats.organizerName.isNotEmpty
                            ? stats.organizerName[0].toUpperCase()
                            : 'O',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stats.organizerName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: _font(context, 15))),
                    const SizedBox(height: 2),
                    Text('Organizer · responds within 24h · ${stats.followersCount} followers', style: const TextStyle(color: Color(0xff8fa0b6), fontSize: 11)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: organizerId <= 0 || toggling
                    ? null
                    : () => eventsController.toggleOrganizerFollow(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: stats.isFollowing
                      ? const Color(0xffeef2ff)
                      : const Color(0xff2f9cec),
                  foregroundColor: stats.isFollowing
                      ? const Color(0xff2f9cec)
                      : Colors.white,
                  disabledBackgroundColor: stats.isFollowing
                      ? const Color(0xffeef2ff)
                      : const Color(0xff2f9cec).withOpacity(0.6),
                  disabledForegroundColor: stats.isFollowing
                      ? const Color(0xff2f9cec)
                      : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: toggling
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: stats.isFollowing
                              ? const Color(0xff2f9cec)
                              : Colors.white,
                        ),
                      )
                    : Text(
                        stats.isFollowing ? 'Unfollow' : 'Follow',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEventFactsSection(BuildContext context, EventDetail event) {
    final d = event.eventDetails;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Event Facts',
            style: TextStyle(
                fontSize: _font(context, 16),
                fontWeight: FontWeight.w900,
                color: const Color(0xff0f172a))),
        const SizedBox(height: 10),
        _buildFactBox('EVENT TYPE', d.eventType.toLowerCase()),
        const SizedBox(height: 8),
        _buildFactBox('SEATING PLAN', d.seatingPlan ? 'Yes' : 'No'),
        const SizedBox(height: 8),
        if (d.ageRequirement != null) ...[
          _buildFactBox('AGE REQUIREMENT', d.ageRequirement!),
          const SizedBox(height: 8),
        ],
        if (d.dressCode != null) ...[
          _buildFactBox('DRESS CODE', d.dressCode!),
          const SizedBox(height: 8),
        ],
        _buildFactBox('WEBSITE', event.website.isNotEmpty ? event.website : 'TBA'),
        const SizedBox(height: 8),
        _buildFactBox('EMAIL', event.email.isNotEmpty ? event.email : 'TBA'),
        const SizedBox(height: 8),
        _buildFactBox('PHONE', event.phone.isNotEmpty ? event.phone : 'TBA'),
        const SizedBox(height: 8),
        _buildFactBox('LOCATION', '${event.country}, ${event.state}, ${event.city}'),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFactBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffdbe5f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xff8fa0b6), fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Color(0xff111827), fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, EventData data) {
    final event = data.event;
    final venue = (event.venue ?? '').trim();
    final place = [
      if (venue.isNotEmpty) venue,
      if (event.city.isNotEmpty) event.city,
      if (event.state.isNotEmpty) event.state,
      if (event.country.isNotEmpty) event.country,
    ].join(', ');
    final hasCoords = event.latitude != null && event.longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: TextStyle(fontSize: _font(context, 16), fontWeight: FontWeight.w900, color: const Color(0xff0f172a))),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFactBox('VENUE', place.isNotEmpty ? place : 'To be announced'),
              if (hasCoords || event.imageUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    width: double.infinity,
                    height: 126,
                    child: event.imageUrl.isNotEmpty
                        ? Image.network(
                            event.imageUrl,
                            width: double.infinity,
                            height: 126,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xffe2e8f0),
                              child: const Icon(Icons.location_on_outlined),
                            ),
                          )
                        : Container(
                            color: const Color(0xffe2e8f0),
                            child: const Icon(Icons.location_on_outlined),
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final query = Uri.encodeComponent(place.isNotEmpty
                        ? place
                        : '${event.city} ${event.country}');
                    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.near_me_outlined, size: 18),
                  label: const Text('Get Directions', style: TextStyle(fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2f9cec),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSponsorsSection(BuildContext context, List<Sponsor> sponsors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sponsors', style: TextStyle(fontSize: _font(context, 16), fontWeight: FontWeight.w900, color: const Color(0xff0f172a))),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: sponsors.map((s) => Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xffe2e8f0)),
                    image: DecorationImage(image: NetworkImage(s.imageUrl), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 4),
                Text(s.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeesSection(BuildContext context, List<Attendee> attendees) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attendees (${attendees.length})', style: TextStyle(fontSize: _font(context, 16), fontWeight: FontWeight.w900, color: const Color(0xff0f172a))),
        const SizedBox(height: 4),
        const Text('Showing attendees who purchased tickets', style: TextStyle(color: Color(0xff8fa0b6), fontSize: 12)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: Row(
            children: attendees.take(5).map((a) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CircleAvatar(radius: 16, backgroundImage: NetworkImage(a.avatar)),
            )).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, EventDetail event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews & Ratings',
            style: TextStyle(
                fontSize: _font(context, 16),
                fontWeight: FontWeight.w900,
                color: const Color(0xff0f172a))),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(event.averageRating.toString(),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff238df2))),
                  const SizedBox(width: 8),
                  Row(
                      children: List.generate(
                          5,
                          (i) => Icon(Icons.star,
                              color: i < event.averageRating
                                  ? const Color(0xffffc83d)
                                  : Colors.grey[200],
                              size: 18))),
                  const SizedBox(width: 8),
                  Text('${event.reviewsCount} reviews',
                      style: const TextStyle(
                          color: Color(0xff8fa0b6), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 24),
              if (event.reviews.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No reviews yet. Be the first!',
                      style: TextStyle(
                          color: Color(0xff8fa0b6),
                          fontSize: 13,
                          fontStyle: FontStyle.italic)),
                ))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: event.reviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final r = event.reviews[index];
                    final user = authController.user?.value;
                    final currentUserName = user != null
                        ? '${user.firstName} ${user.lastName}'.trim()
                        : '';
                    final isMyReview = r.reviewerName == currentUserName;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(r.reviewerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 14)),
                            if (isMyReview) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(4)),
                                child: const Text('YOU',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue)),
                              ),
                            ],
                            const Spacer(),
                            Row(
                                children: List.generate(
                                    5,
                                    (i) => Icon(Icons.star,
                                        color: i < r.rating
                                            ? const Color(0xffffc83d)
                                            : Colors.grey[200],
                                        size: 12))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(_formatReviewDate(r.createdAt),
                                style: const TextStyle(
                                    color: Color(0xff94a3b8), fontSize: 11)),
                            const Spacer(),
                            if (isMyReview) ...[
                              GestureDetector(
                                onTap: () => _startEditingReview(r),
                                child: const Icon(Icons.edit_outlined,
                                    size: 16, color: Color(0xff64748b)),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _confirmDeleteReview(event.id, r.id),
                                child: const Icon(Icons.delete_outline,
                                    size: 16, color: Color(0xffef4444)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(r.reviewText,
                            style: const TextStyle(
                                color: Color(0xff475569),
                                fontSize: 13,
                                height: 1.4)),
                      ],
                    );
                  },
                ),
              const Divider(height: 40),
              Row(
                children: [
                  Text(_editingReview != null ? 'Edit Your Review' : 'Leave a Review',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  const Spacer(),
                  if (_editingReview != null)
                    GestureDetector(
                      onTap: _cancelEditing,
                      child: const Text('Cancel Edit',
                          style: TextStyle(
                              color: Color(0xffef4444),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                    5,
                    (i) => GestureDetector(
                          onTap: () => setState(() => _selectedRating = i + 1),
                          child: Icon(
                            i < _selectedRating ? Icons.star : Icons.star_outline,
                            color: i < _selectedRating
                                ? const Color(0xffffc83d)
                                : const Color(0xffcbd5e1),
                            size: 32,
                          ),
                        )),
              ),
              const SizedBox(height: 16),
              _reviewInput('Share your experience...',
                  controller: _reviewController, lines: 3),
              const SizedBox(height: 16),
              SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitOrUpdateReview(event.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2f9cec),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_editingReview != null ? 'Update Review' : 'Submit Review',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _startEditingReview(Review review) {
    setState(() {
      _editingReview = review;
      _selectedRating = review.rating;
      _reviewController.text = review.reviewText;
    });
    // Optional: scroll to review input
  }

  void _cancelEditing() {
    setState(() {
      _editingReview = null;
      _selectedRating = 0;
      _reviewController.clear();
    });
  }

  void _confirmDeleteReview(int eventId, int reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to delete your review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xff64748b))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReview(eventId, reviewId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffef4444)),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(int eventId, int reviewId) async {
    try {
      setState(() => _isSubmitting = true);
      await eventsController.deleteReview(eventId, reviewId);
      setState(() => _isSubmitting = false);
      Get.snackbar('Deleted', 'Your review has been removed.');
    } catch (e) {
      setState(() => _isSubmitting = false);
      Get.snackbar('Error', 'Failed to delete review. Please try again.');
    }
  }

  Future<void> _submitOrUpdateReview(int eventId) async {
    if (_selectedRating == 0) {
      Get.snackbar('Rating Required', 'Please select a star rating.');
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      Get.snackbar('Review Required', 'Please write a brief review.');
      return;
    }

    final user = authController.user?.value;
    final reviewerName = user != null
        ? '${user.firstName} ${user.lastName}'.trim()
        : 'Guest';

    try {
      setState(() => _isSubmitting = true);
      if (_editingReview != null) {
        await eventsController.updateReview(
            eventId, _editingReview!.id, _selectedRating, _reviewController.text.trim(), reviewerName);
        Get.snackbar('Updated', 'Your review has been updated!');
      } else {
        await eventsController.submitReview(
            eventId, _selectedRating, _reviewController.text.trim(), reviewerName);
        Get.snackbar('Success', 'Thank you for your review!');
      }
      _reviewController.clear();
      setState(() {
        _editingReview = null;
        _selectedRating = 0;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      String errorMsg = 'Failed to process review. Please try again.';
      if (e.toString().contains('already reviewed')) {
        errorMsg = 'You have already reviewed this event.';
      }
      Get.snackbar('Error', errorMsg);
    }
  }

  Widget _reviewInput(String hint,
      {required TextEditingController controller, int lines = 1}) {
    return TextField(
      controller: controller,
      maxLines: lines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xff9aa8bb), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffdbe5f0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff2f9cec), width: 1.4)),
        filled: true,
        fillColor: const Color(0xfff8fafc),
      ),
    );
  }

  Widget _buildMoreEventsSection(BuildContext context, List<LinkupEvent> others) {
    if (others.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('More events from this organizer', style: TextStyle(fontSize: _font(context, 16), fontWeight: FontWeight.w900, color: const Color(0xff0f172a))),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: others.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final e = others[index];
              return GestureDetector(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => EventDetailScreen(slug: e.slug))),
                child: Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffe5edf6)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        e.imageUrl,
                        height: 74,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 74,
                          color: const Color(0xffe2e8f0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, height: 1.1, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('${e.city}, ${e.country}', style: const TextStyle(color: Color(0xff8fa0b6), fontSize: 10)),
                          ],
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

  Widget _buildTicketCard(BuildContext context, Ticket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.name, style: TextStyle(fontSize: _font(context, 15), fontWeight: FontWeight.w900, color: const Color(0xff1e293b))),
                const SizedBox(height: 4),
                Text(ticket.description, style: TextStyle(fontSize: _font(context, 12), color: const Color(0xff64748b))),
                const SizedBox(height: 10),
                Text(
                  ticket.isFree ? 'FREE' : '\$${ticket.price}',
                  style: TextStyle(fontSize: _font(context, 18), fontWeight: FontWeight.w900, color: const Color(0xff2f9bef)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2f9bef),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _headerBadge(BuildContext context, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: _font(context, 11), fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xff0f172a))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: _font(context, 18), fontWeight: FontWeight.w900, color: const Color(0xff0f172a)),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, EventDetail event) {
    bookingController.reset();
    final detailTickets =
        eventsController.eventDetail.value?.data.tickets ?? const <Ticket>[];
    bookingController.useDetailTickets(
      detailTickets,
      salesClosed: event.ticketsNoLongerAvailable,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Booking',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Obx(() {
              if (bookingController.isLoading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }

              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xfff8fafc),
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // The success step brings its own green header.
                    if (bookingController.currentStep.value !=
                        BookingStep.success)
                      _buildBookingHeader(dialogContext, event.title),
                    Expanded(
                      child: _buildBookingStepContent(dialogContext, event),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildBookingHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: _font(context, 16), fontWeight: FontWeight.w900),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xfff1f5f9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Close',
                  style: TextStyle(
                      fontSize: _font(context, 12),
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingStepContent(BuildContext context, EventDetail event) {
    switch (bookingController.currentStep.value) {
      case BookingStep.selection:
        return _buildTicketSelectionStep(context, event);
      case BookingStep.summary:
        return _buildOrderSummaryStep(context, event);
      case BookingStep.success:
        return _buildPaymentSuccessStep(context, event);
    }
  }

  Widget _buildTicketSelectionStep(BuildContext context, EventDetail event) {
    final unavailable = event.ticketsNoLongerAvailable ||
        bookingController.salesClosed.value;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(Icons.confirmation_number_rounded, 'Tickets',
              const Color(0xff238df2), 18),
          if (unavailable) ...[
            const SizedBox(height: 10),
            const Text(
              'No longer available',
              style: TextStyle(
                color: Color(0xff94a3b8),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (bookingController.tickets.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No tickets found for this event.', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            ...bookingController.tickets.map((t) => _buildBookingTicketCard(t)),
          const SizedBox(height: 24),
          if (!unavailable && bookingController.cart.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    bookingController.currentStep.value = BookingStep.summary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2f9cec),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Review Order',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingTicketCard(Ticket ticket) {
    final qty = bookingController.getQuantity(ticket.id);
    final hasWellness = ticket.wellness != null;
    final cookout = ticket.cookout;
    final showsPlatePanel =
        cookout != null && cookout.hasAnything && !cookout.isDrinksOnly;
    final showsDrinksButton = cookout != null && cookout.isDrinksOnly;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(ticket.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      color: Color(0xff0f172a))),
                              const SizedBox(width: 8),
                              _badge('Ticket', const Color(0xff238df2)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(ticket.description,
                              style: const TextStyle(
                                  color: Color(0xff94a3b8), fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('BS\$${ticket.price}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: Color(0xff0f172a))),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _headerBadge(
                        context,
                        'Type: ${ticket.type} · Available: ${ticket.qtyAvailable}',
                        const Color(0xfff1f5f9),
                        const Color(0xff64748b),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _qtySelector(ticket),
                  ],
                ),
              ],
            ),
          ),
          // "View Package" is read-only, so it shows before anything is added.
          // Anything that changes the order waits until the ticket is in the
          // cart, otherwise the extras would be silently dropped.
          if (ticket.packageItems.isNotEmpty || (qty > 0 && showsDrinksButton))
            _buildTicketCardActions(ticket, showDrinks: qty > 0),
          if (qty > 0 &&
              showsDrinksButton &&
              bookingController.expandedDrinkPanels.contains(ticket.id))
            _buildDrinksOnlyPanel(ticket),
          if (qty > 0 && hasWellness) _buildWellnessServicesSection(ticket),
          if (qty > 0 && showsPlatePanel) _buildCookoutSection(ticket),
        ],
      ),
    );
  }

  Widget _qtySelector(Ticket ticket) {
    final cannotAdd =
        bookingController.salesClosed.value || !ticket.isPurchasable;
    final qty = bookingController.getQuantity(ticket.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (cannotAdd) ...[
          const Text(
            'No longer available',
            style: TextStyle(
              color: Color(0xff94a3b8),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xfff1f5f9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyBtn(
                '-',
                cannotAdd
                    ? null
                    : () => bookingController.updateQuantity(ticket.id, -1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '$qty',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: cannotAdd
                        ? const Color(0xff94a3b8)
                        : const Color(0xff0f172a),
                  ),
                ),
              ),
              _qtyBtn(
                '+',
                cannotAdd
                    ? null
                    : () => bookingController.updateQuantity(ticket.id, 1),
                primary: !cannotAdd,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessServicesSection(Ticket ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xfff8fafc),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeading(Icons.spa_rounded, 'Wellness Services',
                  const Color(0xff0f172a), 15),
              const Spacer(),
              _badge('Ticket: ${ticket.name}', const Color(0xff238df2).withOpacity(0.1),
                  textColor: const Color(0xff238df2)),
            ],
          ),
          const SizedBox(height: 16),
          _buildWellnessBookingDetails(ticket.wellness!.booking!),
          const SizedBox(height: 20),
          const Text('Select a time slot',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const Text('Slot is held during checkout › released if canceled.',
              style: TextStyle(color: Color(0xff94a3b8), fontSize: 11)),
          const SizedBox(height: 12),
          _buildSlotGrid(ticket),
          const SizedBox(height: 24),
          const Text('Included Services',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ...ticket.wellness!.services.map((s) => _buildIncludedService(s)),
          const SizedBox(height: 24),
          const Text('Service Location',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 12),
          _buildLocationToggle(ticket.id),
          if (bookingController.locationModes[ticket.id] == 'Mobile')
            _buildMobileAddressField(),
        ],
      ),
    );
  }

  /// "Cookout Plate Order": included plate picker, sides, and paid add-ons.
  Widget _buildCookoutSection(Ticket ticket) {
    final cookout = ticket.cookout!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xfffffbeb),
        border: Border(top: BorderSide(color: Color(0xfffde68a))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionHeading(Icons.local_fire_department_rounded,
                    cookout.title, const Color(0xff0f172a), 15),
              ),
              _badge('Ticket: ${ticket.name}',
                  const Color(0xff238df2).withOpacity(0.1),
                  textColor: const Color(0xff238df2)),
            ],
          ),
          const SizedBox(height: 4),
          Text(cookout.note,
              style: const TextStyle(
                  color: Color(0xff94a3b8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          if (cookout.plates.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('Choose Included Plate (1)',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const Text('Choose exactly one protein for your included plate.',
                style: TextStyle(
                    color: Color(0xff94a3b8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...cookout.plates.map((plate) => _buildPlateOption(ticket, plate)),
          ],
          if (cookout.includedSides.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('Included Sides (Grab \u0026 Go)',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 2),
            Text(cookout.includedSides.join(', '),
                style: const TextStyle(
                    color: Color(0xff64748b),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
          if (cookout.drinks.isNotEmpty) ...[
            const SizedBox(height: 18),
            _buildAddonGroup(ticket, 'Add-on Drinks', cookout.drinks),
          ],
          if (cookout.proteins.isNotEmpty) ...[
            const SizedBox(height: 18),
            _buildAddonGroup(ticket, 'Add-on Proteins', cookout.proteins),
          ],
        ],
      ),
    );
  }

  Widget _buildPlateOption(Ticket ticket, CookoutOption plate) {
    final selectedName = bookingController.plateNameFor(ticket);
    final isSelected = selectedName == plate.name;

    return GestureDetector(
      onTap: () => bookingController.selectPlate(ticket.id, plate.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffeff6ff) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? const Color(0xff238df2)
                  : const Color(0xffe2e8f0),
              width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 19,
                color: isSelected
                    ? const Color(0xff238df2)
                    : const Color(0xffcbd5e1)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plate.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 14)),
                  Text(plate.note,
                      style: const TextStyle(
                          color: Color(0xff94a3b8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonGroup(Ticket ticket, String title, List<CookoutAddon> addons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const Spacer(),
            _badge('Paid', const Color(0xfff59e0b).withOpacity(0.15),
                textColor: const Color(0xffb45309)),
          ],
        ),
        const SizedBox(height: 10),
        // Wrap rather than a fixed-ratio grid: cards keep the two-column look
        // but size to their own content, so long names cannot overflow.
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: addons
                  .map((addon) => SizedBox(
                      width: cardWidth, child: _buildAddonCard(ticket, addon)))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddonCard(Ticket ticket, CookoutAddon addon) {
    final quantity = bookingController.getAddonQuantity(ticket.id, addon.id);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(addon.name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _badge('Cookout', const Color(0xff8b5cf6).withOpacity(0.12),
                  textColor: const Color(0xff6d28d9)),
              _badge('Add-on', const Color(0xfff1f5f9),
                  textColor: const Color(0xff64748b)),
            ],
          ),
          const SizedBox(height: 6),
          Text('BS\$${addon.price.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 8),
          if (addon.isSoldOut)
            Row(
              children: [
                _badge('Available: 0', const Color(0xfff1f5f9),
                    textColor: const Color(0xff94a3b8)),
                const SizedBox(width: 6),
                const Text('Sold out',
                    style: TextStyle(
                        color: Color(0xffef4444),
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
              ],
            )
          else
            Row(
              children: [
                Flexible(
                  child: _badge('Available: ${addon.available}',
                      const Color(0xfff1f5f9),
                      textColor: const Color(0xff94a3b8)),
                ),
                const Spacer(),
                _qtyBtn(
                    '-',
                    () => bookingController.updateAddonQuantity(
                        ticket.id, addon, -1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('$quantity',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                ),
                _qtyBtn(
                    '+',
                    () => bookingController.updateAddonQuantity(
                        ticket.id, addon, 1),
                    primary: true),
              ],
            ),
        ],
      ),
    );
  }

  /// The "Add Drinks" / "View Package" pills under a ticket card.
  Widget _buildTicketCardActions(Ticket ticket, {bool showDrinks = true}) {
    final cookout = ticket.cookout;
    final isExpanded = bookingController.expandedDrinkPanels.contains(ticket.id);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      color: Colors.white,
      child: Row(
        children: [
          if (showDrinks && cookout != null && cookout.isDrinksOnly)
            _outlinePill(
                isExpanded ? Icons.expand_less_rounded : Icons.local_bar_rounded,
                isExpanded ? 'Hide Drinks' : 'Add Drinks',
                () => bookingController.toggleDrinkPanel(ticket.id)),
          if (ticket.packageItems.isNotEmpty)
            _outlinePill(Icons.inventory_2_rounded, 'View Package',
                () => _showPackageSheet(ticket)),
        ],
      ),
    );
  }

  Widget _outlinePill(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffe2e8f0), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xff0f172a)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrinksOnlyPanel(Ticket ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xfffffbeb),
        border: Border(top: BorderSide(color: Color(0xfffde68a))),
      ),
      child: _buildAddonGroup(ticket, 'Add-on Drinks', ticket.cookout!.drinks),
    );
  }

  void _showPackageSheet(Ticket ticket) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _sectionHeading(Icons.inventory_2_rounded,
                        ticket.name, const Color(0xff0f172a), 17),
                  ),
                  Text('BS\$${ticket.price}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 17)),
                ],
              ),
              const SizedBox(height: 4),
              const Text("What's included in this package",
                  style: TextStyle(
                      color: Color(0xff94a3b8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ...ticket.packageItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 17, color: Color(0xff10b981)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff238df2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        TextField(
          controller: bookingController.addressController,
          onChanged: (value) => bookingController.address.value = value,
          decoration: InputDecoration(
            hintText: 'Enter your address',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xffe2e8f0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xff238df2), width: 1.5)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: bookingController.isLocating.value
                ? null
                : () async {
                    await bookingController.useMyLocation();
                    _moveCameraToPin();
                  },
            icon: bookingController.isLocating.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 18),
            label: Text(
                bookingController.isLocating.value
                    ? 'Finding you…'
                    : 'Use my location · Drop pin',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xff0f172a),
              side: const BorderSide(color: Color(0xffe2e8f0), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPinMap(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, size: 14, color: Color(0xffef4444)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Pin: ${bookingController.pinLatitude.value.toStringAsFixed(4)}, '
                '${bookingController.pinLongitude.value.toStringAsFixed(4)} '
                '— your therapist will navigate here.',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff64748b)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPinMap() {
    final pin = LatLng(
        bookingController.pinLatitude.value, bookingController.pinLongitude.value);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: pin, zoom: 14),
          markers: {
            Marker(
              markerId: const MarkerId('service-pin'),
              position: pin,
              draggable: true,
              onDragEnd: (position) =>
                  bookingController.setPin(position.latitude, position.longitude),
            ),
          },
          onMapCreated: (controller) => _pinMapController = controller,
          onTap: (position) =>
              bookingController.setPin(position.latitude, position.longitude),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          // The map sits inside a scrolling sheet, so it has to claim the drag
          // itself or the sheet swallows every pan.
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          },
        ),
      ),
    );
  }

  void _moveCameraToPin() {
    _pinMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(bookingController.pinLatitude.value,
            bookingController.pinLongitude.value),
        16,
      ),
    );
  }

  Widget _buildWellnessBookingDetails(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _bookingInfo('Mode', booking.mode),
              _bookingInfo('Duration', '${booking.duration} min'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _bookingInfo('Buffer', '${booking.buffer} min'),
              _bookingInfo('Max/Slot', booking.maxPerSlot),
            ],
          ),
          const SizedBox(height: 10),
          _bookingInfo('Slots', '${booking.slotDate} ${booking.slotStart} - ${booking.slotEnd}', fullWidth: true),
          if (booking.policy.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _bookingInfo('Policy', booking.policy, fullWidth: true),
          ],
        ],
      ),
    );
  }

  Widget _bookingInfo(String label, String value, {bool fullWidth = false}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xff94a3b8), fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
      ],
    );
    if (fullWidth) return content;
    return Expanded(child: content);
  }

  Widget _buildSlotGrid(Ticket ticket) {
    final slots = ticket.wellness!.booking!.slots;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = bookingController.selectedSlots[ticket.id]?.key == slot.key;
        final isDisabled = slot.disabled == "1";

        return GestureDetector(
          onTap: isDisabled ? null : () => bookingController.selectSlot(ticket.id, slot),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xff238df2) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? const Color(0xff238df2) : const Color(0xffe2e8f0)),
            ),
            child: Text(
              '${slot.start}-${slot.end}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: isSelected ? Colors.white : (isDisabled ? const Color(0xffcbd5e1) : const Color(0xff0f172a)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncludedService(WellnessService service) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xff10b981)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(service.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    const SizedBox(width: 6),
                    _badge('Included', const Color(0xff238df2).withOpacity(0.1), textColor: const Color(0xff238df2)),
                  ],
                ),
                Text('${service.duration} min', style: const TextStyle(color: Color(0xff94a3b8), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationToggle(int ticketId) {
    final mode = bookingController.locationModes[ticketId] ?? 'In-house';
    return Row(
      children: [
        Expanded(
            child: _toggleBtn(Icons.home_rounded, 'In-house', mode == 'In-house',
                () => bookingController.setLocationMode(ticketId, 'In-house'))),
        const SizedBox(width: 10),
        Expanded(
            child: _toggleBtn(Icons.directions_car_filled_rounded,
                'Mobile (to me)', mode == 'Mobile',
                () => bookingController.setLocationMode(ticketId, 'Mobile'))),
      ],
    );
  }

  Widget _toggleBtn(
      IconData icon, String label, bool selected, VoidCallback onTap) {
    final foreground = selected ? Colors.white : const Color(0xff0f172a);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xff238df2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xff238df2) : const Color(0xffe2e8f0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: foreground)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(String label, VoidCallback? onTap, {bool primary = false}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: !enabled
              ? const Color(0xffe2e8f0)
              : primary
                  ? const Color(0xff238df2)
                  : const Color(0xfff1f5f9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: !enabled
                ? const Color(0xff94a3b8)
                : primary
                    ? Colors.white
                    : const Color(0xff0f172a),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, {Color? textColor, IconData? icon}) {
    final foreground = textColor ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: foreground, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  /// Material icons rather than emoji: bundled with the app, so they render
  /// identically on iOS and Android instead of depending on font fallback.
  Widget _sectionHeading(IconData icon, String label, Color color, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: size, color: color),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
                fontSize: size, color: color, fontWeight: FontWeight.w900)),
      ],
    );
  }

  /// An icon + label pair for small grey annotation lines.
  Widget _iconNote(IconData icon, String label,
      {Color color = const Color(0xff94a3b8), double fontSize = 11}) {
    return Row(
      children: [
        Icon(icon, size: fontSize + 2, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryStep(BuildContext context, EventDetail event) {
    final subtotal = bookingController.subtotal;
    final fees = bookingController.fees;
    final tax = bookingController.tax;
    final total = bookingController.total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(event.imageUrl,
                height: 140, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 24),
          const Text('Order Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          ...bookingController.cart.entries.map((entry) {
            final ticket =
                bookingController.tickets.firstWhere((t) => t.id == entry.key);
            final mode =
                bookingController.locationModes[ticket.id] ?? 'In-house';
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('x${entry.value} ${ticket.name}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Color(0xff0f172a))),
                        if (ticket.cookout != null) ...[
                          if (ticket.cookout!.includedSides.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xfff8fafc),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Included Sides (Grab \u0026 Go)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          color: Color(0xff64748b))),
                                  Text(
                                      ticket.cookout!.includedSides.join(', '),
                                      style: const TextStyle(
                                          color: Color(0xff94a3b8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                          if (bookingController.plateNameFor(ticket) != null) ...[
                            const SizedBox(height: 6),
                            Text(
                                'Plate: ${bookingController.plateNameFor(ticket)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xff475569))),
                          ],
                        ],
                        // Party tickets have nothing to qualify; only wellness
                        // lines carry a slot and a service location.
                        if (ticket.wellness != null) ...[
                          const SizedBox(height: 3),
                          if (_summarySlotLine(ticket) != null)
                            Text(_summarySlotLine(ticket)!,
                                style: const TextStyle(
                                    color: Color(0xff94a3b8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          _iconNote(
                              mode == 'In-house'
                                  ? Icons.home_rounded
                                  : Icons.directions_car_filled_rounded,
                              mode == 'In-house'
                                  ? 'In-house at spa'
                                  : 'Mobile · pin '
                                      '${bookingController.pinLatitude.value.toStringAsFixed(3)},'
                                      '${bookingController.pinLongitude.value.toStringAsFixed(3)}'),
                        ],
                      ],
                    ),
                  ),
                  Text(
                      'BS\$${((double.tryParse(ticket.price) ?? 0) * entry.value).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xff10b981))),
                ],
              ),
            );
          }),
          ...bookingController.addonLines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          'x${line.quantity} ${line.addon.name} (${line.group})',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Color(0xff0f172a))),
                    ),
                    Text('BS\$${line.lineTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xff10b981))),
                  ],
                ),
              )),
          const Divider(height: 40, color: Color(0xfff1f5f9)),
          _summaryRow('Services Subtotal', 'BS\$${subtotal.toStringAsFixed(2)}'),
          _summaryRow(
              'Service & Processing Fee', 'BS\$${fees.toStringAsFixed(2)}'),
          _summaryRow('Tax', 'BS\$${tax.toStringAsFixed(2)}'),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Total',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text('BS\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff10b981))),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => bookingController.reset(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff64748b),
                side: const BorderSide(color: Color(0xffe2e8f0), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Clear Cart',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => bookingController.payWithWallet(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff10b981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Pay with Wallet',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => bookingController.buyWithStripe(event.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff238df2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Pay with Card',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => bookingController.payWithScotiabank(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffef4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Pay with Scotiabank',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSuccessStep(BuildContext context, EventDetail event) {
    final ticketCount = bookingController.ticketCount;

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xff12b76a),
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 38),
                ),
                const SizedBox(height: 14),
                const Text('Payment Successful',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                    'Paid BS\$${bookingController.total.toStringAsFixed(2)} '
                    'with ${bookingController.paymentMethod.value} · '
                    '$ticketCount QR ticket${ticketCount == 1 ? '' : 's'} issued',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xffecfdf5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffa7f3d0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.confirmation_number_outlined,
                          size: 15, color: Color(0xff047857)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Saved to your wallet — view anytime in Profile › Tickets \u0026 Events',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff047857)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildSuccessTicketCard(context, event),
                const SizedBox(height: 16),
                if (bookingController.hasMobileService) ...[
                  _successActionBtn('Track my therapist',
                      Icons.navigation_rounded, const Color(0xff12b76a),
                      filled: true,
                      onTap: () => _showLiveTrackingSheet(context, event)),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                        child: _successActionBtn(
                            'My Tickets', Icons.confirmation_number_outlined,
                            const Color(0xff0f172a),
                            onTap: () => Get.back())),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _successActionBtn(
                            'Done', Icons.check_rounded, const Color(0xff12b76a),
                            filled: true,
                            onTap: () => Get.back())),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Slot: 11:30–12:30 · Sports Massage (Included)" under a wellness line.
  String? _summarySlotLine(Ticket ticket) {
    final slot = bookingController.selectedSlots[ticket.id];
    if (slot == null) return null;
    final parts = <String>['Slot: ${slot.start}–${slot.end}'];
    for (final service in ticket.wellness?.services ?? <WellnessService>[]) {
      parts.add('${service.name} (Included)');
    }
    return parts.join(' · ');
  }

  /// "Massage Service · 11:30–12:30 x 2" for every line in the cart.
  String _successTicketSubtitle() {
    final lines = <String>[];
    bookingController.cart.forEach((ticketId, quantity) {
      final matches =
          bookingController.tickets.where((t) => t.id == ticketId);
      if (matches.isEmpty) return;
      final ticket = matches.first;
      final slot = bookingController.selectedSlots[ticketId];
      final parts = <String>[ticket.name];
      if (slot != null) parts.add('${slot.start}–${slot.end}');
      if (quantity > 1) parts.add('x $quantity');
      lines.add(parts.join(' · '));
    });
    return lines.join('  |  ');
  }

  String _formatEventDateRange(EventDetail event) {
    return _eventDateLabel(event);
  }

  String _eventDateLabel(EventDetail event) {
    final details = event.eventDetails;
    final start = _parseEventDate(event.startTime) ??
        _parseEventDate(details.singleEventDate) ??
        _parseEventDate(details.singleStartTime) ??
        _parseEventDate(details.recurrStartDate);
    final end = _parseEventDate(event.endTime) ??
        _parseEventDate(details.singleEndTime) ??
        _parseEventDate(details.recurrEndDate);
    final formatter = DateFormat('dd MMM yyyy');
    final pattern = (details.recurrPattern ?? '').trim();
    final isRecurring = details.eventType.toLowerCase() == 'recurring';

    if (isRecurring && (start != null || end != null)) {
      final range = [
        if (start != null) formatter.format(start),
        if (end != null &&
            (start == null || formatter.format(start) != formatter.format(end)))
          formatter.format(end),
      ].join(' – ');
      if (pattern.isNotEmpty && range.isNotEmpty) {
        return '${pattern[0].toUpperCase()}${pattern.substring(1)} · $range';
      }
      if (range.isNotEmpty) return range;
    }
    if (start == null && end == null) return 'Date TBD';
    if (start == null) return formatter.format(end!);
    if (end == null || formatter.format(start) == formatter.format(end)) {
      return formatter.format(start);
    }
    return '${formatter.format(start)} – ${formatter.format(end)}';
  }

  String _stripHtml(String html) {
    if (html.trim().isEmpty) return '';
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime? _parseEventDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  Widget _buildSuccessTicketCard(BuildContext context, EventDetail event) {
    final ticketCode = bookingController.issuedTicketCode.value.isEmpty
        ? 'TKT-PENDING'
        : bookingController.issuedTicketCode.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffe2e8f0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_rounded,
                  color: Color(0xffff7d95), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(event.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xff0f172a))),
              ),
              _badge(event.categoryName, const Color(0xff238df2).withOpacity(0.1),
                  textColor: const Color(0xff238df2)),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _successTicketSubtitle(),
              style: const TextStyle(
                  color: Color(0xff94a3b8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 104,
                height: 104,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xffe2e8f0)),
                ),
                child: PrettyQrView.data(data: ticketCode),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ticketMetaRow(Icons.confirmation_number_outlined, ticketCode),
                    const SizedBox(height: 8),
                    _ticketMetaRow(Icons.location_on_rounded,
                        '${event.country}, ${event.state}, ${event.city}'),
                    const SizedBox(height: 8),
                    _ticketMetaRow(
                        Icons.calendar_month_rounded, _formatEventDateRange(event)),
                    const SizedBox(height: 10),
                    _badge('Scan at entry',
                        const Color(0xff10b981).withOpacity(0.1),
                        textColor: const Color(0xff10b981),
                        icon: Icons.check_circle_rounded),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _successActionBtn(
              'Send via Chat', Icons.send_rounded, const Color(0xff238df2),
              filled: true,
              onTap: () => _showSendTicketSheet(context, event)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _successActionBtn(
                      'Apple Wallet', Icons.apple, Colors.black,
                      filled: true,
                      onTap: () => Get.snackbar('Wallet', 'Adding ticket to Apple Wallet...', snackPosition: SnackPosition.BOTTOM))),
              const SizedBox(width: 10),
              Expanded(
                  child: _successActionBtn(
                      'Google Wallet', Icons.wallet_rounded,
                      const Color(0xff0f172a),
                      onTap: () => Get.snackbar('Wallet', 'Adding ticket to Google Wallet...', snackPosition: SnackPosition.BOTTOM))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ticketMetaRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xff64748b)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff475569))),
        ),
      ],
    );
  }

  void _showLiveTrackingSheet(BuildContext context, EventDetail event) {
    final providerName = (event.organizerName ?? '').trim().isEmpty
        ? 'Your therapist'
        : event.organizerName!.trim();
    final destination = bookingController.address.value.trim().isEmpty
        ? 'Your location'
        : bookingController.address.value.trim();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Live tracking',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (sheetContext, _, __) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTrackingMap(sheetContext, event),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          children: [
                            _buildTrackingProviderRow(providerName, event),
                            const SizedBox(height: 14),
                            _buildTrackingRoute(event, destination),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.sensors_rounded,
                                    size: 15, color: Color(0xff12b76a)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Live tracking · $providerName can see your '
                                    'location and is on the way',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xff475569)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff12b76a),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Done',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16)),
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
          ),
        );
      },
    );
  }

  Widget _buildTrackingMap(BuildContext sheetContext, EventDetail event) {
    final destination = LatLng(bookingController.pinLatitude.value,
        bookingController.pinLongitude.value);
    final origin = LatLng(
      event.latitude ?? destination.latitude + 0.012,
      event.longitude ?? destination.longitude - 0.014,
    );

    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                (origin.latitude + destination.latitude) / 2,
                (origin.longitude + destination.longitude) / 2,
              ),
              zoom: 12.4,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('provider-origin'),
                position: origin,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
                infoWindow: const InfoWindow(title: 'Therapist start'),
              ),
              Marker(
                markerId: const MarkerId('buyer-destination'),
                position: destination,
                infoWindow: const InfoWindow(title: 'Your location'),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: [origin, destination],
                color: const Color(0xff2f9cec),
                width: 5,
              ),
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer()),
            },
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xff12b76a),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.directions_walk_rounded,
                      size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text('7 min away',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(sheetContext),
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: Color(0xff0f172a)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingProviderRow(String providerName, EventDetail event) {
    final initials = providerName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xffe0f2fe),
          backgroundImage: (event.organizerImageUrl ?? '').isNotEmpty
              ? NetworkImage(event.organizerImageUrl!)
              : null,
          child: (event.organizerImageUrl ?? '').isNotEmpty
              ? null
              : Text(initials.isEmpty ? 'LU' : initials,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: Color(0xff0369a1))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.star_rounded,
                      size: 15, color: Color(0xfffbbf24)),
                  const SizedBox(width: 2),
                  Text(
                      event.averageRating > 0
                          ? event.averageRating.toStringAsFixed(1)
                          : '4.9',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
              Text(event.categoryName.isEmpty
                  ? 'Licensed Massage Therapist'
                  : event.categoryName,
                  style: const TextStyle(
                      color: Color(0xff94a3b8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        _trackingCircleAction(Icons.call_rounded, const Color(0xffecfdf5),
            const Color(0xff12b76a)),
        const SizedBox(width: 8),
        _trackingCircleAction(Icons.chat_bubble_outline_rounded,
            const Color(0xffe0f2fe), const Color(0xff2f9cec)),
      ],
    );
  }

  Widget _trackingCircleAction(IconData icon, Color background, Color tint) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: tint),
    );
  }

  Widget _buildTrackingRoute(EventDetail event, String destination) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        children: [
          _trackingRouteRow(
              const Color(0xff12b76a), event.title, 'Therapist start'),
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 4, bottom: 4),
            child: Row(
              children: const [
                SizedBox(
                  width: 2,
                  height: 16,
                  child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xffcbd5e1))),
                ),
              ],
            ),
          ),
          _trackingRouteRow(
              const Color(0xffef4444), destination, 'Your location'),
        ],
      ),
    );
  }

  Widget _trackingRouteRow(Color dotColor, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 13)),
              Text(subtitle,
                  style: const TextStyle(
                      color: Color(0xff94a3b8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _successActionBtn(String label, IconData icon, Color color,
      {bool filled = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          border: filled ? null : Border.all(color: const Color(0xffe2e8f0), width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: filled ? Colors.white : color),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: filled ? Colors.white : const Color(0xff0f172a))),
          ],
        ),
      ),
    );
  }

  void _showSendTicketSheet(BuildContext context, EventDetail event) {
    final chatController = Get.find<ChatController>(tag: ChatController().toString());
    chatController.getMatchList();

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Send Ticket',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xff0f172a))),
                        const SizedBox(height: 2),
                        Text('${event.title} · ${bookingController.issuedTicketCode.value}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff64748b))),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xfff1f5f9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 20, color: Color(0xff64748b)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xfff1f5f9)),
            Expanded(
              child: GetBuilder<ChatController>(
                tag: ChatController().toString(),
                builder: (controller) {
                  final list = controller.matchList;
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('No connections found to send tickets to.',
                          style: TextStyle(color: Color(0xff64748b))),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 80, color: Color(0xfff8fafc)),
                    itemBuilder: (context, index) {
                      final user = list[index];
                      if (user is! Map) return const SizedBox.shrink();

                      final firstName = user['first_name']?.toString() ?? "";
                      final lastName = user['last_name']?.toString() ?? "";
                      final avatar = user['avatar']?.toString();
                      final hasAvatar = avatar != null && avatar.isNotEmpty;

                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xfff1f5f9),
                          backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
                          child: !hasAvatar
                              ? const Icon(Icons.person, color: Color(0xffcbd5e1))
                              : null,
                        ),
                        title: Text(
                          '$firstName $lastName'.trim().isEmpty ? "User" : '$firstName $lastName',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xff0f172a)),
                        ),
                        trailing: const Icon(Icons.send_rounded,
                            size: 18, color: Color(0xff238df2)),
                        onTap: () {
                          Get.back();
                          bookingController.sendTicketToUser(user as Map<String, dynamic>, event);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
