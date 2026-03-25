import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../widgets/mission_widgets.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final AppSnapshot snapshot;
  final Future<AppSnapshot> Function(AppSettings) onSave;

  const ProfileSettingsScreen({
    super.key,
    required this.snapshot,
    required this.onSave,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late AppSettings _settings;
  late final TextEditingController _displayNameController;
  late final TextEditingController _familyCodeController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.snapshot.settings;
    _displayNameController = TextEditingController(text: _settings.displayName);
    _familyCodeController = TextEditingController(text: _settings.familyCode);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _familyCodeController.dispose();
    super.dispose();
  }

  Future<void> _persist() async {
    final nextSettings = _settings.copyWith(
      displayName: _displayNameController.text.trim(),
      familyCode: _familyCodeController.text.trim().toUpperCase(),
    );
    setState(() => _saving = true);
    final updated = await widget.onSave(nextSettings);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(updated.settings);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _persist,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
        children: [
          GlassPanel(
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF61E6E8), Color(0xFFB6A9FF)],
                    ),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Color(0xFF08111F), size: 34),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _settings.displayName.trim().isEmpty
                            ? 'Local pilot'
                            : _settings.displayName.trim(),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${snapshot.totalSessions} missions completed • ${snapshot.totalRounds} rounds played',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text('Best ${snapshot.bestSessionScore}')),
                          Chip(label: Text('${snapshot.exploredCountries} countries')),
                          Chip(label: Text('${snapshot.currentStreakDays} day streak')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            eyebrow: 'Family',
            title: 'Shared leaderboard setup',
          ),
          const SizedBox(height: 12),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    hintText: 'Example: Bobby or Dad',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _familyCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Family code',
                    hintText: 'Example: KUGLAFAM',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Use the same family code on both phones to join the same private leaderboard.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            eyebrow: 'Gameplay',
            title: 'Mission settings',
          ),
          const SizedBox(height: 12),
          GlassPanel(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.showStreetNames,
                  onChanged: (value) =>
                      setState(() => _settings = _settings.copyWith(showStreetNames: value)),
                  title: const Text('Show street names'),
                  subtitle: const Text('Toggle road labels during missions.'),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.allowMovement,
                  onChanged: (value) =>
                      setState(() => _settings = _settings.copyWith(allowMovement: value)),
                  title: const Text('Allow movement'),
                  subtitle: const Text('Enable walking or panning to adjacent panoramas.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rounds per mission',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text('${_settings.roundsPerMission} rounds'),
                Slider(
                  min: 3,
                  max: 5,
                  divisions: 2,
                  label: '${_settings.roundsPerMission}',
                  value: _settings.roundsPerMission.toDouble(),
                  onChanged: (value) => setState(
                    () => _settings = _settings.copyWith(
                      roundsPerMission: value.round(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            eyebrow: 'Stats',
            title: 'Local record summary',
          ),
          const SizedBox(height: 12),
          TelemetryTile(
            label: 'Average round score',
            value: snapshot.totalRounds == 0
                ? '--'
                : snapshot.averageRoundScore.toStringAsFixed(0),
            icon: Icons.stacked_line_chart_rounded,
            accent: const Color(0xFF61E6E8),
          ),
          const SizedBox(height: 12),
          TelemetryTile(
            label: 'Average distance',
            value: snapshot.totalRounds == 0
                ? '--'
                : '${snapshot.averageDistanceKm.toStringAsFixed(0)} km',
            icon: Icons.pin_drop_rounded,
            accent: const Color(0xFFFFC86B),
          ),
        ],
      ),
    );
  }
}
