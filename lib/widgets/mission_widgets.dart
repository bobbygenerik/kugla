import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/layout_breakpoints.dart';
import '../app/theme.dart';

/// Bottom scroll inset when using [KuglaShell]’s floating pill + [Scaffold.extendBody].
/// Covers pill row, outer margin, drop shadow, and a little headroom for larger
/// accessibility text — [extendBody] zeroes [MediaQuery.padding] at the bottom
/// for the body, so this must fully clear the bar visually.
const kShellFloatingNavScrollBottomDp = 142.0;

EdgeInsets adaptiveScreenPadding(BuildContext context,
    {double? bottom,
    double top = 18,
    bool includeFloatingNavReserve = true}) {
  final mq = MediaQuery.of(context);
  final h = context.centeredContentHorizontalPadding;
  // With extendBody, use viewPadding for system gesture / home indicator; on some
  // Android nav modes padding.bottom can be the larger signal — take the max.
  final systemBottom =
      math.max(mq.viewPadding.bottom, mq.padding.bottom);
  final textBump = (mq.textScaler.scale(14) - 14.0).clamp(0.0, 8.0);
  final navBlock = includeFloatingNavReserve
      ? kShellFloatingNavScrollBottomDp + textBump
      : 24.0 + (textBump * 0.5);
  final b = bottom ?? (navBlock + systemBottom);
  return EdgeInsets.fromLTRB(h, top, h, b);
}

/// Keeps section titles readable on photographic / map backdrops.
List<Shadow> get _sectionHeaderTextShadows => [
      Shadow(
        color: Colors.black.withValues(alpha: 0.75),
        blurRadius: 10,
        offset: const Offset(0, 1),
      ),
      Shadow(
        color: Colors.black.withValues(alpha: 0.45),
        blurRadius: 20,
        offset: const Offset(0, 2),
      ),
    ];

class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final shadows = _sectionHeaderTextShadows;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: KuglaColors.cyanSoft,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w800,
                      shadows: shadows,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: KuglaColors.text,
                      height: 1.15,
                      shadows: shadows,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: KuglaColors.fog,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        shadows: shadows,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? KuglaColors.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KuglaColors.stroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class TelemetryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const TelemetryTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // Was accent@0.08 as the sole fill — nearly invisible on the map backdrop.
    final surface = Color.alphaBlend(
      accent.withValues(alpha: 0.34),
      KuglaColors.panelRaised,
    );
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Color.alphaBlend(
            accent.withValues(alpha: 0.55),
            KuglaColors.stroke,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.45),
                ),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: KuglaColors.fog,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: KuglaColors.text,
                          height: 1.15,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
