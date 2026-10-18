import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:link_up/model/user_model.dart';

class LinkUpMatchPopup extends StatefulWidget {
  final UserModel user;
  final ImageProvider currentUserAvatar;
  final VoidCallback? onMessage;
  final VoidCallback? onKeepSwiping;
  final VoidCallback? onSendSpark;

  const LinkUpMatchPopup({
    Key? key,
    required this.user,
    required this.currentUserAvatar,
    this.onMessage,
    this.onKeepSwiping,
    this.onSendSpark,
  }) : super(key: key);

  @override
  State<LinkUpMatchPopup> createState() => _LinkUpMatchPopupState();
}

class _LinkUpMatchPopupState extends State<LinkUpMatchPopup>
    with TickerProviderStateMixin {
  late final AnimationController _popController;
  late final AnimationController _confettiController;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
    _scale = CurvedAnimation(
      parent: _popController,
      curve: Curves.elasticOut,
    );
    _fade = CurvedAnimation(
      parent: _popController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _popController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  String get _name => widget.user.firstName.isNotEmpty
      ? widget.user.firstName
      : 'your match';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = math.min(size.width - 32, 410.0);

    return Material(
      color: Colors.black.withOpacity(0.66),
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(_scale),
            child: Container(
              width: cardWidth,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff0d1424), Color(0xff17213b), Color(0xff111827)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffec4899).withOpacity(0.28),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(child: _Confetti(controller: _confettiController)),
                  Positioned(
                    top: -60,
                    left: -20,
                    right: -20,
                    child: Container(
                      height: 190,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xff2f9bef).withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    left: -10,
                    right: -10,
                    child: Container(
                      height: 210,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xffec4899).withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [Color(0xfff59e0b), Color(0xffec4899)],
                            ),
                          ),
                          child: const Text(
                            '✨ NEW MATCH',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            colors: [Color(0xff35c3e8), Color(0xff9edb2f), Color(0xffec4899)],
                          ).createShader(rect),
                          child: const Text(
                            "It's a Match!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 40,
                              height: 0.95,
                              letterSpacing: -1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'You and $_name liked each other 🎉',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.58),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          height: 118,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 185,
                                height: 86,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(90),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xff35c3e8).withOpacity(0.48),
                                      const Color(0xffec4899).withOpacity(0.48),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xffec4899).withOpacity(0.28),
                                      blurRadius: 35,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(-38, 0),
                                child: _avatar(widget.currentUserAvatar),
                              ),
                              Transform.translate(
                                offset: const Offset(38, 0),
                                child: _avatar(_networkOrFallback(widget.user.avatar)),
                              ),
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xfff59e0b), Color(0xffec4899)],
                                  ),
                                  border: Border.all(color: const Color(0xff0d1424), width: 3),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 10)),
                                  ],
                                ),
                                child: const Icon(Icons.favorite, color: Colors.white, size: 25),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _primaryButton(
                          icon: Icons.auto_awesome,
                          label: 'Send a Spark',
                          onTap: widget.onSendSpark ?? () => Get.back(),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _secondaryButton(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: 'Message',
                                onTap: widget.onMessage ?? () => Get.back(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ghostButton(
                                label: 'Keep Swiping',
                                onTap: widget.onKeepSwiping ?? () => Get.back(),
                              ),
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
        ),
      ),
    );
  }

  Widget _avatar(ImageProvider image) {
    return Container(
      width: 98,
      height: 98,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xff0d1424), width: 4),
        image: DecorationImage(image: image, fit: BoxFit.cover),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
    );
  }

  ImageProvider _networkOrFallback(String url) {
    if (url.trim().isEmpty) return const NetworkImage('https://i.pravatar.cc/160?img=12');
    return NetworkImage(url);
  }

  Widget _primaryButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [Color(0xfff59e0b), Color(0xffec4899)]),
          boxShadow: [
            BoxShadow(color: const Color(0xffec4899).withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 9)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _ghostButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.70), fontWeight: FontWeight.w900, fontSize: 14),
        ),
      ),
    );
  }
}

class _Confetti extends StatelessWidget {
  final Animation<double> controller;

  const _Confetti({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ConfettiPainter(controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  static const colors = [
    Color(0xff35c3e8),
    Color(0xff9edb2f),
    Color(0xffffe14d),
    Color(0xfff43f5e),
    Color(0xffa855f7),
  ];

  _ConfettiPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 42; i++) {
      final seed = (i * 37) % 100 / 100;
      final x = size.width * seed;
      final fall = ((t + i * 0.037) % 1.0);
      final y = -20 + fall * (size.height + 70);
      final w = 5.0 + (i % 4) * 2;
      final h = 8.0 + (i % 3) * 3;
      paint.color = colors[i % colors.length].withOpacity(1 - fall * 0.65);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((fall * math.pi * 3) + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
