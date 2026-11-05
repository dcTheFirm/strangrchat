import 'package:flutter/material.dart';

import 'tokens.dart';

class StickerAvatar extends StatelessWidget {
  const StickerAvatar({
    super.key,
    required this.variant,
    required this.size,
    this.semanticLabel = 'Decorative sticker illustration',
  });

  final int variant;
  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _StickerPainter(variant)),
      ),
    );
  }
}

class _StickerPainter extends CustomPainter {
  const _StickerPainter(this.variant);

  final int variant;

  static const _backgrounds = [
    AppTokens.peach,
    AppTokens.blush,
    AppTokens.lavender,
    Color(0xFFD6E8D9),
  ];

  static const _accents = [
    AppTokens.coralDeep,
    Color(0xFF72509A),
    Color(0xFFB75E20),
    Color(0xFF397A62),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 100;
    final center = Offset(size.width / 2, size.height / 2);
    final background = _backgrounds[variant % _backgrounds.length];
    final accent = _accents[variant % _accents.length];
    final paint = Paint()..isAntiAlias = true;

    paint.color = background;
    canvas.drawCircle(center, size.shortestSide * 0.48, paint);

    paint.color = accent;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, 7 * unit),
        width: 59 * unit,
        height: 66 * unit,
      ),
      paint,
    );

    paint.color = AppTokens.surface;
    canvas.drawCircle(center.translate(-16 * unit, -2 * unit), 6 * unit, paint);
    canvas.drawCircle(center.translate(16 * unit, -2 * unit), 6 * unit, paint);

    paint.color = AppTokens.ink;
    canvas.drawCircle(center.translate(-15 * unit, -1 * unit), 2 * unit, paint);
    canvas.drawCircle(center.translate(15 * unit, -1 * unit), 2 * unit, paint);

    paint
      ..color = AppTokens.blush
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.translate(-24 * unit, 12 * unit), 5 * unit, paint);
    canvas.drawCircle(center.translate(24 * unit, 12 * unit), 5 * unit, paint);

    paint
      ..color = AppTokens.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * unit
      ..strokeCap = StrokeCap.round;
    final smile = Path()
      ..moveTo(center.dx - 8 * unit, center.dy + 15 * unit)
      ..quadraticBezierTo(
        center.dx,
        center.dy + 25 * unit,
        center.dx + 8 * unit,
        center.dy + 15 * unit,
      );
    canvas.drawPath(smile, paint);

    paint
      ..color = AppTokens.tangerine
      ..style = PaintingStyle.fill;
    final tuft = Path()
      ..moveTo(center.dx - 8 * unit, center.dy - 26 * unit)
      ..quadraticBezierTo(
        center.dx - 20 * unit,
        center.dy - 44 * unit,
        center.dx - 2 * unit,
        center.dy - 38 * unit,
      )
      ..quadraticBezierTo(
        center.dx + 7 * unit,
        center.dy - 53 * unit,
        center.dx + 9 * unit,
        center.dy - 31 * unit,
      )
      ..close();
    canvas.drawPath(tuft, paint);

    paint
      ..color = AppTokens.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * unit;
    canvas.drawCircle(center, size.shortestSide * 0.475, paint);
  }

  @override
  bool shouldRepaint(_StickerPainter oldDelegate) =>
      oldDelegate.variant != variant;
}
