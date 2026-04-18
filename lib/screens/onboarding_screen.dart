import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/build_stamp.dart';
import '../app/theme.dart';
import '../models/app_state.dart';
import '../widgets/kugla_gradient_title.dart';
import '../widgets/kugla_shell_backdrop.dart';
import '../widgets/mission_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  /// When true a profile-setup page is appended to the info slides.
  final bool showProfileSetup;

  /// Called only when [showProfileSetup] is true and the user finishes.
  /// Receives the settings the user entered so the caller can persist them.
  final Future<void> Function(AppSettings)? onProfileSaved;

  /// The current settings to pre-fill the profile fields.
  final AppSettings initialSettings;

  const OnboardingScreen({
    super.key,
    this.showProfileSetup = false,
    this.onProfileSaved,
    this.initialSettings = const AppSettings.defaults(),
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  int _page = 0;
  String? _pickedAvatarPath;
  bool _saving = false;

  static const _infoPages = [
    (
      title: 'Treat every drop like a survey',
      body:
          'Signage, vegetation, road markings, and building style are all fair clues.',
      icon: Icons.travel_explore_rounded,
    ),
    (
      title: 'HUD stays out of your way',
      body:
          'Timer, streak, and score sit up top; the panorama stays the main event.',
      icon: Icons.radar_rounded,
    ),
    (
      title: 'Fill the vault over time',
      body:
          'Missions add to your history, badges, and the places you have pinned.',
      icon: Icons.auto_awesome_mosaic_rounded,
    ),
  ];

  int get _totalPages =>
      _infoPages.length + (widget.showProfileSetup ? 1 : 0);
  bool get _isLastPage => _page == _totalPages - 1;
  bool get _isProfilePage =>
      widget.showProfileSetup && _page == _infoPages.length;

  String get _eyebrowLabel {
    if (_isProfilePage) return 'PROFILE';
    return 'BRIEFING · ${_page + 1} OF ${_infoPages.length}';
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialSettings.displayName;
    _pickedAvatarPath = widget.initialSettings.avatarPath;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() => _pickedAvatarPath = file.path);
  }

  Future<void> _next() async {
    if (_isLastPage && _isProfilePage) {
      await _finish();
      return;
    }
    if (_isLastPage) {
      Navigator.of(context).pop();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final callback = widget.onProfileSaved;
    if (callback == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    final updated = widget.initialSettings.copyWith(
      displayName: _nameController.text.trim(),
      avatarPath: _pickedAvatarPath,
    );
    await callback(updated);
    if (!mounted) return;
    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hPad = w > 720 ? ((w - 680) / 2).clamp(20.0, 240.0) : 20.0;
    final contentPadding = adaptiveScreenPadding(
      context,
      includeFloatingNavReserve: false,
      top: 12,
    );

    return Scaffold(
      backgroundColor: KuglaColors.deepSpace,
      body: KuglaShellBackdrop(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: _OnboardingHeader(
                hPad: hPad,
                eyebrow: _eyebrowLabel,
                title: _isProfilePage ? 'Create Profile' : 'Mission Briefing',
                showTagline: !_isProfilePage,
                showSkip: !_isProfilePage,
                onSkip: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: contentPadding.copyWith(top: 8, bottom: 8),
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (v) => setState(() => _page = v),
                  itemCount: _totalPages,
                  itemBuilder: (context, index) {
                        if (widget.showProfileSetup &&
                            index == _infoPages.length) {
                          return _ProfileSetupPage(
                            nameController: _nameController,
                            avatarPath: _pickedAvatarPath,
                            onPickImage: _showImageSourceSheet,
                          );
                        }
                        final page = _infoPages[index];
                        return LayoutBuilder(
                          builder: (context, constraints) => Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
                              child: GlassPanel(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight - 16,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 92,
                                          height: 92,
                                          decoration: BoxDecoration(
                                            color: KuglaColors.cyan
                                                .withValues(alpha: 0.14),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(page.icon,
                                              size: 42,
                                              color: KuglaColors.cyanSoft),
                                        ),
                                        const SizedBox(height: 28),
                                        Text(
                                          page.title,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          page.body,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: KuglaColors.textMuted,
                                            fontSize: 16,
                                            height: 1.6,
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        const Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            Chip(
                                                label: Text(
                                                    'Street View expeditions')),
                                            Chip(
                                                label:
                                                    Text('Vault progression')),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                  },
                ),
              ),
            ),
            Padding(
              padding: adaptiveScreenPadding(
                context,
                includeFloatingNavReserve: false,
                top: 0,
              ),
              child: Row(
                children: [
                  ...List.generate(
                    _totalPages,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 8),
                      width: _page == index ? 28 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _page == index
                            ? KuglaColors.pulse
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving ? null : _next,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: KuglaColors.deepSpace),
                          )
                        : Icon(_isLastPage
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded),
                    label: Text(
                        _isLastPage ? 'Launch Kugla' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  final double hPad;
  final String eyebrow;
  final String title;
  final bool showTagline;
  final bool showSkip;
  final VoidCallback onSkip;

  const _OnboardingHeader({
    required this.hPad,
    required this.eyebrow,
    required this.title,
    required this.showTagline,
    required this.showSkip,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final shadows = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.75),
        blurRadius: 10,
        offset: const Offset(0, 1),
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        border: const Border(
          bottom: BorderSide(color: KuglaColors.stroke),
        ),
        gradient: LinearGradient(
          colors: [
            KuglaColors.deepSpace.withValues(alpha: 0.92),
            KuglaColors.midnight.withValues(alpha: 0.72),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.public_rounded, color: KuglaColors.cyan, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: KuglaColors.cyanSoft,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                        shadows: shadows,
                      ),
                ),
                const SizedBox(height: 4),
                KuglaGradientTitle(title),
                if (showTagline) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Street View drops · pin the globe · $kBuildStamp',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: KuglaColors.textMuted,
                          letterSpacing: 0.15,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (showSkip)
            TextButton(
              onPressed: onSkip,
              child: const Text('Skip'),
            ),
        ],
      ),
    );
  }
}

class _ProfileSetupPage extends StatelessWidget {
  final TextEditingController nameController;
  final String? avatarPath;
  final VoidCallback onPickImage;

  const _ProfileSetupPage({
    required this.nameController,
    required this.avatarPath,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GlassPanel(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onPickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [KuglaColors.cyan, KuglaColors.lilac],
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: avatarPath != null
                            ? Image.file(File(avatarPath!),
                                fit: BoxFit.cover)
                            : const Icon(Icons.person_rounded,
                                color: KuglaColors.deepSpace, size: 44),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: KuglaColors.cyan,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: KuglaColors.panel, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: KuglaColors.deepSpace),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onPickImage,
                  child: const Text('Add a photo'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    hintText: 'e.g. Bobby or Mum',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'You can update both at any time from your profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: KuglaColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
