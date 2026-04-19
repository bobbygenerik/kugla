import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Parchment map + tint stack (same treatment as main shell). Use behind
/// onboarding, profile, and any full-screen flows that should feel like Kugla.
class KuglaMapBackdrop extends StatelessWidget {
  const KuglaMapBackdrop({super.key});

  /// Shared with [KuglaShell] for a simpler, single-pass backdrop on Android.
  static const mapParchmentAsset = 'assets/bg/map_parchment.png';

  static const _mapAsset = mapParchmentAsset;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: KuglaColors.deepSpace),
          Positioned.fill(
            child: Image.asset(
              _mapAsset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: KuglaColors.midnight),
            ),
          ),
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFF060F15).withValues(alpha: 12 / 255),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F2535).withValues(alpha: 48 / 255),
                  const Color(0xFF071318).withValues(alpha: 68 / 255),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFF0A1B24).withValues(alpha: 12 / 255),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFF071318).withValues(alpha: 18 / 255),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _AtlasBackdropPainter(),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _BackdropVignettePainter(),
          ),
        ),
      ],
      ),
    );
  }
}

class _AtlasBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final contour = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF8BBDCC).withValues(alpha: 0.07);

    for (var i = 0; i < 10; i++) {
      final y = size.height * (0.10 + (i * 0.09));
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width * 0.25, y - 14, size.width * 0.5, y)
        ..quadraticBezierTo(size.width * 0.75, y + 14, size.width, y);
      canvas.drawPath(path, contour);
    }

    final meridian = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF6AAABB).withValues(alpha: 0.06);

    for (var i = 0; i < 8; i++) {
      final x = size.width * (0.08 + (i * 0.12));
      final path = Path()
        ..moveTo(x, 0)
        ..quadraticBezierTo(x - 10, size.height * 0.5, x, size.height);
      canvas.drawPath(path, meridian);
    }

    final route = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = KuglaColors.pulse.withValues(alpha: 0.14);

    final routePath = Path()
      ..moveTo(size.width * 0.10, size.height * 0.72)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.54,
        size.width * 0.58,
        size.height * 0.84,
        size.width * 0.88,
        size.height * 0.38,
      );
    canvas.drawPath(routePath, route);

    final marker = Paint()
      ..style = PaintingStyle.fill
      ..color = KuglaColors.atlas.withValues(alpha: 0.22);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.56), 3, marker);
    canvas.drawCircle(Offset(size.width * 0.26, size.height * 0.66), 2.6, marker);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackdropVignettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.30),
        ],
        stops: const [0.55, 1.0],
        center: Alignment.center,
        radius: 1.05,
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
