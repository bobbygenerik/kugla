import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../widgets/mission_widgets.dart';

class SocialScreen extends StatelessWidget {
  final AppSnapshot snapshot;

  const SocialScreen({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final recentSessions = snapshot.recentSessions.take(10).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        const SectionHeader(
          eyebrow: 'History',
          title: 'Mission log',
          subtitle:
              'A chronological record of the sessions you have actually completed.',
        ),
        const SizedBox(height: 18),
        if (recentSessions.isEmpty)
          const GlassPanel(
            child: Text(
              'No missions logged yet. Start a mission and your history will appear here.',
            ),
          ),
        ...recentSessions.map(
          (session) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${session.totalScore} pts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Played ${session.completedAt.month}/${session.completedAt.day}/${session.completedAt.year} • ${session.rounds.length} rounds',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: session.rounds
                        .map(
                          (round) => Chip(
                            label: Text(
                              '${round.locationName} • ${round.score}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
