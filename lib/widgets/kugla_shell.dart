import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/theme.dart';

class KuglaShell extends StatelessWidget {
  final String title;
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenOnboarding;
  final String? avatarPath;

  const KuglaShell({
    super.key,
    required this.title,
    required this.child,
    required this.currentIndex,
    required this.onNavTap,
    required this.onOpenProfile,
    required this.onOpenOnboarding,
    this.avatarPath,
  });

  @override
  Widget build(BuildContext context) {
    final useRail = MediaQuery.sizeOf(context).width >= 768;
    final topBar = _KuglaTopBar(
      title: title,
      onOpenProfile: onOpenProfile,
      onOpenOnboarding: onOpenOnboarding,
      avatarPath: avatarPath,
    );
    final body = Stack(
      fit: StackFit.expand,
      children: [
        const _NebulaBackdrop(),
        SafeArea(
          top: false,
          child: useRail
              ? Row(
                  children: [
                    _KuglaNavRail(
                      currentIndex: currentIndex,
                      onTap: onNavTap,
                    ),
                    Expanded(child: child),
                  ],
                )
              : child,
        ),
      ],
    );
    if (useRail) {
      return Scaffold(appBar: topBar, body: body);
    }
    return Scaffold(
      extendBody: true,
      appBar: topBar,
      body: body,
      bottomNavigationBar: _KuglaBottomBar(
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
    );
  }
}

class _KuglaTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenOnboarding;
  final String? avatarPath;

  const _KuglaTopBar({
    required this.title,
    required this.onOpenProfile,
    required this.onOpenOnboarding,
    this.avatarPath,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hPad = w > 720 ? ((w - 680) / 2).clamp(20.0, 240.0) : 20.0;
    return AppBar(
      toolbarHeight: 82,
      titleSpacing: hPad,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Street View drops · pin the globe',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: KuglaColors.textMuted,
                  letterSpacing: 0.15,
                ),
          ),
        ],
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              border: const Border(
                bottom: BorderSide(color: KuglaColors.stroke),
              ),
              gradient: LinearGradient(
                colors: [
                  KuglaColors.deepSpace.withValues(alpha: 0.92),
                  KuglaColors.midnight.withValues(alpha: 0.72),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Mission briefing',
          onPressed: onOpenOnboarding,
          icon: const Icon(Icons.tips_and_updates_rounded),
        ),
        Padding(
          padding: EdgeInsets.only(right: hPad),
          child: GestureDetector(
            onTap: onOpenProfile,
            child: Tooltip(
              message: 'Profile',
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [KuglaColors.cyan, KuglaColors.lilac],
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarPath != null
                    ? Image.file(File(avatarPath!), fit: BoxFit.cover)
                    : const Icon(Icons.person_rounded,
                        color: KuglaColors.deepSpace, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(82);
}

class _KuglaBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _KuglaBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          decoration: BoxDecoration(
            color: KuglaColors.midnight.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KuglaColors.stroke),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            height: 74,
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            indicatorColor: KuglaColors.pulse.withValues(alpha: 0.20),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events_rounded),
                label: 'Records',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
                selectedIcon: Icon(Icons.history_edu_rounded),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_mosaic_outlined),
                selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded),
                label: 'Vault',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KuglaNavRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _KuglaNavRail({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: KuglaColors.stroke)),
      ),
      child: NavigationRail(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: KuglaColors.midnight,
        indicatorColor: KuglaColors.pulse.withValues(alpha: 0.14),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: const TextStyle(
          color: KuglaColors.cyanSoft,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: KuglaColors.textMuted,
          fontSize: 12,
        ),
        selectedIconTheme: const IconThemeData(color: KuglaColors.cyanSoft),
        unselectedIconTheme: const IconThemeData(color: KuglaColors.textMuted),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: Text('Explore'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: Text('Records'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_edu_rounded),
            label: Text('History'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.auto_awesome_mosaic_outlined),
            selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded),
            label: Text('Vault'),
          ),
        ],
      ),
    );
  }
}

/// Parchment map + tint stack aligned with `generate_ui_mockups.build_map_background`
/// and `phone_shell` scrims (readable UI on top).
class _NebulaBackdrop extends StatelessWidget {
  const _NebulaBackdrop();

  static const _mapAsset = 'assets/bg/map_parchment.png';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: KuglaColors.deepSpace),
        Positioned.fill(
          child: Image.asset(
            _mapAsset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFF060F15).withValues(alpha: 20 / 255),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F2535).withValues(alpha: 72 / 255),
                  const Color(0xFF071318).withValues(alpha: 96 / 255),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFF0A1B24).withValues(alpha: 18 / 255),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFF071318).withValues(alpha: 28 / 255),
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

/// Soft edge darkening like mockup `draw_edge_vignette` (no rounded phone mask).
class _BackdropVignettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.38),
        ],
        stops: const [0.58, 1.0],
        center: Alignment.center,
        radius: 1.05,
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
