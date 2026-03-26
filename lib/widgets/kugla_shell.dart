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
    return Scaffold(
      extendBody: true,
      appBar: _KuglaTopBar(
        title: title,
        onOpenProfile: onOpenProfile,
        onOpenOnboarding: onOpenOnboarding,
        avatarPath: avatarPath,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _NebulaBackdrop(),
          SafeArea(
            top: false,
            child: child,
          ),
        ],
      ),
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
    return AppBar(
      toolbarHeight: 82,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Local-first geography missions',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: KuglaColors.textMuted,
                ),
          ),
        ],
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: KuglaColors.stroke),
              ),
              gradient: LinearGradient(
                colors: [Color(0xD90C1423), Color(0x990D1B2F)],
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
          padding: const EdgeInsets.only(right: 16),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: KuglaColors.midnight.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
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
        indicatorColor: KuglaColors.cyan.withValues(alpha: 0.16),
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
          colors: [Color(0xFF050B14), Color(0xFF0D1B2F), Color(0xFF111F35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -30,
            child: _GlowOrb(
              color: KuglaColors.cyan.withValues(alpha: 0.18),
              size: 240,
            ),
          ),
          Positioned(
            right: -40,
            top: 120,
            child: _GlowOrb(
              color: KuglaColors.lilac.withValues(alpha: 0.14),
              size: 220,
            ),
          ),
          Positioned(
            bottom: -70,
            left: 80,
            child: _GlowOrb(
              color: KuglaColors.amber.withValues(alpha: 0.12),
              size: 180,
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
