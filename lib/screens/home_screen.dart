import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/app_state.dart';
import '../models/mock_data.dart';
import '../widgets/mission_widgets.dart';

class HomeScreen extends StatefulWidget {
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Own controller so we never inherit a stale [PrimaryScrollController]
  /// offset from another route or tab (which can leave this page blank).
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(0);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          padding: adaptiveScreenPadding(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: LayoutBuilder(
                  builder: (context, inner) {
                    final wide = inner.maxWidth >= 980;
                    final telemetryTiles = [
                      TelemetryTile(
                        label: 'Missions',
                        value: '${widget.snapshot.totalSessions}',
                        icon: Icons.flag_rounded,
                        accent: KuglaColors.cyan,
                      ),
                      TelemetryTile(
                        label: 'Streak',
                        value: widget.snapshot.currentStreakDays == 0
                            ? '--'
                            : '${widget.snapshot.currentStreakDays}d',
                        icon: Icons.local_fire_department_rounded,
                        accent: KuglaColors.pulse,
                      ),
                      TelemetryTile(
                        label: 'Countries',
                        value: '${widget.snapshot.exploredCountries}',
                        icon: Icons.public_rounded,
                        accent: KuglaColors.success,
                      ),
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!wide) ...[
                          _HeroMissionPanel(
                            snapshot: widget.snapshot,
                            onStartMission: () =>
                                widget.onStartMission(GameMode.dailyPulse),
                            onOpenVault: widget.onOpenVault,
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, tileConstraints) {
                              final useRow = tileConstraints.maxWidth >= 760;
                              if (useRow) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: telemetryTiles[0]),
                                    const SizedBox(width: 12),
                                    Expanded(child: telemetryTiles[1]),
                                    const SizedBox(width: 12),
                                    Expanded(child: telemetryTiles[2]),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  telemetryTiles[0],
                                  const SizedBox(height: 12),
                                  telemetryTiles[1],
                                  const SizedBox(height: 12),
                                  telemetryTiles[2],
                                ],
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
                                  snapshot: widget.snapshot,
                                  onStartMission: () => widget
                                      .onStartMission(GameMode.dailyPulse),
                                  onOpenVault: widget.onOpenVault,
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
                          title: 'Other mission types',
                          subtitle:
                              'Daily Pulse lives in the card above. Atlas and Landmark use different timers and scoring.',
                        ),
                        const SizedBox(height: 16),
                        ...missionModes
                            .where((m) => m.gameMode != GameMode.dailyPulse)
                            .map(
                              (mode) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _MissionModeCard(
                                  mode: mode,
                                  onLaunch: () =>
                                      widget.onStartMission(mode.gameMode),
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
        );
      },
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
    final vaultLabel =
        '$unlockedCount/${snapshot.achievements.length} achievements';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF3D495B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Background layers must be [Positioned.fill]: a bare [ColoredBox] in
            // a [Stack] expands to the column's unbounded height and breaks layout
            // on device (release builds can show a blank body).
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color(0xF21C222C),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0A1016).withValues(alpha: 0.52),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.44],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 3,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        KuglaColors.pulse.withValues(alpha: 0.9),
                        KuglaColors.cyan.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
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
                            color: KuglaColors.pulse, size: 18),
                        label: Text('Daily Pulse'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.auto_awesome_mosaic_outlined,
                            color: KuglaColors.fog, size: 18),
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
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Mission'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
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

        final launchButton = FilledButton.tonalIcon(
          onPressed: onLaunch,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Play'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        );

        // Rounded rects cannot mix borderRadius with non-uniform Border colors
        // (paint error). Use a uniform stroke + left accent strip.
        return Container(
          decoration: BoxDecoration(
            color: KuglaColors.panel.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: KuglaColors.stroke),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: ColoredBox(
                  color: mode.color.withValues(alpha: 0.7),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(23, 20, 20, 20),
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
            ],
          ),
        );
      },
    );
  }
}
