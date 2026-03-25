import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/app_state.dart';
import '../widgets/mission_widgets.dart';

class HomeScreen extends StatelessWidget {
  final AppSnapshot snapshot;
  final VoidCallback onStartMission;
  final VoidCallback onOpenVault;
  final VoidCallback onOpenOnboarding;
  final VoidCallback onOpenRecords;

  const HomeScreen({
    super.key,
    required this.snapshot,
    required this.onStartMission,
    required this.onOpenVault,
    required this.onOpenOnboarding,
    required this.onOpenRecords,
  });

  @override
  Widget build(BuildContext context) {
    final latestSession = snapshot.latestSession;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _HeroMissionPanel(
                snapshot: snapshot,
                onStartMission: onStartMission,
                onOpenOnboarding: onOpenOnboarding,
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final children = [
                    Expanded(
                      child: TelemetryTile(
                        label: 'Sessions',
                        value: '${snapshot.totalSessions}',
                        icon: Icons.flag_circle_rounded,
                        accent: KuglaColors.cyan,
                      ),
                    ),
                    const SizedBox(width: 12, height: 12),
                    Expanded(
                      child: TelemetryTile(
                        label: 'Best mission',
                        value: '${snapshot.bestSessionScore}',
                        icon: Icons.emoji_events_rounded,
                        accent: KuglaColors.amber,
                      ),
                    ),
                    Expanded(
                      child: TelemetryTile(
                        label: 'Closest guess',
                        value: snapshot.hasSessions
                            ? '${snapshot.closestGuessKm.toStringAsFixed(0)} km'
                            : '--',
                        icon: Icons.track_changes_rounded,
                        accent: KuglaColors.success,
                      ),
                    ),
                  ];
                  return compact
                      ? Column(children: children)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children,
                        );
                },
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                eyebrow: 'Progress',
                title: 'Real mission stats',
                subtitle:
                    'Everything below is computed from missions you have actually played on this device.',
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final modules = [
                    AnimatedHudRing(
                      progress: snapshot.totalRounds == 0
                          ? 0
                          : (snapshot.totalRounds / 20).clamp(0, 1).toDouble(),
                      value: '${snapshot.totalRounds}',
                      label: 'Rounds played',
                      color: KuglaColors.cyan,
                    ),
                    AnimatedHudRing(
                      progress: snapshot.averageRoundScore == 0
                          ? 0
                          : (snapshot.averageRoundScore / 5000)
                              .clamp(0, 1)
                              .toDouble(),
                      value: snapshot.totalRounds == 0
                          ? '--'
                          : snapshot.averageRoundScore.toStringAsFixed(0),
                      label: 'Avg round score',
                      color: KuglaColors.lilac,
                    ),
                    AnimatedHudRing(
                      progress: snapshot.exploredCountries == 0
                          ? 0
                          : (snapshot.exploredCountries / 10)
                              .clamp(0, 1)
                              .toDouble(),
                      value: '${snapshot.exploredCountries}',
                      label: 'Countries seen',
                      color: KuglaColors.amber,
                    ),
                  ];
                  return compact
                      ? Wrap(
                          alignment: WrapAlignment.spaceAround,
                          spacing: 18,
                          runSpacing: 18,
                          children: modules,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: modules,
                        );
                },
              ),
              const SizedBox(height: 28),
              GlassPanel(
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: KuglaColors.amber, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latestSession == null
                                ? 'No missions logged yet'
                                : 'Latest mission score: ${latestSession.totalScore}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            latestSession == null
                                ? 'Start your first mission to begin tracking records, achievements, and history.'
                                : 'Completed ${latestSession.rounds.length} rounds with an average distance of ${latestSession.averageDistanceKm.toStringAsFixed(0)} km.',
                            style: const TextStyle(color: KuglaColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: onOpenRecords,
                      child: const Text('View records'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                eyebrow: 'Modes',
                title: 'Playable right now',
                subtitle:
                    'Each mission is a real local session that saves results on this device.',
              ),
              const SizedBox(height: 16),
              _ModeCard(
                icon: Icons.public_rounded,
                color: KuglaColors.cyan,
                title: 'Street View mission',
                subtitle: 'Guess the location from real Street View imagery.',
                detail:
                    'Rounds, scores, closest guesses, history, and achievements are saved locally after each mission.',
                onLaunch: onStartMission,
              ),
              const SizedBox(height: 14),
              _ModeCard(
                icon: Icons.auto_awesome_mosaic_rounded,
                color: KuglaColors.amber,
                title: 'Achievement vault',
                subtitle: 'Unlock progress based on your actual missions.',
                detail:
                    'The vault updates from your real results instead of fabricated progression.',
                onLaunch: onOpenVault,
                actionLabel: 'Open vault',
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HeroMissionPanel extends StatelessWidget {
  final AppSnapshot snapshot;
  final VoidCallback onStartMission;
  final VoidCallback onOpenOnboarding;

  const _HeroMissionPanel({
    required this.snapshot,
    required this.onStartMission,
    required this.onOpenOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    final latest = snapshot.latestSession;
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
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Chip(
                  avatar: const Icon(Icons.tour_rounded,
                      color: KuglaColors.cyan, size: 18),
                  label: Text('${snapshot.settings.roundsPerMission} rounds'),
                ),
                Chip(
                  avatar: Icon(
                    snapshot.settings.allowMovement
                        ? Icons.directions_walk_rounded
                        : Icons.pan_tool_alt_rounded,
                    color: KuglaColors.amber,
                    size: 18,
                  ),
                  label: Text(
                    snapshot.settings.allowMovement
                        ? 'Movement enabled'
                        : 'No movement',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Play real missions.\nBuild real records.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.06,
                  ),
            ),
            const SizedBox(height: 14),
            Text(
              latest == null
                  ? 'This build now works as a local-first solo game. Your missions, settings, records, and vault progress all live on this device.'
                  : 'Your latest mission scored ${latest.totalScore} points across ${latest.rounds.length} rounds. Jump back in to improve your best run.',
              style: const TextStyle(
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
                OutlinedButton.icon(
                  onPressed: onOpenOnboarding,
                  icon: const Icon(Icons.route_rounded),
                  label: const Text('How scoring works'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback onLaunch;
  final String actionLabel;

  const _ModeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.onLaunch,
    this.actionLabel = 'Open',
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
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  detail,
                  style: const TextStyle(
                    color: KuglaColors.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.tonal(
            onPressed: onLaunch,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
