import 'package:flutter/material.dart';

class CustomQrCodeWidget extends StatelessWidget {
  final double size;
  const CustomQrCodeWidget({Key? key, this.size = 220}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.1),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size * 0.84, size * 0.84),
            painter: CustomQrPainter(),
          ),
          Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: const Color(0xff2d98e5),
              borderRadius: BorderRadius.circular(size * 0.06),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Center(
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'li',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 22,
                      ),
                    ),
                    TextSpan(
                      text: 'p',
                      style: TextStyle(
                        color: Color(0xffccff00),
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = const LinearGradient(
      colors: [Color(0xff8b5cf6), Color(0xff3b82f6), Color(0xff0ea5e9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(rect);

    final double dotSize = size.width / 25;
    final double radius = dotSize * 0.35;

    void drawFinderPattern(double x, double y) {
      final outerRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, dotSize * 7, dotSize * 7),
        Radius.circular(radius * 3),
      );
      final outerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = dotSize * 1.4
        ..shader = paint.shader;
      canvas.drawRRect(outerRRect, outerPaint);

      final innerRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + dotSize * 2, y + dotSize * 2, dotSize * 3, dotSize * 3),
        Radius.circular(radius * 1.5),
      );
      final innerPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = paint.shader;
      canvas.drawRRect(innerRRect, innerPaint);
    }

    drawFinderPattern(0, 0);
    drawFinderPattern(size.width - dotSize * 7, 0);
    drawFinderPattern(0, size.height - dotSize * 7);

    final rnd = List.generate(25, (i) => List.generate(25, (j) => (i * 3 + j * 7) % 2 == 0));
    for (int i = 0; i < 25; i++) {
      for (int j = 0; j < 25; j++) {
        bool inTopLeftFinder = i < 8 && j < 8;
        bool inTopRightFinder = i < 8 && j >= 17;
        bool inBottomLeftFinder = i >= 17 && j < 8;
        bool inCenterLogo = i >= 9 && i <= 15 && j >= 9 && j <= 15;

        if (!inTopLeftFinder && !inTopRightFinder && !inBottomLeftFinder && !inCenterLogo) {
          if (rnd[i][j]) {
            final rrect = RRect.fromRectAndRadius(
              Rect.fromLTWH(j * dotSize + dotSize * 0.15, i * dotSize + dotSize * 0.15, dotSize * 0.7, dotSize * 0.7),
              Radius.circular(radius),
            );
            canvas.drawRRect(rrect, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
