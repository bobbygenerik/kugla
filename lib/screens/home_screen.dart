import 'dart:math';

import 'package:flutter/material.dart';

import '../app/layout_breakpoints.dart';
import '../app/theme.dart';
import '../models/app_state.dart';
import '../models/mock_data.dart';
import '../widgets/mission_widgets.dart';

class HomeScreen extends StatefulWidget {
  final AppSnapshot snapshot;
  final void Function(GameMode) onStartMission;
  final VoidCallback onOpenVault;

  const HomeScreen({
    super.key,
    required this.snapshot,
    required this.onStartMission,
    required this.onOpenVault,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Own controller so we never inherit a stale [PrimaryScrollController]
  /// offset from another route or tab (which can leave this page blank).
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(0);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          padding: adaptiveScreenPadding(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: LayoutBuilder(
                  builder: (context, inner) {
                    final wide = context.wideColumnsFor(inner.maxWidth,
                        minWidth: kWideLayoutMinWidth);
                    final telemetryTiles = [
                      TelemetryTile(
                        label: 'Missions',
                        value: '${widget.snapshot.totalSessions}',
                        icon: Icons.flag_rounded,
                        accent: KuglaColors.cyan,
                      ),
                      TelemetryTile(
                        label: 'Streak',
                        value: widget.snapshot.currentStreakDays == 0
                            ? '--'
                            : '${widget.snapshot.currentStreakDays}d',
                        icon: Icons.local_fire_department_rounded,
                        accent: KuglaColors.amber,
                      ),
                      TelemetryTile(
                        label: 'Countries',
                        value: '${widget.snapshot.exploredCountries}',
                        icon: Icons.public_rounded,
                        accent: KuglaColors.success,
                      ),
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!wide) ...[
                          _HeroMissionPanel(
                            snapshot: widget.snapshot,
                            onStartMission: () =>
                                widget.onStartMission(GameMode.dailyPulse),
                            onOpenVault: widget.onOpenVault,
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, tileConstraints) {
                              final useRow = tileConstraints.maxWidth >= 760;
                              if (useRow) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: telemetryTiles[0]),
                                    const SizedBox(width: 12),
                                    Expanded(child: telemetryTiles[1]),
                                    const SizedBox(width: 12),
                                    Expanded(child: telemetryTiles[2]),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  telemetryTiles[0],
                                  const SizedBox(height: 12),
                                  telemetryTiles[1],
                                  const SizedBox(height: 12),
                                  telemetryTiles[2],
                                ],
                              );
                            },
                          ),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _HeroMissionPanel(
                                  snapshot: widget.snapshot,
                                  onStartMission: () => widget
                                      .onStartMission(GameMode.dailyPulse),
                                  onOpenVault: widget.onOpenVault,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    telemetryTiles[0],
                                    const SizedBox(height: 12),
                                    telemetryTiles[1],
                                    const SizedBox(height: 12),
                                    telemetryTiles[2],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 32),
                        const SectionHeader(
                          eyebrow: 'Routes',
                          title: 'Other mission types',
                          subtitle:
                              'Daily Pulse lives in the card above. Atlas and Landmark use different timers and scoring.',
                        ),
                        const SizedBox(height: 16),
                        ...missionModes
                            .where((m) => m.gameMode != GameMode.dailyPulse)
                            .map(
                              (mode) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _MissionModeCard(
                                  mode: mode,
                                  onLaunch: () =>
                                      widget.onStartMission(mode.gameMode),
                                ),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroMissionPanel extends StatefulWidget {
  final AppSnapshot snapshot;
  final VoidCallback onStartMission;
  final VoidCallback onOpenVault;

  const _HeroMissionPanel({
    required this.snapshot,
    required this.onStartMission,
    required this.onOpenVault,
  });

  @override
  State<_HeroMissionPanel> createState() => _HeroMissionPanelState();
}

class _HeroMissionPanelState extends State<_HeroMissionPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount =
        widget.snapshot.achievements.where((a) => a.unlocked).length;
    final vaultLabel =
        '$unlockedCount/${widget.snapshot.achievements.length} achievements';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1A3B4A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color(0xF20D1E28),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF071318).withValues(alpha: 0.52),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.44],
                    ),
                  ),
                ),
              ),
            ),
            // Daily Pulse ambient animation (radiating pin/beacon)
            Positioned(
              right: -40,
              top: 0,
              bottom: 0,
              width: 260,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) => CustomPaint(
                    painter: _PulseBeaconPainter(
                      progress: _pulseController.value,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 3,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        KuglaColors.pulse.withValues(alpha: 0.9),
                        KuglaColors.cyan.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      const Chip(
                        avatar: Icon(Icons.flash_on_rounded,
                            color: KuglaColors.pulse, size: 18),
                        label: Text('Daily Pulse'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.auto_awesome_mosaic_outlined,
                            color: KuglaColors.fog, size: 18),
                        label: Text(vaultLabel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Daily pulse is ready.\nChart the next drop.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: const Text(
                      'Five daily-seeded rounds with a live timer, streak bonuses, and one clean pin on the map.',
                      style: TextStyle(
                        color: KuglaColors.textMuted,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: widget.onStartMission,
                        icon: const Icon(Icons.flash_on_rounded),
                        label: const Text('Play Daily Pulse'),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.onOpenVault,
                        icon: const Icon(Icons.auto_awesome_mosaic_outlined),
                        label: const Text('Open Vault'),
                      ),
                    ],
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

class _MissionModeCard extends StatefulWidget {
  final MissionMode mode;
  final VoidCallback onLaunch;

  const _MissionModeCard({
    required this.mode,
    required this.onLaunch,
  });

  @override
  State<_MissionModeCard> createState() => _MissionModeCardState();
}

class _MissionModeCardState extends State<_MissionModeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final iconTile = Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: widget.mode.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Custom painters replace the stock icons for atlas / landmark so we
              // don't get a second "mini globe" or map glyph in the center.
              if (widget.mode.gameMode != GameMode.worldAtlas &&
                  widget.mode.gameMode != GameMode.landmarkLock)
                Icon(widget.mode.icon, color: widget.mode.color),
              if (widget.mode.gameMode == GameMode.worldAtlas)
                AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) => CustomPaint(
                    painter: _AtlasBadgePainter(
                      viewLng: _ambientController.value * 360 - 180,
                    ),
                  ),
                ),
              if (widget.mode.gameMode == GameMode.landmarkLock)
                AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) => CustomPaint(
                    painter: _LandmarkPulsePainter(
                      progress: _ambientController.value,
                    ),
                  ),
                ),
            ],
          ),
        );

        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mode.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.mode.subtitle,
              style: TextStyle(
                color: widget.mode.color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.mode.detail,
              style: const TextStyle(
                color: KuglaColors.textMuted,
                height: 1.45,
              ),
            ),
          ],
        );

        final launchButton = FilledButton.tonalIcon(
          onPressed: widget.onLaunch,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Play'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: KuglaColors.panel.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: KuglaColors.stroke),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: ColoredBox(
                  color: widget.mode.color.withValues(alpha: 0.7),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(23, 20, 20, 20),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              iconTile,
                              const SizedBox(width: 16),
                              Expanded(child: copy),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: launchButton,
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          iconTile,
                          const SizedBox(width: 16),
                          Expanded(child: copy),
                          const SizedBox(width: 16),
                          launchButton,
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Simplified continent polygon data [lat, lng] for orthographic globe rendering.
// Tuned for recognizability (not geodetic precision) at small card scale.
const _continentPolygons = <List<List<double>>>[
  // North America
  [
    [72.0, -165.0], [67.0, -150.0], [60.0, -135.0], [53.0, -125.0],
    [48.0, -123.0], [43.0, -124.0], [37.0, -121.0], [32.0, -117.0],
    [25.0, -110.0], [21.0, -100.0], [17.0, -93.0], [14.0, -89.0],
    [16.0, -84.0], [22.0, -82.0], [27.0, -80.0], [30.0, -81.0],
    [36.0, -76.0], [42.0, -70.0], [47.0, -60.0], [52.0, -56.0],
    [58.0, -64.0], [64.0, -78.0], [70.0, -100.0], [72.0, -130.0],
    [72.0, -165.0],
  ],
  // South America
  [
    [12.0, -78.0], [10.0, -72.0], [8.0, -66.0], [6.0, -60.0],
    [3.0, -54.0], [-2.0, -50.0], [-8.0, -47.0], [-14.0, -44.0],
    [-22.0, -46.0], [-30.0, -52.0], [-38.0, -58.0], [-46.0, -65.0],
    [-53.0, -69.0], [-56.0, -66.0], [-52.0, -61.0], [-44.0, -58.0],
    [-34.0, -54.0], [-22.0, -60.0], [-12.0, -70.0], [-4.0, -76.0],
    [4.0, -79.0], [10.0, -78.0], [12.0, -78.0],
  ],
  // Europe
  [
    [71.0, 28.0], [66.0, 22.0], [61.0, 14.0], [57.0, 8.0],
    [54.0, 2.0], [50.0, 0.0], [46.0, -4.0], [43.0, -8.0],
    [40.0, -9.0], [37.0, -4.0], [37.0, 4.0], [40.0, 10.0],
    [43.0, 14.0], [46.0, 18.0], [49.0, 20.0], [53.0, 18.0],
    [58.0, 20.0], [63.0, 24.0], [68.0, 27.0], [71.0, 28.0],
  ],
  // Africa
  [
    [37.0, -17.0], [37.0, -8.0], [35.0, 0.0], [36.0, 8.0],
    [37.0, 16.0], [34.0, 24.0], [30.0, 32.0], [23.0, 37.0],
    [15.0, 43.0], [8.0, 44.0], [2.0, 40.0], [-6.0, 38.0],
    [-15.0, 36.0], [-22.0, 34.0], [-29.0, 30.0], [-34.0, 24.0],
    [-34.0, 17.0], [-30.0, 12.0], [-24.0, 13.0], [-16.0, 15.0],
    [-8.0, 12.0], [-3.0, 8.0], [2.0, 5.0], [5.0, 0.0],
    [9.0, -5.0], [12.0, -11.0], [18.0, -16.0], [26.0, -17.0],
    [33.0, -15.0], [37.0, -17.0],
  ],
  // Asia
  [
    [71.0, 28.0], [72.0, 45.0], [72.0, 62.0], [70.0, 80.0],
    [66.0, 98.0], [62.0, 118.0], [58.0, 132.0], [52.0, 142.0],
    [45.0, 145.0], [38.0, 140.0], [32.0, 132.0], [28.0, 122.0],
    [24.0, 116.0], [20.0, 111.0], [16.0, 106.0], [10.0, 102.0],
    [5.0, 98.0], [2.0, 102.0], [7.0, 108.0], [13.0, 102.0],
    [18.0, 95.0], [22.0, 86.0], [25.0, 78.0], [28.0, 70.0],
    [24.0, 64.0], [18.0, 60.0], [16.0, 52.0], [20.0, 45.0],
    [24.0, 40.0], [30.0, 34.0], [37.0, 36.0], [44.0, 46.0],
    [52.0, 56.0], [60.0, 66.0], [67.0, 74.0], [71.0, 28.0],
  ],
  // Australia
  [
    [-11.0, 113.0], [-15.0, 122.0], [-16.0, 130.0], [-12.0, 138.0],
    [-16.0, 146.0], [-23.0, 153.0], [-30.0, 153.0], [-36.0, 149.0],
    [-39.0, 145.0], [-38.0, 139.0], [-35.0, 132.0], [-31.0, 125.0],
    [-31.0, 118.0], [-27.0, 114.0], [-20.0, 112.0], [-14.0, 112.0],
    [-11.0, 113.0],
  ],
];

Offset? _projectOrtho(
  double lat,
  double lng,
  Size size, {
  required double viewLng,
  double viewLatRad = 0.3490658503988659,
  double radiusScale = 0.46,
}) {
  final latR = lat * pi / 180;
  final lngR = lng * pi / 180;
  final viewLngR = viewLng * pi / 180;

  final x = cos(latR) * sin(lngR - viewLngR);
  final y = cos(viewLatRad) * sin(latR) -
      sin(viewLatRad) * cos(latR) * cos(lngR - viewLngR);
  final z = sin(viewLatRad) * sin(latR) +
      cos(viewLatRad) * cos(latR) * cos(lngR - viewLngR);
  if (z < 0) return null;
  final r = min(size.width, size.height) * radiusScale;
  return Offset(size.width / 2 + x * r, size.height / 2 - y * r);
}

class _AtlasBadgePainter extends CustomPainter {
  final double viewLng;
  const _AtlasBadgePainter({required this.viewLng});

  @override
  void paint(Canvas canvas, Size size) {
    final r = min(size.width, size.height) * 0.44;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center, r,
      Paint()..color = KuglaColors.atlas.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center, r,
      Paint()
        ..color = KuglaColors.atlas.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    final gridPaint = Paint()
      ..color = KuglaColors.atlas.withValues(alpha: 0.18)
      ..strokeWidth = 0.55
      ..style = PaintingStyle.stroke;
    for (var lngDeg = -120; lngDeg <= 120; lngDeg += 60) {
      final pts = <Offset>[];
      for (var latDeg = -80; latDeg <= 80; latDeg += 8) {
        final p = _projectOrtho(
          latDeg.toDouble(),
          lngDeg.toDouble(),
          size,
          viewLng: viewLng,
          radiusScale: 0.44,
        );
        if (p != null) pts.add(p);
      }
      if (pts.length > 1) {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final p in pts.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, gridPaint);
      }
    }

    final landPaint = Paint()
      ..color = KuglaColors.cyan.withValues(alpha: 0.28)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    for (final polygon in _continentPolygons) {
      Offset? first;
      Offset? prev;
      for (final pt in polygon) {
        final projected = _projectOrtho(
          pt[0],
          pt[1],
          size,
          viewLng: viewLng,
          radiusScale: 0.44,
        );
        if (projected == null) {
          prev = null;
          continue;
        }
        if (prev != null) {
          canvas.drawLine(prev, projected, landPaint);
        } else {
          first = projected;
        }
        prev = projected;
      }
      if (first != null && prev != null) {
        canvas.drawLine(prev, first, landPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_AtlasBadgePainter old) => old.viewLng != viewLng;
}

class _PulseBeaconPainter extends CustomPainter {
  final double progress;
  const _PulseBeaconPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final epicenter = Offset(size.width * 0.58, size.height * 0.46);
    final base = min(size.width, size.height) * 0.12;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Outer waves — radiate from pin tip (epicenter).
    for (var i = 0; i < 4; i++) {
      final t = (progress + i / 4) % 1.0;
      final radius = base + (t * size.width * 0.34);
      ringPaint.color = KuglaColors.pulse.withValues(alpha: (1 - t) * 0.25);
      canvas.drawCircle(epicenter, radius, ringPaint);
    }
    // Inner burst so the origin at the pin reads clearly (same epicenter).
    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3 + 0.12) % 1.0;
      final radius = base * 0.12 + (t * size.width * 0.2);
      ringPaint
        ..strokeWidth = 1.25
        ..color = KuglaColors.pulse.withValues(alpha: (1 - t) * 0.42);
      canvas.drawCircle(epicenter, radius, ringPaint);
    }

    final pinPath = Path()
      ..moveTo(epicenter.dx, epicenter.dy - base * 2.7)
      ..cubicTo(
        epicenter.dx + base * 0.95,
        epicenter.dy - base * 2.7,
        epicenter.dx + base * 1.08,
        epicenter.dy - base * 1.65,
        epicenter.dx,
        epicenter.dy,
      )
      ..cubicTo(
        epicenter.dx - base * 1.08,
        epicenter.dy - base * 1.65,
        epicenter.dx - base * 0.95,
        epicenter.dy - base * 2.7,
        epicenter.dx,
        epicenter.dy - base * 2.7,
      )
      ..close();

    canvas.drawPath(
      pinPath,
      Paint()..color = KuglaColors.pulse.withValues(alpha: 0.46),
    );
    canvas.drawCircle(
      Offset(epicenter.dx, epicenter.dy - base * 1.95),
      base * 0.42,
      Paint()..color = KuglaColors.cyan.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_PulseBeaconPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _LandmarkPulsePainter extends CustomPainter {
  final double progress;
  const _LandmarkPulsePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final dim = min(size.width, size.height);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    // Same geometry as [_AtlasBadgePainter]: circular badge in the square tile.
    final r = dim * 0.44;
    const tone = KuglaColors.landmark;
    final wobble = sin(progress * 2 * pi * 4.2) * 0.16 * (1 - progress);
    final glow = 0.28 + 0.08 * cos(progress * 2 * pi);

    // Shell matches Atlas (filled disc + rim).
    canvas.drawCircle(center, r, Paint()..color = tone.withValues(alpha: 0.16));
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = tone.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.9, dim * 0.018),
    );

    // Monument design size in abstract units (width 26 × height 25); scale so
    // the full bbox fits inside the disc with margin (like continents in Atlas).
    const designW = 26.0;
    const designH = 25.0;
    final u = 2 * r * 0.86 / max(designW, designH);
    final sw = max(0.75, u * 0.12);

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.38),
        width: r * 1.05,
        height: r * 0.2,
      ),
      Paint()..color = tone.withValues(alpha: 0.12 + glow * 0.2),
    );

    // Local coords: origin = bbox center; pivot at arch foot (ground) for wobble.
    canvas.translate(cx, cy);
    canvas.translate(0, 9.5 * u);
    canvas.rotate(wobble);
    canvas.translate(0, -9.5 * u);

    final fill = Paint()..color = tone.withValues(alpha: 0.42 + glow * 0.2);
    final edge = Paint()
      ..color = const Color(0xFF4A3028).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw;

    void strokeRectLocal(Rect rect) {
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, edge);
    }

    final lo = -13 * u;
    final li = -5 * u;
    final ri = 5 * u;
    final ro = 13 * u;

    strokeRectLocal(Rect.fromLTRB(lo, 9.5 * u, ro, 12.5 * u));
    strokeRectLocal(Rect.fromLTRB(lo, -1.5 * u, li, 9.5 * u));
    strokeRectLocal(Rect.fromLTRB(ri, -1.5 * u, ro, 9.5 * u));
    strokeRectLocal(Rect.fromLTRB(lo, -4.5 * u, ro, -1.5 * u));

    final pediment = Path()
      ..moveTo(lo, -4.5 * u)
      ..lineTo(ro, -4.5 * u)
      ..lineTo(0, -12.5 * u)
      ..close();
    canvas.drawPath(pediment, fill);
    canvas.drawPath(pediment, edge);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LandmarkPulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
