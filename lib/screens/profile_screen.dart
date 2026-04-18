import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme.dart';
import '../models/app_state.dart';
import '../widgets/kugla_map_backdrop.dart';
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
  final _picker = ImagePicker();
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

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() => _settings = _settings.copyWith(avatarPath: file.path));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KuglaColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: KuglaColors.cyan),
              title: const Text('Choose from library'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: KuglaColors.cyan),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _persist() async {
    final nextSettings = _settings.copyWith(
      displayName: _displayNameController.text.trim(),
      familyCode: _familyCodeController.text.trim().toUpperCase(),
      avatarPath: _settings.avatarPath,
    );
    setState(() => _saving = true);
    final updated = await widget.onSave(nextSettings);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final name = _settings.displayName.trim();
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const KuglaMapBackdrop(),
          LayoutBuilder(
            builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final profileHeader = GlassPanel(
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [KuglaColors.pulse, KuglaColors.rose],
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _settings.avatarPath != null
                            ? Image.file(
                                File(_settings.avatarPath!),
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.person_rounded,
                                color: KuglaColors.deepSpace, size: 34),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: KuglaColors.cyan,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: KuglaColors.panel, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 11, color: KuglaColors.deepSpace),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Pilot' : name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.flag_rounded,
                                size: 14, color: KuglaColors.cyan),
                            label: Text('${snapshot.totalSessions} missions'),
                          ),
                          Chip(
                            avatar: const Icon(
                                Icons.local_fire_department_rounded,
                                size: 14,
                                color: KuglaColors.pulse),
                            label: Text(
                              snapshot.currentStreakDays == 0
                                  ? 'No streak'
                                  : '${snapshot.currentStreakDays}d streak',
                            ),
                          ),
                          Chip(
                            avatar: const Icon(Icons.public_rounded,
                                size: 14, color: KuglaColors.success),
                            label:
                                Text('${snapshot.exploredCountries} countries'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final familySection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        hintText: 'e.g. Bobby or Dad',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _familyCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Family code',
                        hintText: 'e.g. KUGLAFAM',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Use the same family code on both phones to share a private leaderboard.',
                      style: TextStyle(color: KuglaColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          );

          final gameplaySection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      onChanged: (value) => setState(
                          () => _settings =
                              _settings.copyWith(showStreetNames: value)),
                      title: const Text('Show street names'),
                      subtitle:
                          const Text('Toggle road labels during missions.'),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _settings.allowMovement,
                      onChanged: (value) => setState(
                          () => _settings =
                              _settings.copyWith(allowMovement: value)),
                      title: const Text('Allow movement'),
                      subtitle: const Text(
                          'Enable walking to adjacent panoramas.'),
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
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text('${_settings.roundsPerMission} rounds'),
                    Slider(
                      min: kMinRoundsPerMission.toDouble(),
                      max: kMaxRoundsPerMission.toDouble(),
                      divisions: kMaxRoundsPerMission - kMinRoundsPerMission,
                      label: '${_settings.roundsPerMission}',
                      value: _settings.roundsPerMission.toDouble(),
                      onChanged: (value) => setState(
                        () => _settings = _settings.copyWith(
                            roundsPerMission: value.round()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final statsSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                accent: KuglaColors.cyan,
              ),
              const SizedBox(height: 12),
              TelemetryTile(
                label: 'Average distance',
                value: snapshot.totalRounds == 0
                    ? '--'
                    : '${snapshot.averageDistanceKm.toStringAsFixed(0)} km',
                icon: Icons.pin_drop_rounded,
                accent: KuglaColors.fog,
              ),
            ],
          );

          return ListView(
            padding: adaptiveScreenPadding(context),
            children: [
              profileHeader,
              const SizedBox(height: 24),
              if (!wide) ...[
                familySection,
                const SizedBox(height: 24),
                gameplaySection,
                const SizedBox(height: 24),
                statsSection,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          familySection,
                          const SizedBox(height: 24),
                          statsSection,
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 7,
                      child: gameplaySection,
                    ),
                  ],
                ),
            ],
          );
            },
          ),
        ],
      ),
    );
  }
}
