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
          padding: adaptiveScreenPadding(context),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final telemetryTiles = [
                      TelemetryTile(
                        label: 'Missions',
                        value: '${snapshot.totalSessions}',
                        icon: Icons.flag_rounded,
                        accent: KuglaColors.cyan,
                      ),
                      TelemetryTile(
                        label: 'Streak',
                        value: snapshot.currentStreakDays == 0
                            ? '--'
                            : '${snapshot.currentStreakDays}d',
                        icon: Icons.local_fire_department_rounded,
                        accent: KuglaColors.amber,
                      ),
                      TelemetryTile(
                        label: 'Countries',
                        value: '${snapshot.exploredCountries}',
                        icon: Icons.public_rounded,
                        accent: KuglaColors.success,
                      ),
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!wide) ...[
                          _HeroMissionPanel(
                            snapshot: snapshot,
                            onStartMission: () =>
                                onStartMission(GameMode.dailyPulse),
                            onOpenVault: onOpenVault,
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, innerConstraints) {
                              final compact = innerConstraints.maxWidth < 760;
                              final children = [
                                Expanded(child: telemetryTiles[0]),
                                const SizedBox(width: 12, height: 12),
                                Expanded(child: telemetryTiles[1]),
                                const SizedBox(width: 12, height: 12),
                                Expanded(child: telemetryTiles[2]),
                              ];
                              return compact
                                  ? Column(children: children)
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: children,
                                    );
                            },
                          ),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _HeroMissionPanel(
                                  snapshot: snapshot,
                                  onStartMission: () =>
                                      onStartMission(GameMode.dailyPulse),
                                  onOpenVault: onOpenVault,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    telemetryTiles[0],
                                    const SizedBox(height: 12),
                                    telemetryTiles[1],
                                    const SizedBox(height: 12),
                                    telemetryTiles[2],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 32),
                        const SectionHeader(
                          eyebrow: 'Routes',
                          title: 'Pick how you want to play',
                          subtitle:
                              'Timers, streak bonuses, and scoring change with each mode.',
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
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMissionPanel extends StatelessWidget {
  final AppSnapshot snapshot;
  final VoidCallback onStartMission;
  final VoidCallback onOpenVault;

  const _HeroMissionPanel({
    required this.snapshot,
    required this.onStartMission,
    required this.onOpenVault,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedCount = snapshot.achievements.where((a) => a.unlocked).length;
    final vaultLabel = '$unlockedCount/${snapshot.achievements.length} vault marks';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border(
          top: BorderSide(color: KuglaColors.amber.withValues(alpha: 0.5)),
          left: const BorderSide(color: KuglaColors.stroke),
          right: const BorderSide(color: KuglaColors.stroke),
          bottom: const BorderSide(color: KuglaColors.stroke),
        ),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2C2318),
            KuglaColors.midnight,
            Color(0xFF1F1A16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                const Chip(
                  avatar: Icon(Icons.flash_on_rounded,
                      color: KuglaColors.amber, size: 18),
                  label: Text('Daily Pulse'),
                ),
                Chip(
                  avatar: const Icon(Icons.auto_awesome_mosaic_outlined,
                      color: KuglaColors.cyan, size: 18),
                  label: Text(vaultLabel),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Daily pulse is ready.\nChart the next drop.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: const Text(
                'Five daily-seeded rounds with a live timer, streak bonuses, and one clean pin on the map.',
                style: TextStyle(
                  color: KuglaColors.textMuted,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onStartMission,
                  icon: const Icon(Icons.flash_on_rounded),
                  label: const Text('Play Daily Pulse'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenVault,
                  icon: const Icon(Icons.auto_awesome_mosaic_outlined),
                  label: const Text('Open Vault'),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final iconTile = Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: mode.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(mode.icon, color: mode.color),
        );

        final copy = Column(
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
              style: TextStyle(
                color: mode.color,
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
        );

        final launchButton = IconButton.filledTonal(
          onPressed: onLaunch,
          icon: const Icon(Icons.north_east_rounded),
        );

        return Container(
          decoration: BoxDecoration(
            color: KuglaColors.panel.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border(
              top: const BorderSide(color: KuglaColors.stroke),
              right: const BorderSide(color: KuglaColors.stroke),
              bottom: const BorderSide(color: KuglaColors.stroke),
              left:
                  BorderSide(color: mode.color.withValues(alpha: 0.7), width: 3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          iconTile,
                          const SizedBox(width: 16),
                          Expanded(child: copy),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: launchButton,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      iconTile,
                      const SizedBox(width: 16),
                      Expanded(child: copy),
                      const SizedBox(width: 16),
                      launchButton,
                    ],
                  ),
          ),
        );
      },
    );
  }
}
