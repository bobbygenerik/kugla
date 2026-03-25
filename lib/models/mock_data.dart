import 'package:flutter/material.dart';

class MissionMode {
  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final Color color;

  const MissionMode({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

class AchievementEntry {
  final String title;
  final String category;
  final String description;
  final double progress;
  final IconData icon;
  final Color color;

  const AchievementEntry({
    required this.title,
    required this.category,
    required this.description,
    required this.progress,
    required this.icon,
    required this.color,
  });
}

class FriendProfile {
  final String name;
  final String status;
  final String specialty;
  final int streak;
  final int trophies;
  final bool online;

  const FriendProfile({
    required this.name,
    required this.status,
    required this.specialty,
    required this.streak,
    required this.trophies,
    required this.online,
  });
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final int score;
  final String region;
  final bool isUser;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.score,
    required this.region,
    this.isUser = false,
  });
}

const missionModes = <MissionMode>[
  MissionMode(
    title: 'Daily Pulse',
    subtitle: 'Timed expedition',
    detail: 'Five fresh drops, live telemetry, bonus streak multipliers.',
    icon: Icons.flash_on_rounded,
    color: Color(0xFF61E6E8),
  ),
  MissionMode(
    title: 'World Atlas',
    subtitle: 'Classic roaming',
    detail: 'Unlimited practice across every supported region and biome.',
    icon: Icons.public_rounded,
    color: Color(0xFF7AB6FF),
  ),
  MissionMode(
    title: 'Landmark Lock',
    subtitle: 'Precision route',
    detail: 'Famous places, tighter score windows, prestige badge rewards.',
    icon: Icons.terrain_rounded,
    color: Color(0xFFFFC86B),
  ),
];

const vaultEntries = <AchievementEntry>[
  AchievementEntry(
    title: 'Aurora Cartographer',
    category: 'Exploration',
    description: 'Score 4,500+ in three icy regions during one session.',
    progress: 0.84,
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFF61E6E8),
  ),
  AchievementEntry(
    title: 'Signal Hunter',
    category: 'Telemetry',
    description: 'Finish 20 daily missions while keeping a 90% accuracy rate.',
    progress: 0.56,
    icon: Icons.radar_rounded,
    color: Color(0xFFB6A9FF),
  ),
  AchievementEntry(
    title: 'Summit Witness',
    category: 'Landmarks',
    description: 'Correctly identify seven mountain landmarks without hints.',
    progress: 0.29,
    icon: Icons.landscape_rounded,
    color: Color(0xFFFFC86B),
  ),
];

const friendProfiles = <FriendProfile>[
  FriendProfile(
    name: 'Nova',
    status: 'In Daily Pulse',
    specialty: 'Urban reads',
    streak: 18,
    trophies: 152,
    online: true,
  ),
  FriendProfile(
    name: 'Atlas',
    status: 'Reviewing replays',
    specialty: 'Mountain roads',
    streak: 27,
    trophies: 211,
    online: true,
  ),
  FriendProfile(
    name: 'Lyra',
    status: 'Offline 2h ago',
    specialty: 'Coastal signage',
    streak: 11,
    trophies: 97,
    online: false,
  ),
];

const squadInvites = <String>[
  'Join a duo relay with Nova',
  'Atlas sent a replay challenge from Patagonia',
  'Weekly squad briefing unlocks in 3 hours',
];

const globalLeaders = <LeaderboardEntry>[
  LeaderboardEntry(rank: 1, name: 'Atlas', score: 1524000, region: 'NA'),
  LeaderboardEntry(rank: 2, name: 'Vega', score: 1499800, region: 'EU'),
  LeaderboardEntry(rank: 3, name: 'Sol', score: 1482100, region: 'APAC'),
  LeaderboardEntry(rank: 4, name: 'Nova', score: 1455300, region: 'NA'),
  LeaderboardEntry(rank: 5, name: 'Helio', score: 1439200, region: 'LATAM'),
  LeaderboardEntry(
      rank: 6, name: 'Pilot You', score: 1194000, region: 'NA', isUser: true),
];

const friendsLeaders = <LeaderboardEntry>[
  LeaderboardEntry(rank: 1, name: 'Nova', score: 1455300, region: 'Squad'),
  LeaderboardEntry(rank: 2, name: 'Atlas', score: 1439200, region: 'Squad'),
  LeaderboardEntry(
      rank: 3,
      name: 'Pilot You',
      score: 1194000,
      region: 'Squad',
      isUser: true),
  LeaderboardEntry(rank: 4, name: 'Lyra', score: 1112600, region: 'Squad'),
];
