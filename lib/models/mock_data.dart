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
    detail: 'Five timed rounds with daily seeding and bonus streak multipliers.',
    icon: Icons.flash_on_rounded,
    color: KuglaColors.amber,
    gameMode: GameMode.dailyPulse,
  ),
  MissionMode(
    title: 'World Atlas',
    subtitle: 'Classic roaming',
    detail: 'Flexible practice across the full location pool with your chosen round count.',
    icon: Icons.public_rounded,
    color: KuglaColors.cyan,
    gameMode: GameMode.worldAtlas,
  ),
  MissionMode(
    title: 'Landmark Lock',
    subtitle: 'Precision route',
    detail: 'Famous places with tighter score windows and more exact reads.',
    icon: Icons.terrain_rounded,
    color: KuglaColors.rose,
    gameMode: GameMode.landmarkLock,
  ),
];
