import 'dart:io';

import 'package:flutter/material.dart';

import '../app/build_stamp.dart';
import '../app/theme.dart';
import 'kugla_gradient_title.dart';
import 'kugla_shell_backdrop.dart';

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
    final body = useRail
        ? Row(
            children: [
              _KuglaNavRail(
                currentIndex: currentIndex,
                onTap: onNavTap,
              ),
              Expanded(
                child: KuglaShellBackdrop(child: child),
              ),
            ],
          )
        : KuglaShellBackdrop(child: child);
    if (useRail) {
      return Scaffold(appBar: topBar, body: body);
    }
    // extendBody: true gives the body the full inset box under the app bar so
    // tab content keeps a non-zero height on devices where the floating pill
    // + SafeArea combo otherwise produced an empty middle panel.
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
          KuglaGradientTitle(title),
          const SizedBox(height: 4),
          Text(
            'Street View drops · pin the globe · $kBuildStamp',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: KuglaColors.textMuted,
                  letterSpacing: 0.15,
                ),
          ),
        ],
      ),
      // Avoid BackdropFilter here: on some Android GPUs it can composite incorrectly
      // and obscure the entire scaffold body (looks like a blank middle panel).
      flexibleSpace: Container(
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

  static const _items = <(IconData, IconData, String)>[
    (Icons.explore_outlined, Icons.explore_rounded, 'Explore'),
    (Icons.emoji_events_outlined, Icons.emoji_events_rounded, 'Records'),
    (Icons.history_rounded, Icons.history_edu_rounded, 'History'),
    (
      Icons.auto_awesome_mosaic_outlined,
      Icons.auto_awesome_mosaic_rounded,
      'Vault',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      minimum: EdgeInsets.zero,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _KuglaNavPillItem(
                      selected: currentIndex == i,
                      iconOutlined: _items[i].$1,
                      iconFilled: _items[i].$2,
                      label: _items[i].$3,
                      onTap: () => onTap(i),
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

class _KuglaNavPillItem extends StatelessWidget {
  final bool selected;
  final IconData iconOutlined;
  final IconData iconFilled;
  final String label;
  final VoidCallback onTap;

  const _KuglaNavPillItem({
    required this.selected,
    required this.iconOutlined,
    required this.iconFilled,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = selected ? iconFilled : iconOutlined;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? KuglaColors.pulse.withValues(alpha: 0.20)
                      : null,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color:
                      selected ? KuglaColors.cyanSoft : KuglaColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? KuglaColors.cyanSoft
                          : KuglaColors.textMuted,
                      letterSpacing: 0.2,
                    ),
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
