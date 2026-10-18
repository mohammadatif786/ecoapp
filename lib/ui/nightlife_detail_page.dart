import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/get_controller/nightlife_controller.dart';
import 'package:link_up/model/nightlife_model.dart';
import 'package:url_launcher/url_launcher.dart';

class NightlifeDetailPage extends StatefulWidget {
  const NightlifeDetailPage({
    super.key,
    required this.kind,
    required this.placeId,
    this.preview,
  });

  final String kind;
  final String placeId;
  final NightlifePlace? preview;

  @override
  State<NightlifeDetailPage> createState() => _NightlifeDetailPageState();
}

class _NightlifeDetailPageState extends State<NightlifeDetailPage> {
  late final NightlifeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<NightlifeController>();
    _controller.detail.value = null;
    _controller.detailError.value = null;
    _controller.fetchDetail(kind: widget.kind, placeId: widget.placeId);
  }

  double _ui(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.08).toDouble();
  }

  double _font(BuildContext context, double value) => _ui(context, value);

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(NightlifePlaceDetail? detail) async {
    if (detail?.mapsUrl.isNotEmpty == true) {
      await _openUrl(detail!.mapsUrl);
      return;
    }
    if (detail?.latitude != null && detail?.longitude != null) {
      await _openUrl(
        'https://www.google.com/maps/search/?api=1&query=${detail!.latitude},${detail.longitude}',
      );
      return;
    }
    final address = detail?.address ?? widget.preview?.address ?? '';
    if (address.isEmpty) return;
    await _openUrl(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeaf4fe),
      body: SafeArea(
        child: Obx(() {
          final detail = _controller.detail.value;
          final loading = _controller.isDetailLoading.value && detail == null;
          final error = _controller.detailError.value;
          return Column(
            children: [
              _header(context, detail?.name ?? widget.preview?.name ?? 'Details'),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null && detail == null && widget.preview == null
                        ? _errorState(context)
                        : RefreshIndicator(
                            onRefresh: () => _controller.fetchDetail(
                              kind: widget.kind,
                              placeId: widget.placeId,
                            ),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                _ui(context, 14),
                                _ui(context, 14),
                                _ui(context, 14),
                                _ui(context, 24),
                              ),
                              children: [
                                if (error != null && detail == null)
                                  _errorBanner(context, error),
                                _hero(context, detail),
                                SizedBox(height: _ui(context, 14)),
                                _infoCard(context, detail),
                                SizedBox(height: _ui(context, 12)),
                                _actions(context, detail),
                                if ((detail?.openingHours ?? const []).isNotEmpty) ...[
                                  SizedBox(height: _ui(context, 12)),
                                  _hoursCard(context, detail!),
                                ],
                                if ((detail?.photos.length ?? 0) > 1) ...[
                                  SizedBox(height: _ui(context, 12)),
                                  _photos(context, detail!),
                                ],
                                if ((detail?.reviews ?? const []).isNotEmpty) ...[
                                  SizedBox(height: _ui(context, 12)),
                                  _reviews(context, detail!),
                                ],
                              ],
                            ),
                          ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _header(BuildContext context, String title) {
    return Container(
      height: _ui(context, 54),
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
            onTap: () => Navigator.of(context).maybePop(),
            child: Icon(Icons.arrow_back, color: Colors.white, size: _ui(context, 22)),
          ),
          SizedBox(width: _ui(context, 10)),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: _font(context, 17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, NightlifePlaceDetail? detail) {
    final image = (detail?.imageUrl.isNotEmpty == true)
        ? detail!.imageUrl
        : (widget.preview?.imageUrl ?? '');
    return ClipRRect(
      borderRadius: BorderRadius.circular(_ui(context, 20)),
      child: SizedBox(
        height: _ui(context, 210),
        width: double.infinity,
        child: image.isEmpty
            ? _fallback()
            : Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff7c3aed), Color(0xffff2f92)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.nightlife, color: Colors.white, size: 48),
    );
  }

  Widget _infoCard(BuildContext context, NightlifePlaceDetail? detail) {
    final name = detail?.name.isNotEmpty == true
        ? detail!.name
        : (widget.preview?.name ?? 'Untitled place');
    final address = detail?.address.isNotEmpty == true
        ? detail!.address
        : (widget.preview?.address ?? '');
    final rating = detail?.ratingLabel.isNotEmpty == true
        ? detail!.ratingLabel
        : (widget.preview?.ratingLabel ?? '');
    return Container(
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: const Color(0xff0f172a),
              fontSize: _font(context, 22),
              fontWeight: FontWeight.w900,
            ),
          ),
          if (rating.isNotEmpty) ...[
            SizedBox(height: _ui(context, 8)),
            Row(
              children: [
                Icon(Icons.star, color: const Color(0xfff59e0b), size: _ui(context, 18)),
                SizedBox(width: _ui(context, 4)),
                Text(
                  rating,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: _font(context, 16),
                    color: const Color(0xff0f172a),
                  ),
                ),
                if ((detail?.userRatingsTotal ?? 0) > 0) ...[
                  SizedBox(width: _ui(context, 6)),
                  Text(
                    '(${detail!.userRatingsTotal})',
                    style: TextStyle(
                      color: const Color(0xff64748b),
                      fontWeight: FontWeight.w700,
                      fontSize: _font(context, 13),
                    ),
                  ),
                ],
                if (detail?.openNow != null) ...[
                  SizedBox(width: _ui(context, 10)),
                  Text(
                    detail!.openNow! ? 'Open now' : 'Closed',
                    style: TextStyle(
                      color: detail.openNow! ? const Color(0xff16a34a) : const Color(0xffdc2626),
                      fontWeight: FontWeight.w800,
                      fontSize: _font(context, 13),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (address.isNotEmpty) ...[
            SizedBox(height: _ui(context, 8)),
            Text(
              address,
              style: TextStyle(
                color: const Color(0xff64748b),
                fontWeight: FontWeight.w600,
                fontSize: _font(context, 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, NightlifePlaceDetail? detail) {
    final phone = detail?.phone ?? '';
    final website = detail?.website ?? '';
    return Row(
      children: [
        if (phone.isNotEmpty)
          Expanded(child: _actionButton(context, Icons.call, 'Call', () => _call(phone))),
        if (phone.isNotEmpty) SizedBox(width: _ui(context, 8)),
        if (website.isNotEmpty)
          Expanded(child: _actionButton(context, Icons.language, 'Website', () => _openUrl(website))),
        if (website.isNotEmpty) SizedBox(width: _ui(context, 8)),
        Expanded(child: _actionButton(context, Icons.map_outlined, 'Map', () => _openMaps(detail))),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _ui(context, 46),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xff7c3aed), size: _ui(context, 18)),
            SizedBox(width: _ui(context, 6)),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xff0f172a),
                fontWeight: FontWeight.w900,
                fontSize: _font(context, 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hoursCard(BuildContext context, NightlifePlaceDetail detail) {
    return _section(
      context,
      title: 'Hours',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: detail.openingHours
            .map(
              (line) => Padding(
                padding: EdgeInsets.only(bottom: _ui(context, 6)),
                child: Text(
                  line,
                  style: TextStyle(
                    color: const Color(0xff334155),
                    fontWeight: FontWeight.w600,
                    fontSize: _font(context, 13),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _photos(BuildContext context, NightlifePlaceDetail detail) {
    return _section(
      context,
      title: 'Photos',
      child: SizedBox(
        height: _ui(context, 92),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: detail.photos.length,
          separatorBuilder: (_, __) => SizedBox(width: _ui(context, 8)),
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(_ui(context, 12)),
              child: Image.network(
                detail.photos[index],
                width: _ui(context, 92),
                height: _ui(context, 92),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: _ui(context, 92),
                  color: const Color(0xffe2e8f0),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _reviews(BuildContext context, NightlifePlaceDetail detail) {
    return _section(
      context,
      title: 'Reviews',
      child: Column(
        children: detail.reviews.take(8).map((review) {
          return Padding(
            padding: EdgeInsets.only(bottom: _ui(context, 12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: _ui(context, 16),
                  backgroundImage: review.avatarUrl.startsWith('http')
                      ? NetworkImage(review.avatarUrl)
                      : null,
                  child: review.avatarUrl.startsWith('http')
                      ? null
                      : Text(
                          review.author.isNotEmpty ? review.author[0].toUpperCase() : 'U',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
                SizedBox(width: _ui(context, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review.author.isEmpty ? 'Guest' : review.author,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: _font(context, 13),
                              ),
                            ),
                          ),
                          if (review.rating != null)
                            Text(
                              review.rating!.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: _font(context, 12),
                                color: const Color(0xfff59e0b),
                              ),
                            ),
                        ],
                      ),
                      if (review.time.isNotEmpty)
                        Text(
                          review.time,
                          style: TextStyle(
                            color: const Color(0xff94a3b8),
                            fontSize: _font(context, 11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (review.text.isNotEmpty) ...[
                        SizedBox(height: _ui(context, 4)),
                        Text(
                          review.text,
                          style: TextStyle(
                            color: const Color(0xff475569),
                            fontSize: _font(context, 13),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _section(BuildContext context, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_ui(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ui(context, 18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color(0xff0f172a),
              fontSize: _font(context, 16),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: _ui(context, 10)),
          child,
        ],
      ),
    );
  }

  Widget _errorBanner(BuildContext context, String error) {
    return Container(
      margin: EdgeInsets.only(bottom: _ui(context, 12)),
      padding: EdgeInsets.all(_ui(context, 12)),
      decoration: BoxDecoration(
        color: const Color(0xffffe4e6),
        borderRadius: BorderRadius.circular(_ui(context, 14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error,
            style: TextStyle(
              color: const Color(0xff9f1239),
              fontWeight: FontWeight.w700,
              fontSize: _font(context, 12),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _controller.fetchDetail(
                kind: widget.kind,
                placeId: widget.placeId,
              ),
              child: const Text('Try again'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_ui(context, 24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Could not load details',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: _font(context, 18),
                color: const Color(0xff0f172a),
              ),
            ),
            SizedBox(height: _ui(context, 8)),
            Text(
              _controller.detailError.value ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xff64748b),
                fontWeight: FontWeight.w600,
                fontSize: _font(context, 13),
              ),
            ),
            SizedBox(height: _ui(context, 10)),
            TextButton(
              onPressed: () => _controller.fetchDetail(
                kind: widget.kind,
                placeId: widget.placeId,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
