import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'app_state.dart';

class MissionMode {
  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final Color color;
  final GameMode gameMode;

  const MissionMode({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.color,
    required this.gameMode,
  });
}

const missionModes = <MissionMode>[
  MissionMode(
    title: 'Daily Pulse',
    subtitle: 'Timed expedition',
    detail: 'Five fresh drops, live telemetry, bonus streak multipliers.',
    icon: Icons.flash_on_rounded,
    color: KuglaColors.cyan,
    gameMode: GameMode.dailyPulse,
  ),
  MissionMode(
    title: 'World Atlas',
    subtitle: 'Classic roaming',
    detail: 'Unlimited practice across every supported region and biome.',
    icon: Icons.public_rounded,
    color: Color(0xFF7D9AAA),
    gameMode: GameMode.worldAtlas,
  ),
  MissionMode(
    title: 'Landmark Lock',
    subtitle: 'Precision route',
    detail: 'Famous places, tighter score windows, prestige badge rewards.',
    icon: Icons.terrain_rounded,
    color: KuglaColors.amber,
    gameMode: GameMode.landmarkLock,
  ),
];
