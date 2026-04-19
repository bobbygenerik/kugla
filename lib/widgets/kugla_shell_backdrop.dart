import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'kugla_map_backdrop.dart';

/// Lighter than [KuglaMapBackdrop]: no stacked scrims or [CustomPaint] shaders,
/// which have triggered full-body composite failures on some Android builds.
/// Use for the main shell, onboarding, and other full-screen flows.
class KuglaShellBackdrop extends StatelessWidget {
  final Widget child;

  const KuglaShellBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        const ColoredBox(color: KuglaColors.deepSpace),
        Positioned.fill(
          child: Image.asset(
            KuglaMapBackdrop.mapParchmentAsset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: KuglaColors.midnight),
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
            child: SafeArea(
              top: false,
              bottom: false,
              left: true,
              right: true,
              child: ColoredBox(
                color: KuglaColors.midnight.withValues(alpha: 26 / 255),
                child: RepaintBoundary(
                  child: SizedBox.expand(child: child),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
