import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/app_state.dart';
import '../models/mock_data.dart';
import '../widgets/mission_widgets.dart';

class HomeScreen extends StatelessWidget {
  final AppSnapshot snapshot;
  final void Function(GameMode) onStartMission;
  final VoidCallback onOpenVault;

  const HomeScreen({
    super.key,
    required this.snapshot,
    required this.onStartMission,
    required this.onOpenVault,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _HeroMissionPanel(
                onStartMission: () => onStartMission(GameMode.worldAtlas),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final children = [
                    Expanded(
                      child: TelemetryTile(
                        label: 'Missions',
                        value: '${snapshot.totalSessions}',
                        icon: Icons.flag_rounded,
                        accent: KuglaColors.cyan,
                      ),
                    ),
                    const SizedBox(width: 12, height: 12),
                    Expanded(
                      child: TelemetryTile(
                        label: 'Streak',
                        value: snapshot.currentStreakDays == 0
                            ? '--'
                            : '${snapshot.currentStreakDays}d',
                        icon: Icons.local_fire_department_rounded,
                        accent: KuglaColors.amber,
                      ),
                    ),
                    const SizedBox(width: 12, height: 12),
                    Expanded(
                      child: TelemetryTile(
                        label: 'Countries',
                        value: '${snapshot.exploredCountries}',
                        icon: Icons.public_rounded,
                        accent: KuglaColors.success,
                      ),
                    ),
                  ];
                  return compact
                      ? Column(children: children)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children);
                },
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                eyebrow: 'Modes',
                title: 'Choose your next drop',
                subtitle:
                    'Each route tunes timers, telemetry, and reward pacing differently.',
              ),
              const SizedBox(height: 16),
              ...missionModes.map(
                (mode) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _MissionModeCard(
                    mode: mode,
                    onLaunch: () => onStartMission(mode.gameMode),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HeroMissionPanel extends StatelessWidget {
  final VoidCallback onStartMission;

  const _HeroMissionPanel({
    required this.onStartMission,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: KuglaColors.stroke),
        gradient: const LinearGradient(
          colors: [Color(0xFF163152), Color(0xFF0A1323), Color(0xFF17162E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Chip(
                  avatar: Icon(Icons.satellite_alt_rounded,
                      color: KuglaColors.cyan, size: 18),
                  label: Text('Street View'),
                ),
                Chip(
                  avatar: Icon(Icons.auto_awesome_mosaic_outlined,
                      color: KuglaColors.amber, size: 18),
                  label: Text('Vault unlocks'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Discover the unseen.\nChart the world by instinct.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.06,
                  ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Drop into real Street View locations around the world and use roads, terrain, and architecture to pinpoint where you are.',
              style: TextStyle(
                color: KuglaColors.textMuted,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onStartMission,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start mission'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionModeCard extends StatelessWidget {
  final MissionMode mode;
  final VoidCallback onLaunch;

  const _MissionModeCard({
    required this.mode,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: mode.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(mode.icon, color: mode.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  mode.subtitle,
                  style: const TextStyle(
                    color: KuglaColors.cyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mode.detail,
                  style: const TextStyle(
                    color: KuglaColors.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton.filledTonal(
            onPressed: onLaunch,
            icon: const Icon(Icons.north_east_rounded),
          ),
        ],
      ),
    );
  }
}
