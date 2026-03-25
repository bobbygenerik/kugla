import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../screens/game_screen.dart';
import '../screens/home_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/social_screen.dart';
import '../screens/vault_screen.dart';
import '../widgets/kugla_shell.dart';
import 'local_app_store.dart';
import 'remote_sync_service.dart';
import 'theme.dart';

class KuglaApp extends StatelessWidget {
  const KuglaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kugla',
      debugShowCheckedModeBanner: false,
      theme: buildKuglaTheme(),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _store = LocalAppStore();
  final _remote = RemoteSyncService();

  int _selectedIndex = 0;
  AppSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _remote.initialize();
    final snapshot = await _store.load();
    if (_remote.isEnabled) {
      await _remote.syncProfile(settings: snapshot.settings, snapshot: snapshot);
    }
    if (!mounted) return;
    setState(() => _snapshot = snapshot);
  }

  void _setIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _openGame() async {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    final session = await Navigator.of(context).push<MissionSession>(
      MaterialPageRoute<MissionSession>(
        builder: (_) => GameScreen(settings: snapshot.settings),
      ),
    );
    if (!mounted || session == null) return;
    final updated = await _store.addSession(snapshot, session);
    if (_remote.isEnabled) {
      await _remote.syncMission(
        settings: updated.settings,
        snapshot: updated,
        session: session,
      );
    }
    if (!mounted) return;
    setState(() {
      _snapshot = updated;
      _selectedIndex = 1;
    });
  }

  void _openOnboarding() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
    );
  }

  Future<void> _openProfile() async {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    final settings = await Navigator.of(context).push<AppSettings>(
      MaterialPageRoute<AppSettings>(
        builder: (_) => ProfileSettingsScreen(
          snapshot: snapshot,
          onSave: (next) async => _store.saveSettings(snapshot, next),
        ),
      ),
    );
    if (!mounted || settings == null) return;
    final updated = snapshot.copyWith(settings: settings);
    if (_remote.isEnabled) {
      await _remote.syncProfile(settings: settings, snapshot: updated);
    }
    setState(() {
      _snapshot = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final destinations = [
      _ShellDestination(
        title: 'KUGLA',
        screen: HomeScreen(
          snapshot: snapshot,
          onStartMission: _openGame,
          onOpenVault: () => _setIndex(3),
          onOpenOnboarding: _openOnboarding,
          onOpenRecords: () => _setIndex(1),
        ),
      ),
      _ShellDestination(
        title: 'MISSION RECORDS',
        screen: LeaderboardScreen(
          snapshot: snapshot,
          remoteLeaderboard: _remote.watchLeaderboard(snapshot.settings.familyCode),
          remoteEnabled: _remote.isEnabled,
        ),
      ),
      _ShellDestination(
        title: 'MISSION LOG',
        screen: SocialScreen(snapshot: snapshot),
      ),
      _ShellDestination(
        title: 'STAR VAULT',
        screen: VaultScreen(snapshot: snapshot),
      ),
    ];

    final destination = destinations[_selectedIndex];

    return KuglaShell(
      title: destination.title,
      currentIndex: _selectedIndex,
      onNavTap: _setIndex,
      onOpenProfile: _openProfile,
      onOpenOnboarding: _openOnboarding,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: destination.screen,
        ),
      ),
    );
  }
}

class _ShellDestination {
  final String title;
  final Widget screen;

  const _ShellDestination({
    required this.title,
    required this.screen,
  });
}
