import 'package:flutter/material.dart';

class VibesReferenceIntro extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;

  const VibesReferenceIntro({
    Key? key,
    this.title = 'Linkup Vibes!',
    this.description =
        'The only App that brings Caribbean & Latin\nAmericans together from all over the World.',
    this.onNext,
    this.onSkip,
  }) : super(key: key);

  double _s(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.06).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topHeight = size.height * 0.71;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topHeight,
            child: Image.asset(
              'assets/Layer 31.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + _s(context, 12),
            left: _s(context, 12),
            child: const _BrazilFlag(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + _s(context, 10),
            right: _s(context, 12),
            child: Image.asset(
              'assets/Vector Smart Object 2.png',
              width: _s(context, 100),
              height: _s(context, 38),
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: _s(context, 24),
            top: topHeight - _s(context, 58),
            child: GestureDetector(
              onTap: onSkip ?? () => Navigator.maybePop(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _s(context, 13),
                  vertical: _s(context, 8),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff20283b).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(_s(context, 18)),
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    fontSize: _s(context, 13),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: topHeight - _s(context, 10),
            child: Container(
              height: _s(context, 5),
              color: const Color(0xff35c2df),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height - topHeight + _s(context, 14),
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                _s(context, 24),
                _s(context, 44),
                _s(context, 24),
                _s(context, 24),
              ),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xff3198df),
                      fontFamily: 'OpenSans',
                      fontSize: _s(context, 25),
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: _s(context, 22)),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xff66748a),
                      fontFamily: 'OpenSans',
                      fontSize: _s(context, 16),
                      fontWeight: FontWeight.w500,
                      height: 1.7,
                    ),
                  ),
                  SizedBox(height: _s(context, 24)),
                  const _IntroDots(),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: _s(context, 56),
                    child: ElevatedButton(
                      onPressed: onNext ?? () {},
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xff3198df),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_s(context, 15)),
                        ),
                      ),
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontFamily: 'OpenSans',
                          fontSize: _s(context, 18),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showNewVibeComposer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const NewVibeComposerSheet(),
  );
}

class NewVibeComposerSheet extends StatelessWidget {
  const NewVibeComposerSheet({Key? key}) : super(key: key);

  double _s(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 430).clamp(0.86, 1.06).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(top: _s(context, 70), bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_s(context, 22)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              _s(context, 16),
              _s(context, 22),
              _s(context, 16),
              _s(context, 18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'New Vibe',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'OpenSans',
                        fontSize: _s(context, 20),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: _s(context, 26)),
                      color: Colors.black,
                    ),
                  ],
                ),
                Divider(height: _s(context, 24), color: const Color(0xffedf1f6)),
                Text(
                  'POST AS',
                  style: TextStyle(
                    color: const Color(0xff91a0b7),
                    fontFamily: 'OpenSans',
                    fontSize: _s(context, 12),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: _s(context, 10)),
                Row(
                  children: [
                    Expanded(
                      child: _SegmentButton(
                        label: '👤  Myself',
                        selected: true,
                        height: _s(context, 44),
                      ),
                    ),
                    SizedBox(width: _s(context, 8)),
                    Expanded(
                      child: _SegmentButton(
                        label: '🏢  Organization / Group',
                        selected: false,
                        height: _s(context, 44),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _s(context, 14)),
                Row(
                  children: [
                    Expanded(
                      child: _MediaAction(
                        icon: Icons.photo_camera_outlined,
                        color: const Color(0xff3468f4),
                        label: 'Take Photo',
                      ),
                    ),
                    SizedBox(width: _s(context, 8)),
                    Expanded(
                      child: _MediaAction(
                        icon: Icons.videocam_outlined,
                        color: const Color(0xffe22b63),
                        label: 'Record Video',
                      ),
                    ),
                    SizedBox(width: _s(context, 8)),
                    Expanded(
                      child: _MediaAction(
                        icon: Icons.image_outlined,
                        color: const Color(0xff5748e7),
                        label: 'Gallery',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _s(context, 12)),
                Center(
                  child: Text(
                    'Snap a photo, record a video, or pick from your gallery (select multiple for a\ncarousel)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xff91a0b7),
                      fontFamily: 'OpenSans',
                      fontSize: _s(context, 12),
                      height: 1.45,
                    ),
                  ),
                ),
                SizedBox(height: _s(context, 24)),
                _TextBox(
                  height: _s(context, 62),
                  text: 'Write a caption... #carnival #island',
                  muted: true,
                ),
                SizedBox(height: _s(context, 14)),
                _TextBox(height: _s(context, 44), text: 'The Valley'),
                SizedBox(height: _s(context, 14)),
                Container(
                  height: _s(context, 44),
                  padding: EdgeInsets.symmetric(horizontal: _s(context, 12)),
                  decoration: BoxDecoration(
                    color: const Color(0xfffffae9),
                    borderRadius: BorderRadius.circular(_s(context, 20)),
                  ),
                  child: Row(
                    children: [
                      Text('🌚', style: TextStyle(fontSize: _s(context, 15))),
                      SizedBox(width: _s(context, 8)),
                      Expanded(
                        child: Text(
                          'Allow Big Up coin gifts',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'OpenSans',
                            fontSize: _s(context, 15),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        width: _s(context, 22),
                        height: _s(context, 22),
                        decoration: BoxDecoration(
                          color: const Color(0xff2589df),
                          borderRadius: BorderRadius.circular(_s(context, 4)),
                        ),
                        child: Icon(Icons.check,
                            color: Colors.white, size: _s(context, 18)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _s(context, 14)),
                Container(
                  padding: EdgeInsets.all(_s(context, 13)),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xffdfe5ee)),
                    borderRadius: BorderRadius.circular(_s(context, 17)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('🛍️', style: TextStyle(fontSize: _s(context, 14))),
                          SizedBox(width: _s(context, 6)),
                          Expanded(
                            child: Text(
                              'Tag a product (shoppable)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'OpenSans',
                                fontSize: _s(context, 15),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _s(context, 14),
                              vertical: _s(context, 9),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xff3198df),
                              borderRadius: BorderRadius.circular(_s(context, 18)),
                            ),
                            child: Text(
                              'Tag Product',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'OpenSans',
                                fontSize: _s(context, 12),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _s(context, 12)),
                      Text(
                        'Feature a Marketplace product so viewers can buy it directly from your\nvibe.',
                        style: TextStyle(
                          color: const Color(0xff91a0b7),
                          fontFamily: 'OpenSans',
                          fontSize: _s(context, 12),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _s(context, 14)),
                SizedBox(
                  width: double.infinity,
                  height: _s(context, 50),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xff3198df),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_s(context, 16)),
                      ),
                    ),
                    child: Text(
                      'Share Vibe',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                        fontSize: _s(context, 16),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final double height;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xffeef6ff) : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: selected ? const Color(0xff3198df) : const Color(0xffdfe5ee),
          width: 1.6,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.black,
          fontFamily: 'OpenSans',
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MediaAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MediaAction({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xfffafbfd),
        border: Border.all(color: const Color(0xffedf1f6), width: 1.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontFamily: 'OpenSans',
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBox extends StatelessWidget {
  final double height;
  final String text;
  final bool muted;

  const _TextBox({
    required this.height,
    required this.text,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffdfe5ee)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: muted ? const Color(0xff99a3b5) : Colors.black,
          fontFamily: 'OpenSans',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _IntroDots extends StatelessWidget {
  const _IntroDots();

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xff35c2df),
      Color(0xff8cd22a),
      Color(0xffcbd5e1),
      Color(0xffcbd5e1),
      Color(0xffcbd5e1),
      Color(0xffcbd5e1),
      Color(0xffcbd5e1),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors
          .map(
            (color) => Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          )
          .toList(),
    );
  }
}

class _BrazilFlag extends StatelessWidget {
  const _BrazilFlag();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 69,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xff059447),
        borderRadius: BorderRadius.circular(7),
      ),
      child: CustomPaint(painter: _BrazilFlagPainter()),
    );
  }
}

class _BrazilFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final yellow = Paint()..color = const Color(0xffffdf2f);
    final blue = Paint()..color = const Color(0xff263a93);
    final white = Paint()..color = Colors.white;
    final diamond = Path()
      ..moveTo(size.width * 0.5, size.height * 0.16)
      ..lineTo(size.width * 0.84, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.84)
      ..lineTo(size.width * 0.16, size.height * 0.5)
      ..close();
    canvas.drawPath(diamond, yellow);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5),
        size.height * 0.21, blue);
    canvas.save();
    canvas.clipPath(
      Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(size.width * 0.5, size.height * 0.5),
            radius: size.height * 0.21,
          ),
        ),
    );
    final band = Path()
      ..moveTo(size.width * 0.27, size.height * 0.47)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.37,
        size.width * 0.73,
        size.height * 0.51,
      )
      ..lineTo(size.width * 0.73, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.45,
        size.width * 0.27,
        size.height * 0.54,
      )
      ..close();
    canvas.drawPath(band, white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
