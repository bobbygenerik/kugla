import 'dart:convert';

import 'package:flutter/material.dart';

class AppSettings {
  final String displayName;
  final String familyCode;
  final bool showStreetNames;
  final bool allowMovement;
  final int roundsPerMission;

  const AppSettings({
    required this.displayName,
    required this.familyCode,
    required this.showStreetNames,
    required this.allowMovement,
    required this.roundsPerMission,
  });

  const AppSettings.defaults()
      : displayName = '',
        familyCode = '',
        showStreetNames = false,
        allowMovement = true,
        roundsPerMission = 3;

  AppSettings copyWith({
    String? displayName,
    String? familyCode,
    bool? showStreetNames,
    bool? allowMovement,
    int? roundsPerMission,
  }) {
    return AppSettings(
      displayName: displayName ?? this.displayName,
      familyCode: familyCode ?? this.familyCode,
      showStreetNames: showStreetNames ?? this.showStreetNames,
      allowMovement: allowMovement ?? this.allowMovement,
      roundsPerMission: roundsPerMission ?? this.roundsPerMission,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'familyCode': familyCode,
        'showStreetNames': showStreetNames,
        'allowMovement': allowMovement,
        'roundsPerMission': roundsPerMission,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      displayName: json['displayName'] as String? ?? '',
      familyCode: json['familyCode'] as String? ?? '',
      showStreetNames: json['showStreetNames'] as bool? ?? false,
      allowMovement: json['allowMovement'] as bool? ?? true,
      roundsPerMission: json['roundsPerMission'] as int? ?? 3,
    );
  }
}

class RemoteLeaderboardEntry {
  final String userId;
  final String displayName;
  final String familyCode;
  final int bestSessionScore;
  final int bestDailyPulseScore;
  final int bestWorldAtlasScore;
  final int bestLandmarkLockScore;
  final int totalScore;
  final int missionsPlayed;
  final int roundsPlayed;
  final double averageRoundScore;
  final DateTime? updatedAt;

  const RemoteLeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.familyCode,
    required this.bestSessionScore,
    this.bestDailyPulseScore = 0,
    this.bestWorldAtlasScore = 0,
    this.bestLandmarkLockScore = 0,
    required this.totalScore,
    required this.missionsPlayed,
    required this.roundsPlayed,
    required this.averageRoundScore,
    required this.updatedAt,
  });

  int bestScoreForMode(GameMode? mode) => switch (mode) {
        GameMode.dailyPulse => bestDailyPulseScore,
        GameMode.worldAtlas => bestWorldAtlasScore,
        GameMode.landmarkLock => bestLandmarkLockScore,
        null => bestSessionScore,
      };
}

class LocationSeed {
  final String id;
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final String clue;

  const LocationSeed({
    required this.id,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.clue,
  });
}

class RoundResult {
  final String locationId;
  final String locationName;
  final String country;
  final double targetLatitude;
  final double targetLongitude;
  final double guessLatitude;
  final double guessLongitude;
  final double distanceKm;
  final int score;
  final DateTime playedAt;

  const RoundResult({
    required this.locationId,
    required this.locationName,
    required this.country,
    required this.targetLatitude,
    required this.targetLongitude,
    required this.guessLatitude,
    required this.guessLongitude,
    required this.distanceKm,
    required this.score,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
        'locationId': locationId,
        'locationName': locationName,
        'country': country,
        'targetLatitude': targetLatitude,
        'targetLongitude': targetLongitude,
        'guessLatitude': guessLatitude,
        'guessLongitude': guessLongitude,
        'distanceKm': distanceKm,
        'score': score,
        'playedAt': playedAt.toIso8601String(),
      };

  factory RoundResult.fromJson(Map<String, dynamic> json) {
    return RoundResult(
      locationId: json['locationId'] as String,
      locationName: json['locationName'] as String,
      country: json['country'] as String,
      targetLatitude: (json['targetLatitude'] as num).toDouble(),
      targetLongitude: (json['targetLongitude'] as num).toDouble(),
      guessLatitude: (json['guessLatitude'] as num).toDouble(),
      guessLongitude: (json['guessLongitude'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      score: json['score'] as int,
      playedAt: DateTime.parse(json['playedAt'] as String),
    );
  }
}

class MissionSession {
  final String id;
  final DateTime startedAt;
  final DateTime completedAt;
  final List<RoundResult> rounds;
  final GameMode gameMode;

  const MissionSession({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.rounds,
    this.gameMode = GameMode.worldAtlas,
  });

  int get totalScore => rounds.fold(0, (sum, round) => sum + round.score);
  double get averageScore =>
      rounds.isEmpty ? 0 : totalScore / rounds.length.toDouble();
  double get averageDistanceKm => rounds.isEmpty
      ? 0
      : rounds.fold(0.0, (sum, round) => sum + round.distanceKm) /
          rounds.length.toDouble();
  RoundResult? get bestRound => rounds.isEmpty
      ? null
      : rounds.reduce((a, b) => a.score >= b.score ? a : b);

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'rounds': rounds.map((round) => round.toJson()).toList(),
        'gameMode': gameMode.name,
      };

  factory MissionSession.fromJson(Map<String, dynamic> json) {
    return MissionSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      rounds: (json['rounds'] as List<dynamic>)
          .map((item) => RoundResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      gameMode: GameMode.values.firstWhere(
        (e) => e.name == (json['gameMode'] as String?),
        orElse: () => GameMode.worldAtlas,
      ),
    );
  }
}

class AchievementProgress {
  final String title;
  final String description;
  final String metricLabel;
  final double progress;
  final bool unlocked;
  final IconData icon;
  final Color color;

  const AchievementProgress({
    required this.title,
    required this.description,
    required this.metricLabel,
    required this.progress,
    required this.unlocked,
    required this.icon,
    required this.color,
  });
}

class AppSnapshot {
  final AppSettings settings;
  final List<MissionSession> sessions;

  const AppSnapshot({
    required this.settings,
    required this.sessions,
  });

  const AppSnapshot.empty()
      : settings = const AppSettings.defaults(),
        sessions = const [];

  AppSnapshot copyWith({
    AppSettings? settings,
    List<MissionSession>? sessions,
  }) {
    return AppSnapshot(
      settings: settings ?? this.settings,
      sessions: sessions ?? this.sessions,
    );
  }

  bool get hasSessions => sessions.isNotEmpty;
  int get totalSessions => sessions.length;
  int get totalRounds =>
      sessions.fold(0, (sum, session) => sum + session.rounds.length);
  int get totalScore =>
      sessions.fold(0, (sum, session) => sum + session.totalScore);
  double get averageRoundScore =>
      totalRounds == 0 ? 0 : totalScore / totalRounds.toDouble();
  double get averageDistanceKm {
    if (totalRounds == 0) return 0;
    final totalDistance = sessions.fold<double>(
      0,
      (sum, session) =>
          sum +
          session.rounds.fold(0, (inner, round) => inner + round.distanceKm),
    );
    return totalDistance / totalRounds.toDouble();
  }

  int get bestSessionScore => sessions.isEmpty
      ? 0
      : sessions
          .map((session) => session.totalScore)
          .reduce((a, b) => a > b ? a : b);

  int bestSessionScoreForMode(GameMode mode) {
    final modeSessions =
        sessions.where((s) => s.gameMode == mode).toList();
    if (modeSessions.isEmpty) return 0;
    return modeSessions
        .map((s) => s.totalScore)
        .reduce((a, b) => a > b ? a : b);
  }

  double get closestGuessKm {
    if (sessions.isEmpty || totalRounds == 0) return 0;
    return sessions
        .expand((session) => session.rounds)
        .map((round) => round.distanceKm)
        .reduce((a, b) => a < b ? a : b);
  }

  int get exploredCountries => sessions
      .expand((session) => session.rounds)
      .map((round) => round.country)
      .toSet()
      .length;

  MissionSession? get latestSession => sessions.isEmpty
      ? null
      : sessions.reduce((a, b) => a.completedAt.isAfter(b.completedAt) ? a : b);

  List<MissionSession> get recentSessions {
    final copy = [...sessions];
    copy.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return copy;
  }

  List<MissionSession> get bestSessions {
    final copy = [...sessions];
    copy.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return copy;
  }

  int get currentStreakDays {
    if (sessions.isEmpty) return 0;
    final localDates = sessions
        .map((session) => DateTime(
              session.completedAt.year,
              session.completedAt.month,
              session.completedAt.day,
            ))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    for (final date in localDates) {
      if (date == cursor) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (date == cursor.subtract(const Duration(days: 1)) &&
          streak == 0) {
        streak++;
        cursor = date.subtract(const Duration(days: 1));
      } else if (date != cursor) {
        break;
      }
    }
    return streak;
  }

  List<AchievementProgress> get achievements {
    final totalPerfectishRounds = sessions
        .expand((session) => session.rounds)
        .where((round) => round.distanceKm <= 50)
        .length;
    final eliteSessions =
        sessions.where((session) => session.averageScore >= 3500).length;

    return [
      AchievementProgress(
        title: 'First Landing',
        description: 'Complete your first mission.',
        metricLabel: '$totalSessions / 1 missions',
        progress: _ratio(totalSessions, 1),
        unlocked: totalSessions >= 1,
        icon: Icons.rocket_launch_rounded,
        color: const Color(0xFF61E6E8),
      ),
      AchievementProgress(
        title: 'Sharp Eye',
        description: 'Finish 3 rounds within 50 km.',
        metricLabel: '$totalPerfectishRounds / 3 close guesses',
        progress: _ratio(totalPerfectishRounds, 3),
        unlocked: totalPerfectishRounds >= 3,
        icon: Icons.track_changes_rounded,
        color: const Color(0xFFFFC86B),
      ),
      AchievementProgress(
        title: 'Road Warrior',
        description: 'Play 10 total rounds.',
        metricLabel: '$totalRounds / 10 rounds',
        progress: _ratio(totalRounds, 10),
        unlocked: totalRounds >= 10,
        icon: Icons.route_rounded,
        color: const Color(0xFFB6A9FF),
      ),
      AchievementProgress(
        title: 'World Sampler',
        description: 'Visit 6 different countries across missions.',
        metricLabel: '$exploredCountries / 6 countries',
        progress: _ratio(exploredCountries, 6),
        unlocked: exploredCountries >= 6,
        icon: Icons.public_rounded,
        color: const Color(0xFF87F0A2),
      ),
      AchievementProgress(
        title: 'Steady Navigator',
        description: 'Post an average session score of 3,500 or more twice.',
        metricLabel: '$eliteSessions / 2 strong sessions',
        progress: _ratio(eliteSessions, 2),
        unlocked: eliteSessions >= 2,
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFF7AB6FF),
      ),
    ];
  }
}

double _ratio(int value, int target) {
  if (target <= 0) return 0;
  final ratio = value / target;
  return ratio.clamp(0, 1).toDouble();
}

List<Map<String, dynamic>> decodeSessions(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
}

String encodeSessions(List<MissionSession> sessions) {
  return jsonEncode(sessions.map((session) => session.toJson()).toList());
}

enum GameMode { dailyPulse, worldAtlas, landmarkLock }

const landmarkSeeds = <LocationSeed>[
  LocationSeed(
    id: 'eiffel_tower',
    name: 'Eiffel Tower',
    country: 'France',
    latitude: 48.8584,
    longitude: 2.2945,
    clue: 'An iron lattice tower on the Champ de Mars, overlooking a European capital on the Seine.',
  ),
  LocationSeed(
    id: 'colosseum',
    name: 'Colosseum',
    country: 'Italy',
    latitude: 41.8902,
    longitude: 12.4922,
    clue: 'An ancient oval amphitheatre of volcanic stone in the heart of an imperial city.',
  ),
  LocationSeed(
    id: 'taj_mahal',
    name: 'Taj Mahal',
    country: 'India',
    latitude: 27.1751,
    longitude: 78.0421,
    clue: 'A white marble mausoleum on a river in northern India, flanked by four minarets.',
  ),
  LocationSeed(
    id: 'sydney_opera_house',
    name: 'Sydney Opera House',
    country: 'Australia',
    latitude: -33.8568,
    longitude: 151.2153,
    clue: 'Shell-shaped roof forms on a harbour peninsula in a major southern-hemisphere city.',
  ),
  LocationSeed(
    id: 'sagrada_familia',
    name: 'Sagrada Família',
    country: 'Spain',
    latitude: 41.4036,
    longitude: 2.1744,
    clue: 'An unfinished Gothic-Art Nouveau basilica with towering organic spires in a Mediterranean port city.',
  ),
  LocationSeed(
    id: 'statue_of_liberty',
    name: 'Statue of Liberty',
    country: 'United States',
    latitude: 40.6892,
    longitude: -74.0445,
    clue: 'A neoclassical copper statue on a small island in a harbour at the mouth of a major estuary.',
  ),
  LocationSeed(
    id: 'golden_gate_bridge',
    name: 'Golden Gate Bridge',
    country: 'United States',
    latitude: 37.8199,
    longitude: -122.4783,
    clue: 'An International Orange suspension bridge spanning the entrance to a Pacific coast bay.',
  ),
  LocationSeed(
    id: 'big_ben',
    name: 'Palace of Westminster',
    country: 'United Kingdom',
    latitude: 51.5007,
    longitude: -0.1246,
    clue: 'A Gothic Revival parliament complex beside a tidal river in the capital of a northern island nation.',
  ),
];

const streetViewSeeds = <LocationSeed>[
  LocationSeed(
    id: 'us_residential_grid',
    name: 'Residential grid',
    country: 'United States',
    latitude: 41.5943,
    longitude: -93.6157,
    clue: 'Detached homes, wide streets, and North American road geometry.',
  ),
  LocationSeed(
    id: 'canada_suburb',
    name: 'Suburban arterial',
    country: 'Canada',
    latitude: 45.4211,
    longitude: -75.6903,
    clue: 'A tidy northern streetscape with broad lanes and familiar road markings.',
  ),
  LocationSeed(
    id: 'uk_row_houses',
    name: 'Terraced street',
    country: 'United Kingdom',
    latitude: 53.4806,
    longitude: -2.2426,
    clue: 'Compact streets, older brick housing, and left-side driving.',
  ),
  LocationSeed(
    id: 'france_roundabout_edge',
    name: 'Town edge road',
    country: 'France',
    latitude: 48.5730,
    longitude: 7.7520,
    clue: 'European lane markings and roadside design near a built-up area.',
  ),
  LocationSeed(
    id: 'italy_neighborhood',
    name: 'Neighborhood street',
    country: 'Italy',
    latitude: 45.4640,
    longitude: 9.1895,
    clue: 'Tight streets, close-set buildings, and southern European urban density.',
  ),
  LocationSeed(
    id: 'spain_mixed_block',
    name: 'Mixed-use block',
    country: 'Spain',
    latitude: 39.4702,
    longitude: -0.3768,
    clue: 'Warm-weather city blocks with balconies, signage, and narrower streets.',
  ),
  LocationSeed(
    id: 'japan_side_street',
    name: 'Side street',
    country: 'Japan',
    latitude: 35.6899,
    longitude: 139.7006,
    clue: 'Dense East Asian streets with compact buildings and frequent overhead wiring.',
  ),
  LocationSeed(
    id: 'australia_local_road',
    name: 'Local road',
    country: 'Australia',
    latitude: -37.8138,
    longitude: 144.9690,
    clue: 'Southern Hemisphere road layout with left-side driving and low-rise streets.',
  ),
  LocationSeed(
    id: 'new_zealand_suburban',
    name: 'Suburban street',
    country: 'New Zealand',
    latitude: -41.2862,
    longitude: 174.7762,
    clue: 'Oceanic suburb feel with left-side driving and hilly residential streets.',
  ),
  LocationSeed(
    id: 'brazil_avenue',
    name: 'Urban avenue',
    country: 'Brazil',
    latitude: -23.5508,
    longitude: -46.6333,
    clue: 'Busy South American city fabric with Portuguese-looking signage and dense traffic.',
  ),
  LocationSeed(
    id: 'mexico_neighborhood',
    name: 'Neighborhood corner',
    country: 'Mexico',
    latitude: 20.6734,
    longitude: -103.3442,
    clue: 'A high-activity Latin American street with compact storefronts and utility lines.',
  ),
  LocationSeed(
    id: 'south_africa_residential',
    name: 'Residential road',
    country: 'South Africa',
    latitude: -26.2047,
    longitude: 28.0462,
    clue: 'Sunny neighborhood streets with left-side driving and a suburban layout.',
  ),
  LocationSeed(
    id: 'chile_city_slope',
    name: 'City slope',
    country: 'Chile',
    latitude: -33.4483,
    longitude: -70.6693,
    clue: 'A drier urban setting with hills, mixed low-rise buildings, and Spanish signage.',
  ),
  LocationSeed(
    id: 'ireland_small_town',
    name: 'Town road',
    country: 'Ireland',
    latitude: 53.3496,
    longitude: -6.2603,
    clue: 'Left-side driving, modest storefronts, and a damp Atlantic-town feel.',
  ),
];
