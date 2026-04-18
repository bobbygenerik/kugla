import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/app_state.dart';
import 'flutter_test_mode_io.dart'
    if (dart.library.html) 'flutter_test_mode_web.dart';

class RemoteSyncService {
  bool _initialized = false;
  bool _enabled = false;
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  late String _clientId;

  bool get isEnabled => _enabled;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // `flutter test` sets FLUTTER_TEST; Firebase plugins can hang without native
    // mocks, so skip remote entirely in that harness.
    if (runningInFlutterTest) {
      _enabled = false;
      return;
    }

    const enabled = bool.fromEnvironment('FIREBASE_ENABLED', defaultValue: true);
    if (!enabled) {
      _enabled = false;
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final prefs = await SharedPreferences.getInstance();
      _clientId = prefs.getString('remote_client_id_v1') ??
          DateTime.now().microsecondsSinceEpoch.toString();
      await prefs.setString('remote_client_id_v1', _clientId);
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      if (_auth!.currentUser == null) {
        try {
          await _auth!.signInAnonymously();
        } catch (_) {}
      }
      _enabled = true;
    } catch (_) {
      _enabled = false;
    }
  }

  Stream<List<RemoteLeaderboardEntry>> watchLeaderboard(String familyCode) {
    if (!_enabled || familyCode.trim().isEmpty) {
      return const Stream<List<RemoteLeaderboardEntry>>.empty();
    }

    return _firestore!
        .collection('groups')
        .doc(_normalizedFamilyCode(familyCode))
        .collection('members')
        .orderBy('bestSessionScore', descending: true)
        .orderBy('updatedAt', descending: false)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return RemoteLeaderboardEntry(
            userId: doc.id,
            displayName: data['displayName'] as String? ?? 'Unknown',
            familyCode: data['familyCode'] as String? ?? '',
            bestSessionScore: data['bestSessionScore'] as int? ?? 0,
            bestDailyPulseScore: data['bestDailyPulseScore'] as int? ?? 0,
            bestWorldAtlasScore: data['bestWorldAtlasScore'] as int? ?? 0,
            bestLandmarkLockScore: data['bestLandmarkLockScore'] as int? ?? 0,
            totalScore: data['totalScore'] as int? ?? 0,
            missionsPlayed: data['missionsPlayed'] as int? ?? 0,
            roundsPlayed: data['roundsPlayed'] as int? ?? 0,
            averageRoundScore: (data['averageRoundScore'] as num?)?.toDouble() ?? 0,
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
          );
        }).toList();
      },
    );
  }

  Future<void> syncProfile({
    required AppSettings settings,
    required AppSnapshot snapshot,
  }) async {
    if (!_enabled) return;
    final trimmedName = settings.displayName.trim();
    final normalizedCode = _normalizedFamilyCode(settings.familyCode);
    if (trimmedName.isEmpty || normalizedCode.isEmpty) return;

    final uid = _auth?.currentUser?.uid ?? _clientId;
    final memberData = {
      'userId': uid,
      'displayName': trimmedName,
      'familyCode': normalizedCode,
      'bestSessionScore': snapshot.bestSessionScore,
      'bestDailyPulseScore':
          snapshot.bestSessionScoreForMode(GameMode.dailyPulse),
      'bestWorldAtlasScore':
          snapshot.bestSessionScoreForMode(GameMode.worldAtlas),
      'bestLandmarkLockScore':
          snapshot.bestSessionScoreForMode(GameMode.landmarkLock),
      'totalScore': snapshot.totalScore,
      'missionsPlayed': snapshot.totalSessions,
      'roundsPlayed': snapshot.totalRounds,
      'averageRoundScore': snapshot.averageRoundScore,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore!.collection('users').doc(uid).set({
      ...memberData,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore!
        .collection('groups')
        .doc(normalizedCode)
        .collection('members')
        .doc(uid)
        .set(memberData, SetOptions(merge: true));
  }

  Future<void> syncMission({
    required AppSettings settings,
    required AppSnapshot snapshot,
    required MissionSession session,
  }) async {
    if (!_enabled) return;
    final trimmedName = settings.displayName.trim();
    final normalizedCode = _normalizedFamilyCode(settings.familyCode);
    if (trimmedName.isEmpty || normalizedCode.isEmpty) return;

    final uid = _auth?.currentUser?.uid ?? _clientId;
    await syncProfile(settings: settings, snapshot: snapshot);

    final missionData = {
      'userId': uid,
      'displayName': trimmedName,
      'familyCode': normalizedCode,
      'sessionId': session.id,
      'startedAt': Timestamp.fromDate(session.startedAt),
      'completedAt': Timestamp.fromDate(session.completedAt),
      'totalScore': session.totalScore,
      'averageRoundScore': session.averageScore,
      'averageDistanceKm': session.averageDistanceKm,
      'roundCount': session.rounds.length,
      'rounds': session.rounds.map((round) => round.toJson()).toList(),
    };

    await _firestore!
        .collection('groups')
        .doc(normalizedCode)
        .collection('missions')
        .doc('${uid}_${session.id}')
        .set(missionData, SetOptions(merge: true));
  }
}

String _normalizedFamilyCode(String familyCode) {
  return familyCode.trim().toUpperCase();
}
