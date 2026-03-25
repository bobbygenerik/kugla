import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../widgets/mission_widgets.dart';

class VaultScreen extends StatefulWidget {
  final AppSnapshot snapshot;

  const VaultScreen({
    super.key,
    required this.snapshot,
  });

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final achievements = widget.snapshot.achievements;
    final selected = achievements[_selectedIndex];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        const SectionHeader(
          eyebrow: 'Vault',
          title: 'Achievement vault',
          subtitle:
              'Unlocks here are computed from your real missions, not from sample data.',
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            final collection = Expanded(
              flex: compact ? 0 : 5,
              child: GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievements',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(achievements.length, (index) {
                      final achievement = achievements[index];
                      final selectedItem = index == _selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => setState(() => _selectedIndex = index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedItem
                                  ? achievement.color.withValues(alpha: 0.14)
                                  : const Color(0xFF0D1B2F),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selectedItem
                                    ? achievement.color.withValues(alpha: 0.6)
                                    : Colors.transparent,
                              ),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(achievement.icon, color: achievement.color),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        achievement.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(achievement.metricLabel),
                                    ],
                                  ),
                                ),
                                Icon(
                                  achievement.unlocked
                                      ? Icons.lock_open_rounded
                                      : Icons.lock_outline_rounded,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );

            final detail = Expanded(
              flex: 6,
              child: GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: selected.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(selected.icon, color: selected.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(selected.description),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 12,
                        value: selected.progress,
                        backgroundColor: const Color(0xFF0D1B2F),
                        color: selected.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      selected.metricLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 18),
                    TelemetryTile(
                      label: 'Status',
                      value: selected.unlocked ? 'Unlocked' : 'In progress',
                      icon: selected.unlocked
                          ? Icons.verified_rounded
                          : Icons.timelapse_rounded,
                      accent: selected.color,
                    ),
                  ],
                ),
              ),
            );

            return compact
                ? Column(
                    children: [collection, const SizedBox(height: 12), detail],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      collection,
                      const SizedBox(width: 12),
                      detail,
                    ],
                  );
          },
        ),
      ],
    );
  }
}
