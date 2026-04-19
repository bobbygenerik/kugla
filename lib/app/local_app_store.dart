import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_state.dart';

class LocalAppStore {
  static const _settingsKey = 'app_settings_v1';
  static const _sessionsKey = 'mission_sessions_v1';

  Future<AppSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsRaw = prefs.getString(_settingsKey);
    final sessionsRaw = prefs.getString(_sessionsKey);

    final settings = settingsRaw == null || settingsRaw.isEmpty
        ? const AppSettings.defaults()
        : AppSettings.fromJson(jsonDecode(settingsRaw) as Map<String, dynamic>);
    final sessions = decodeSessions(sessionsRaw)
        .map(MissionSession.fromJson)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return AppSnapshot(settings: settings, sessions: sessions);
  }

  Future<AppSnapshot> saveSettings(AppSnapshot snapshot, AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    return snapshot.copyWith(settings: settings);
  }

  Future<AppSnapshot> addSession(AppSnapshot snapshot, MissionSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = [session, ...snapshot.sessions]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    await prefs.setString(_sessionsKey, encodeSessions(sessions));
    return snapshot.copyWith(sessions: sessions);
  }

  static const _onboardingKey = 'has_seen_onboarding_v1';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}
