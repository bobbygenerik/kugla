import 'package:flutter/material.dart';

import '../app/mode_style.dart';
import '../app/theme.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        final contentMaxWidth = wide ? 980.0 : double.infinity;
        final constrainedWidth = wide
            ? (constraints.maxWidth < contentMaxWidth
                ? constraints.maxWidth
                : contentMaxWidth)
            : constraints.maxWidth;
        final cardWidth = wide ? (constrainedWidth - 24) / 2 : null;

        final panelBody = <Widget>[
          const SectionHeader(
            eyebrow: 'History',
            // App bar already says MISSION LOG — don’t repeat it here.
            title: 'Recent sessions',
            subtitle:
                'Chronological record of missions you have completed, newest first.',
          ),
          const SizedBox(height: 16),
          if (recentSessions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'No missions logged yet. Start a mission and your history will appear here.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: KuglaColors.textMuted,
                      height: 1.45,
                    ),
              ),
            )
          else if (!wide)
            ...recentSessions.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SessionCard(session: session),
              ),
            )
          else
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                ...recentSessions.map(
                  (session) => SizedBox(
                    width: cardWidth,
                    child: _SessionCard(session: session),
                  ),
                ),
              ],
            ),
        ];

        final panel = Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.copyWith(
                  bodyMedium: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color: KuglaColors.fog,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                ),
          ),
          child: GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: panelBody,
            ),
          ),
        );

        return ListView(
          padding: adaptiveScreenPadding(context),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: panel,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  final GameMode mode;
  const _ModeChip(this.mode);

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (mode) {
      GameMode.dailyPulse => ('Daily Pulse', Icons.flash_on_rounded),
      GameMode.worldAtlas => ('World Atlas', Icons.public_rounded),
      GameMode.landmarkLock => ('Landmark Lock', Icons.terrain_rounded),
    };
    final color = kuglaModeColor(mode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final MissionSession session;

  const _SessionCard({required this.session});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _formattedDate {
    final d = session.completedAt;
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final score = session.totalScore;
    final countries = session.rounds.map((r) => r.country).toSet().toList();
    final avgDist = session.averageDistanceKm;

    final Color accent;
    final String tier;
    if (score >= 4000 * session.rounds.length) {
      accent = KuglaColors.success;
      tier = 'Sharp';
    } else if (score >= 2500 * session.rounds.length) {
      accent = KuglaColors.atlas;
      tier = 'Decent';
    } else {
      accent = KuglaColors.lilac;
      tier = 'Rough';
    }

    return Container(
      decoration: BoxDecoration(
        color: KuglaColors.panel.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KuglaColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score bar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: LinearProgressIndicator(
              value: (score / (5000 * session.rounds.length)).clamp(0.0, 1.0),
              minHeight: 4,
              color: accent,
              backgroundColor: KuglaColors.midnight,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$score pts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: accent,
                            ),
                      ),
                    ),
                    _ModeChip(session.gameMode),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        tier,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$_formattedDate  ·  ${session.rounds.length} rounds  ·  ${avgDist.toStringAsFixed(0)} km avg',
                  style: const TextStyle(
                      color: KuglaColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...countries.map(
                      (c) => Theme(
                        data: Theme.of(context).copyWith(
                          chipTheme: Theme.of(context).chipTheme.copyWith(
                                backgroundColor:
                                    KuglaColors.success.withValues(alpha: 0.08),
                              ),
                        ),
                        child: Chip(
                          avatar: const Icon(
                            Icons.public_rounded,
                            size: 14,
                            color: KuglaColors.success,
                          ),
                          label: Text(c),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                if (session.rounds.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...session.rounds.take(3).map(
                            (r) => Chip(
                              label: Text(
                                '${r.locationName}  ${r.distanceKm.toStringAsFixed(0)} km',
                              ),
                            ),
                          ),
                      if (session.rounds.length > 3)
                        Chip(
                          label: Text('+${session.rounds.length - 3} more'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
