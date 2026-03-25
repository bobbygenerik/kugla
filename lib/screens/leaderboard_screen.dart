import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../widgets/mission_widgets.dart';

class LeaderboardScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bestSessions = snapshot.bestSessions.take(5).toList();
    final hasFamilySetup = snapshot.settings.displayName.trim().isNotEmpty &&
        snapshot.settings.familyCode.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        const SectionHeader(
          eyebrow: 'Records',
          title: 'Family leaderboard',
          subtitle:
              'Compare synced mission scores once both devices join the same family code.',
        ),
        const SizedBox(height: 18),
        if (!remoteEnabled)
          const GlassPanel(
            child: Text(
              'Remote sync code is in the app, but Firebase is not configured in this build yet. Once it is configured, this screen will show live rankings.',
            ),
          )
        else if (!hasFamilySetup)
          const GlassPanel(
            child: Text(
              'Open Profile & Settings and enter a display name plus a shared family code. Use the same family code on both phones.',
            ),
          )
        else
          StreamBuilder<List<RemoteLeaderboardEntry>>(
            stream: remoteLeaderboard,
            builder: (context, snapshotData) {
              final entries = snapshotData.data ?? const <RemoteLeaderboardEntry>[];
              if (entries.isEmpty) {
                return GlassPanel(
                  child: Text(
                    'No synced family scores yet for code ${snapshot.settings.familyCode.toUpperCase()}. Complete a mission on both devices and they will appear here.',
                  ),
                );
              }
              return Column(
                children: entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isMe = item.displayName.trim().toLowerCase() ==
                      snapshot.settings.displayName.trim().toLowerCase();
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == entries.length - 1 ? 0 : 12),
                    child: GlassPanel(
                      color: isMe ? const Color(0x2261E6E8) : null,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              '#${index + 1}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.missionsPlayed} missions • ${item.roundsPlayed} rounds',
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item.bestSessionScore}',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              const Text('best'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        const SizedBox(height: 24),
        const SectionHeader(
          eyebrow: 'Local',
          title: 'Your best missions',
          subtitle: 'These are the best sessions saved on this device.',
        ),
        const SizedBox(height: 18),
        GlassPanel(
          child: Row(
            children: [
              Expanded(
                child: TelemetryTile(
                  label: 'Best score',
                  value: '${snapshot.bestSessionScore}',
                  icon: Icons.emoji_events_rounded,
                  accent: const Color(0xFFFFC86B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TelemetryTile(
                  label: 'Avg round',
                  value: snapshot.totalRounds == 0
                      ? '--'
                      : snapshot.averageRoundScore.toStringAsFixed(0),
                  icon: Icons.query_stats_rounded,
                  accent: const Color(0xFF61E6E8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (bestSessions.isEmpty)
          const GlassPanel(
            child: Text(
              'No completed missions yet. Finish a mission and your results will show up here automatically.',
            ),
          ),
        ...bestSessions.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final session = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecordCard(
                rank: index + 1,
                session: session,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  final int rank;
  final MissionSession session;

  const _RecordCard({
    required this.rank,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.totalScore} pts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.rounds.length} rounds • ${session.averageDistanceKm.toStringAsFixed(0)} km avg distance',
                ),
              ],
            ),
          ),
          Text('${session.completedAt.month}/${session.completedAt.day}'),
        ],
      ),
    );
  }
}
