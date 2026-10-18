import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:link_up/widgets/linkup_location_sheet.dart';

class BroadcastSettingsResult {
  final String title;
  final String category;
  final String location;
  final bool isPublic;
  final String? coverPath;
  final String baseResolution;
  final String outputResolution;
  final String downscaleFilter;

  const BroadcastSettingsResult({
    required this.title,
    required this.category,
    required this.location,
    required this.isPublic,
    required this.coverPath,
    required this.baseResolution,
    required this.outputResolution,
    required this.downscaleFilter,
  });
}

Future<BroadcastSettingsResult?> showBroadcastSettingsSheet(
  BuildContext context, {
  List<String> categories = const [],
}) {
  return showModalBottomSheet<BroadcastSettingsResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BroadcastSettingsSheet(categories: categories),
  );
}

class BroadcastSettingsSheet extends StatefulWidget {
  final List<String> categories;

  const BroadcastSettingsSheet({Key? key, this.categories = const []}) : super(key: key);

  @override
  State<BroadcastSettingsSheet> createState() => _BroadcastSettingsSheetState();
}

class _BroadcastSettingsSheetState extends State<BroadcastSettingsSheet> {
  static const _bg = Color(0xff0c3558);
  static const _field = Color(0xff082844);
  static const _hint = Color(0xff7d93aa);
  static const _yellow = Color(0xffffdf45);
  static const _fallbacks = [
    'Adult / Mature',
    'Music',
    'Party/Fete',
    'Talk',
    'Sports',
    'Comedy',
    'News',
    'Gaming',
  ];
  static const _resolutions = ['1920x1080', '1280x720', '854x480', '640x360'];
  static const _filters = [
    'Bilinear (Fastest)',
    'Bicubic (Sharpened scaling, 16 samples)',
    'Lanczos (Sharpened scaling, 32 samples)',
    'Area (Weighted four-sample)',
  ];

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _picker = ImagePicker();

  late List<String> _categories;
  late String _category;
  bool _isPublic = true;
  String? _coverPath;
  String _baseResolution = '1920x1080';
  String _outputResolution = '1280x720';
  String _downscaleFilter = 'Bicubic (Sharpened scaling, 16 samples)';
  bool _goingLive = false;

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
    final seen = <String>{};
    _categories = [];
    for (final item in [...widget.categories, ..._fallbacks]) {
      final label = item.trim();
      if (label.isEmpty || label.toLowerCase() == 'all') continue;
      if (seen.add(label)) _categories.add(label);
    }
    if (_categories.isEmpty) _categories = List<String>.from(_fallbacks);
    _category = _categories.contains('Adult / Mature') ? 'Adult / Mature' : _categories.first;
    _locationController.text = _compactLocation(LinkupLocationService.selected.value);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _compactLocation(LinkupLocation loc) {
    const countryCodes = {
      'Anguilla': 'AI',
      'Antigua & Barbuda': 'AG',
      'Aruba': 'AW',
      'Bahamas': 'BS',
      'Barbados': 'BB',
      'Bonaire': 'BQ',
      'British Virgin Islands': 'VG',
      'Cayman Islands': 'KY',
      'Cuba': 'CU',
      'Dominica': 'DM',
      'Dominican Republic': 'DO',
      'Grenada': 'GD',
      'Jamaica': 'JM',
      'Puerto Rico': 'PR',
      'Saint Lucia': 'LC',
      'Trinidad & Tobago': 'TT',
      'United States': 'US',
    };
    const regionCodes = {
      'New Providence': 'NP',
      'Grand Bahama': 'GB',
      'Florida': 'FL',
      'Saint John': 'SJ',
      'Saint Michael': 'SM',
      'La Habana': 'LH',
      'Distrito Nacional': 'DN',
      'Saint James': 'JM',
      'Grand Cayman': 'GC',
    };
    final region = regionCodes[loc.region] ?? loc.region;
    final country = countryCodes[loc.country] ?? loc.country;
    return '${loc.city}, $region, $country';
  }

  Future<void> _pickCover() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1920);
      if (picked == null || !mounted) return;
      setState(() => _coverPath = picked.path);
    } catch (_) {}
  }

  void _goLive() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a heading before going live.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_goingLive) return;
    setState(() => _goingLive = true);
    Navigator.of(context).pop(
      BroadcastSettingsResult(
        title: title,
        category: _category,
        location: _locationController.text.trim(),
        isPublic: _isPublic,
        coverPath: _coverPath,
        baseResolution: _baseResolution,
        outputResolution: _outputResolution,
        downscaleFilter: _downscaleFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 22))),
          child: Material(
            color: _bg,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(_ui(context, 18), _ui(context, 16), _ui(context, 8), _ui(context, 8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Broadcast Settings',
                            style: TextStyle(color: Colors.white, fontSize: _font(context, 22), fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Colors.white, size: _ui(context, 22)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(_ui(context, 18), _ui(context, 4), _ui(context, 18), _ui(context, 12)),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _label(context, 'Heading (Title)'),
                        _textField(context, controller: _titleController, hint: 'e.g. Carnival Warmup! 🎉'),
                        SizedBox(height: _ui(context, 14)),
                        _label(context, 'Category'),
                        _dropdown(context, value: _category, items: _categories, onChanged: (v) => setState(() => _category = v)),
                        SizedBox(height: _ui(context, 14)),
                        _label(context, 'Location'),
                        _textField(context, controller: _locationController, hint: 'City, region, country'),
                        SizedBox(height: _ui(context, 14)),
                        _label(context, 'Visibility'),
                        _visibilityToggle(context),
                        SizedBox(height: _ui(context, 14)),
                        _label(context, 'Cover Image'),
                        _coverPicker(context),
                        SizedBox(height: _ui(context, 22)),
                        Text(
                          'Video Settings',
                          style: TextStyle(color: _yellow, fontSize: _font(context, 16), fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: _ui(context, 14)),
                        _label(context, 'Base (Canvas) Resolution'),
                        _dropdown(context, value: _baseResolution, items: _resolutions, onChanged: (v) => setState(() => _baseResolution = v)),
                        SizedBox(height: _ui(context, 14)),
                        _label(context, 'Output (Scaled) Resolution'),
                        _dropdown(context, value: _outputResolution, items: _resolutions, onChanged: (v) => setState(() => _outputResolution = v)),
                        SizedBox(height: _ui(context, 14)),
                        _label(context, 'Downscale Filter'),
                        _dropdown(context, value: _downscaleFilter, items: _filters, onChanged: (v) => setState(() => _downscaleFilter = v)),
                        SizedBox(height: _ui(context, 8)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(_ui(context, 18), _ui(context, 8), _ui(context, 18), _ui(context, 14)),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _goLive,
                      child: Container(
                        height: _ui(context, 52),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xffff3f4f), Color(0xffe83fa4)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(_ui(context, 15)),
                          boxShadow: [BoxShadow(color: const Color(0xffec4899).withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: _ui(context, 9), height: _ui(context, 9), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                            SizedBox(width: _ui(context, 8)),
                            Text(
                              _goingLive ? 'Starting…' : 'Go Live',
                              style: TextStyle(color: Colors.white, fontSize: _font(context, 16), fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: _ui(context, 7)),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: _font(context, 13), fontWeight: FontWeight.w800)),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _hint, fontSize: _font(context, 14), fontWeight: FontWeight.w600),
      filled: true,
      fillColor: _field,
      contentPadding: EdgeInsets.symmetric(horizontal: _ui(context, 14), vertical: _ui(context, 14)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 10)), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 10)), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_ui(context, 10)), borderSide: BorderSide.none),
    );
  }

  Widget _textField(BuildContext context, {required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w700),
      cursorColor: Colors.white,
      decoration: _fieldDecoration(context, hint: hint),
    );
  }

  Widget _dropdown(BuildContext context, {required String value, required List<String> items, required ValueChanged<String> onChanged}) {
    final selected = items.contains(value) ? value : items.first;
    return GestureDetector(
      onTap: () async {
        final next = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: _field,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(_ui(context, 16)))),
          builder: (sheetContext) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: items
                    .map((item) => ListTile(
                          title: Text(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          trailing: item == selected ? const Icon(Icons.check, color: _yellow) : null,
                          onTap: () => Navigator.of(sheetContext).pop(item),
                        ))
                    .toList(),
              ),
            );
          },
        );
        if (next != null) onChanged(next);
      },
      child: Container(
        height: _ui(context, 50),
        padding: EdgeInsets.symmetric(horizontal: _ui(context, 14)),
        decoration: BoxDecoration(color: _field, borderRadius: BorderRadius.circular(_ui(context, 10))),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: _font(context, 14), fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: _ui(context, 22)),
          ],
        ),
      ),
    );
  }

  Widget _visibilityToggle(BuildContext context) {
    return Container(
      height: _ui(context, 46),
      padding: EdgeInsets.all(_ui(context, 4)),
      decoration: BoxDecoration(color: _field, borderRadius: BorderRadius.circular(_ui(context, 10))),
      child: Row(
        children: [
          Expanded(child: _visibilityChip(context, 'Public', _isPublic, () => setState(() => _isPublic = true))),
          Expanded(child: _visibilityChip(context, 'Private', !_isPublic, () => setState(() => _isPublic = false))),
        ],
      ),
    );
  }

  Widget _visibilityChip(BuildContext context, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(_ui(context, 8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xff0c3558) : Colors.white,
            fontSize: _font(context, 13),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _coverPicker(BuildContext context) {
    final height = _ui(context, 118);
    return GestureDetector(
      onTap: _pickCover,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _coverPath == null ? const _DashedRRectPainter(color: Color(0xff6b8299)) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_ui(context, 10)),
            child: _coverPath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_outlined, color: const Color(0xff8aa3bb), size: _ui(context, 26)),
                      SizedBox(height: _ui(context, 8)),
                      Text('Click to upload', style: TextStyle(color: const Color(0xff8aa3bb), fontSize: _font(context, 13), fontWeight: FontWeight.w700)),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(_coverPath!), fit: BoxFit.cover),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          color: Colors.black.withValues(alpha: 0.45),
                          padding: EdgeInsets.symmetric(vertical: _ui(context, 6)),
                          child: Text('Change cover', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: _font(context, 12), fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;

  const _DashedRRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 7.0;
      const gap = 5.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) => oldDelegate.color != color;
}
