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
                    colors: [KuglaColors.amber, KuglaColors.rose],
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
            indicatorColor: KuglaColors.cyan.withValues(alpha: 0.22),
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
        indicatorColor: KuglaColors.cyan.withValues(alpha: 0.12),
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

class _NebulaBackdrop extends StatelessWidget {
  const _NebulaBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KuglaColors.deepSpace,
            KuglaColors.midnight,
            Color(0xFF141210),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -20,
            child: _GlowOrb(
              color: KuglaColors.amber.withValues(alpha: 0.15),
              size: 320,
            ),
          ),
          Positioned(
            right: -60,
            top: 100,
            child: _GlowOrb(
              color: KuglaColors.rose.withValues(alpha: 0.10),
              size: 240,
            ),
          ),
          Positioned(
            bottom: -80,
            left: 40,
            child: _GlowOrb(
              color: KuglaColors.cyan.withValues(alpha: 0.09),
              size: 260,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
