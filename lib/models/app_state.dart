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
    required this.totalScore,
    required this.missionsPlayed,
    required this.roundsPlayed,
    required this.averageRoundScore,
    required this.updatedAt,
  });
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

  const MissionSession({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.rounds,
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
      };

  factory MissionSession.fromJson(Map<String, dynamic> json) {
    return MissionSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      rounds: (json['rounds'] as List<dynamic>)
          .map((item) => RoundResult.fromJson(item as Map<String, dynamic>))
          .toList(),
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
          sum + session.rounds.fold(0, (inner, round) => inner + round.distanceKm),
    );
    return totalDistance / totalRounds.toDouble();
  }

  int get bestSessionScore => sessions.isEmpty
      ? 0
      : sessions.map((session) => session.totalScore).reduce((a, b) => a > b ? a : b);

  double get closestGuessKm {
    if (sessions.isEmpty || totalRounds == 0) return 0;
    return sessions
        .expand((session) => session.rounds)
        .map((round) => round.distanceKm)
        .reduce((a, b) => a < b ? a : b);
  }

  int get exploredCountries =>
      sessions.expand((session) => session.rounds).map((round) => round.country).toSet().length;

  MissionSession? get latestSession =>
      sessions.isEmpty ? null : sessions.reduce((a, b) => a.completedAt.isAfter(b.completedAt) ? a : b);

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
      } else if (date == cursor.subtract(const Duration(days: 1)) && streak == 0) {
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
    final eliteSessions = sessions.where((session) => session.averageScore >= 3500).length;

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
  return (jsonDecode(raw) as List<dynamic>)
      .cast<Map<String, dynamic>>();
}

String encodeSessions(List<MissionSession> sessions) {
  return jsonEncode(sessions.map((session) => session.toJson()).toList());
}

const streetViewSeeds = <LocationSeed>[
  LocationSeed(
    id: 'golden_gate',
    name: 'Golden Gate Bridge',
    country: 'United States',
    latitude: 37.8199,
    longitude: -122.4783,
    clue: 'Coastal city with an iconic red bridge.',
  ),
  LocationSeed(
    id: 'times_square',
    name: 'Times Square',
    country: 'United States',
    latitude: 40.7580,
    longitude: -73.9855,
    clue: 'Dense billboards and Manhattan traffic.',
  ),
  LocationSeed(
    id: 'eiffel',
    name: 'Eiffel Tower',
    country: 'France',
    latitude: 48.8584,
    longitude: 2.2945,
    clue: 'A major European monument by the Seine.',
  ),
  LocationSeed(
    id: 'rome_colosseum',
    name: 'Colosseum',
    country: 'Italy',
    latitude: 41.8902,
    longitude: 12.4922,
    clue: 'Ancient stone arena in southern Europe.',
  ),
  LocationSeed(
    id: 'tokyo_crossing',
    name: 'Shibuya Crossing',
    country: 'Japan',
    latitude: 35.6595,
    longitude: 139.7005,
    clue: 'A neon-heavy crossing in a dense Japanese city.',
  ),
  LocationSeed(
    id: 'sydney_opera',
    name: 'Sydney Opera House',
    country: 'Australia',
    latitude: -33.8568,
    longitude: 151.2153,
    clue: 'Harbor views and famous sail-shaped architecture.',
  ),
  LocationSeed(
    id: 'table_mountain',
    name: 'Table Mountain',
    country: 'South Africa',
    latitude: -33.9628,
    longitude: 18.4098,
    clue: 'A flat-topped mountain above a southern coastal city.',
  ),
  LocationSeed(
    id: 'rio_copacabana',
    name: 'Copacabana',
    country: 'Brazil',
    latitude: -22.9711,
    longitude: -43.1822,
    clue: 'Palm-lined beachfront in a major South American city.',
  ),
  LocationSeed(
    id: 'reykjavik_harpa',
    name: 'Harpa Concert Hall',
    country: 'Iceland',
    latitude: 64.1500,
    longitude: -21.9326,
    clue: 'A glass waterfront venue in a Nordic capital.',
  ),
  LocationSeed(
    id: 'mexico_city_zocalo',
    name: 'Zocalo',
    country: 'Mexico',
    latitude: 19.4326,
    longitude: -99.1332,
    clue: 'Historic plaza in a high-altitude Latin American capital.',
  ),
];
