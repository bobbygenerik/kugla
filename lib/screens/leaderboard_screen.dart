import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/app_state.dart';
import '../widgets/mission_widgets.dart';

class LeaderboardScreen extends StatefulWidget {
  final AppSnapshot snapshot;
  final Stream<List<RemoteLeaderboardEntry>> remoteLeaderboard;
  final bool remoteEnabled;

  const LeaderboardScreen({
    super.key,
    required this.snapshot,
    required this.remoteLeaderboard,
    required this.remoteEnabled,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  GameMode? _modeFilter;

  static const _modes = [
    (null, 'All', Icons.public_rounded),
    (GameMode.dailyPulse, 'Daily', Icons.flash_on_rounded),
    (GameMode.worldAtlas, 'Atlas', Icons.map_rounded),
    (GameMode.landmarkLock, 'Landmark', Icons.terrain_rounded),
  ];

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  eyebrow: 'Leaderboard',
                  title: 'Hall of Navigators',
                  subtitle: 'Family rankings and your personal best missions.',
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: KuglaColors.midnight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: KuglaColors.cyan.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: KuglaColors.cyanSoft,
                    unselectedLabelColor: KuglaColors.textMuted,
                    tabs: const [
                      Tab(text: 'Family'),
                      Tab(text: 'Personal best'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _modes.map((entry) {
                      final (mode, label, icon) = entry;
                      final selected = _modeFilter == mode;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _modeFilter = mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? KuglaColors.cyan.withValues(alpha: 0.14)
                                  : KuglaColors.midnight,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: selected
                                    ? KuglaColors.cyan.withValues(alpha: 0.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon,
                                    size: 13,
                                    color: selected
                                        ? KuglaColors.cyanSoft
                                        : KuglaColors.textMuted),
                                const SizedBox(width: 5),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: selected
                                        ? KuglaColors.cyanSoft
                                        : KuglaColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FamilyTab(
                snapshot: widget.snapshot,
                remoteLeaderboard: widget.remoteLeaderboard,
                remoteEnabled: widget.remoteEnabled,
                modeFilter: _modeFilter,
              ),
              _PersonalBestTab(
                snapshot: widget.snapshot,
                modeFilter: _modeFilter,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FamilyTab extends StatelessWidget {
  final AppSnapshot snapshot;
  final Stream<List<RemoteLeaderboardEntry>> remoteLeaderboard;
  final bool remoteEnabled;
  final GameMode? modeFilter;

  const _FamilyTab({
    required this.snapshot,
    required this.remoteLeaderboard,
    required this.remoteEnabled,
    required this.modeFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (!remoteEnabled) {
      return const _EmptyState(
        icon: Icons.cloud_off_rounded,
        message: 'Firebase is not configured in this build. Family rankings will appear here once it is set up.',
      );
    }

    final familyCode = snapshot.settings.familyCode.trim();
    final displayName = snapshot.settings.displayName.trim();

    if (familyCode.isEmpty || displayName.isEmpty) {
      return const _EmptyState(
        icon: Icons.group_add_rounded,
        message: 'Open Profile & Settings and enter a display name and family code to join a shared leaderboard.',
      );
    }

    return StreamBuilder<List<RemoteLeaderboardEntry>>(
      stream: remoteLeaderboard,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: KuglaColors.cyan),
          );
        }

        final rawEntries = snap.data ?? [];
        final entries = [...rawEntries]
          ..sort((a, b) => b.bestScoreForMode(modeFilter)
              .compareTo(a.bestScoreForMode(modeFilter)));

        if (entries.isEmpty) {
          return _EmptyState(
            icon: Icons.leaderboard_rounded,
            message:
                'No scores yet for family code ${familyCode.toUpperCase()}. Complete a mission on any device to appear here.',
          );
        }

        final scoreLabel = switch (modeFilter) {
          GameMode.dailyPulse => 'daily best',
          GameMode.worldAtlas => 'atlas best',
          GameMode.landmarkLock => 'landmark best',
          null => 'best',
        };

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isMe = entry.displayName.trim().toLowerCase() ==
                displayName.toLowerCase();
            final score = entry.bestScoreForMode(modeFilter);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassPanel(
                color: isMe
                    ? KuglaColors.cyan.withValues(alpha: 0.08)
                    : null,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        '#${index + 1}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isMe
                                  ? KuglaColors.cyanSoft
                                  : null,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${entry.missionsPlayed} missions · ${entry.roundsPlayed} rounds',
                            style: const TextStyle(
                                color: KuglaColors.textMuted,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          score > 0 ? '$score' : '--',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900),
                        ),
                        Text(
                          scoreLabel,
                          style: const TextStyle(
                              color: KuglaColors.textMuted,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PersonalBestTab extends StatelessWidget {
  final AppSnapshot snapshot;
  final GameMode? modeFilter;

  const _PersonalBestTab({required this.snapshot, required this.modeFilter});

  static String _modeLabel(GameMode mode) => switch (mode) {
        GameMode.dailyPulse => 'Daily Pulse',
        GameMode.worldAtlas => 'World Atlas',
        GameMode.landmarkLock => 'Landmark Lock',
      };

  @override
  Widget build(BuildContext context) {
    final allBest = snapshot.bestSessions;
    final best = (modeFilter == null
            ? allBest
            : allBest.where((s) => s.gameMode == modeFilter).toList())
        .take(10)
        .toList();

    if (best.isEmpty) {
      return const _EmptyState(
        icon: Icons.flag_rounded,
        message: 'Complete a mission to see your personal best scores here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      itemCount: best.length,
      itemBuilder: (context, index) {
        final session = best[index];
        final maxScore = 5000 * session.rounds.length;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    '#${index + 1}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${session.totalScore} pts',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_modeLabel(session.gameMode)}  ·  ${session.rounds.length} rounds  ·  ${session.averageDistanceKm.toStringAsFixed(0)} km avg',
                        style: const TextStyle(
                            color: KuglaColors.textMuted,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: session.totalScore / maxScore,
                      minHeight: 6,
                      color: KuglaColors.cyan,
                      backgroundColor: KuglaColors.midnight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        GlassPanel(
          child: Column(
            children: [
              Icon(icon, size: 40, color: KuglaColors.textMuted),
              const SizedBox(height: 14),
              Text(
                message,
                style:
                    const TextStyle(color: KuglaColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
