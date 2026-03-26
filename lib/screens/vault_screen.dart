import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/app_state.dart';
import '../widgets/mission_widgets.dart';

class VaultScreen extends StatefulWidget {
  final AppSnapshot snapshot;

  const VaultScreen({super.key, required this.snapshot});

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
          title: 'Star Vault',
          subtitle:
              'Inspect achievement relics, route milestones, and unlock progress across the season.',
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
                      'Achievement collection',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(achievements.length, (index) {
                      final entry = achievements[index];
                      final selectedItem = index == _selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => setState(() => _selectedIndex = index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedItem
                                  ? entry.color.withValues(alpha:0.14)
                                  : KuglaColors.midnight,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selectedItem
                                    ? entry.color.withValues(alpha:0.6)
                                    : Colors.transparent,
                              ),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(entry.icon, color: entry.color),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 4),
                                      Text(entry.metricLabel,
                                          style: const TextStyle(
                                              color: KuglaColors.textMuted,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (entry.unlocked)
                                  const Icon(Icons.check_circle_rounded,
                                      size: 18, color: KuglaColors.success)
                                else
                                  Text(
                                    '${(entry.progress * 100).round()}%',
                                    style: TextStyle(
                                      color: entry.color,
                                      fontWeight: FontWeight.w700,
                                    ),
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
                            color: selected.color.withValues(alpha:0.16),
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
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              if (selected.unlocked)
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 14, color: KuglaColors.success),
                                    SizedBox(width: 4),
                                    Text('Unlocked',
                                        style: TextStyle(
                                            color: KuglaColors.success,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                  ],
                                )
                              else
                                Text(selected.metricLabel,
                                    style: const TextStyle(
                                        color: KuglaColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      selected.description,
                      style: const TextStyle(
                          color: KuglaColors.textMuted, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 12,
                        value: selected.progress,
                        backgroundColor: KuglaColors.midnight,
                        color: selected.unlocked
                            ? KuglaColors.success
                            : selected.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      selected.unlocked
                          ? 'Complete!'
                          : '${(selected.progress * 100).round()}% complete',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            );

            return compact
                ? Column(
                    children: [collection, const SizedBox(height: 12), detail])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    collection,
                    const SizedBox(width: 12),
                    detail,
                  ]);
          },
        ),
      ],
    );
  }
}
