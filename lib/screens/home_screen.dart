import 'dart:math';

import 'package:flutter/material.dart';

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
                    final wide = inner.maxWidth >= 980;
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
  late final AnimationController _globeController;

  @override
  void initState() {
    super.initState();
    _globeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 48),
    )..repeat();
  }

  @override
  void dispose() {
    _globeController.dispose();
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
            // Rotating globe backdrop
            Positioned(
              right: -40,
              top: 0,
              bottom: 0,
              width: 260,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _globeController,
                  builder: (context, _) => CustomPaint(
                    painter: _GlobePainter(
                      viewLng: _globeController.value * 360 - 180,
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

class _MissionModeCard extends StatelessWidget {
  final MissionMode mode;
  final VoidCallback onLaunch;

  const _MissionModeCard({
    required this.mode,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final iconTile = Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: mode.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(mode.icon, color: mode.color),
        );

        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mode.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              mode.subtitle,
              style: TextStyle(
                color: mode.color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mode.detail,
              style: const TextStyle(
                color: KuglaColors.textMuted,
                height: 1.45,
              ),
            ),
          ],
        );

        final launchButton = FilledButton.tonalIcon(
          onPressed: onLaunch,
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
                  color: mode.color.withValues(alpha: 0.7),
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
const _continentPolygons = <List<List<double>>>[
  // North America
  [
    [71.0, -156.0], [60.0, -140.0], [49.0, -124.0], [32.5, -117.0],
    [15.0, -87.0], [8.0, -77.0], [9.0, -83.0], [15.0, -92.0],
    [25.0, -80.0], [30.0, -81.0], [35.0, -76.0], [41.0, -70.0],
    [47.0, -53.0], [50.0, -56.0], [60.0, -64.0], [65.0, -83.0],
    [71.0, -156.0],
  ],
  // South America
  [
    [12.0, -72.0], [10.0, -62.0], [5.0, -52.0], [0.0, -50.0],
    [-10.0, -37.0], [-22.0, -42.0], [-34.0, -53.0], [-55.0, -65.0],
    [-45.0, -75.0], [-18.0, -70.0], [-5.0, -81.0], [10.0, -75.0],
    [12.0, -72.0],
  ],
  // Europe
  [
    [71.0, 28.0], [65.0, 14.0], [58.0, 5.0], [51.0, 2.0],
    [43.0, -9.0], [36.0, -6.0], [36.0, 2.0], [37.0, 15.0],
    [40.0, 18.0], [46.0, 13.0], [48.0, 22.0], [54.0, 18.0],
    [60.0, 25.0], [71.0, 28.0],
  ],
  // Africa
  [
    [37.0, -5.0], [37.0, 10.0], [30.0, 32.0], [22.0, 37.0],
    [12.0, 44.0], [5.0, 40.0], [-5.0, 39.0], [-26.0, 33.0],
    [-34.0, 27.0], [-34.0, 18.0], [-26.0, 15.0], [-8.0, 14.0],
    [5.0, -5.0], [10.0, -15.0], [22.0, -17.0], [30.0, -13.0],
    [37.0, -5.0],
  ],
  // Asia
  [
    [71.0, 28.0], [72.0, 68.0], [70.0, 100.0], [65.0, 142.0],
    [50.0, 140.0], [35.0, 120.0], [22.0, 114.0], [10.0, 105.0],
    [1.0, 104.0], [10.0, 99.0], [20.0, 73.0], [8.0, 77.0],
    [22.0, 68.0], [25.0, 51.0], [15.0, 43.0], [12.0, 44.0],
    [22.0, 37.0], [30.0, 32.0], [37.0, 36.0], [40.0, 45.0],
    [57.0, 60.0], [65.0, 68.0], [71.0, 28.0],
  ],
  // Australia
  [
    [-14.0, 127.0], [-12.0, 137.0], [-18.0, 145.0], [-28.0, 154.0],
    [-37.0, 150.0], [-39.0, 146.0], [-38.0, 141.0], [-32.0, 134.0],
    [-32.0, 115.0], [-22.0, 114.0], [-17.0, 122.0], [-14.0, 127.0],
  ],
];

class _GlobePainter extends CustomPainter {
  final double viewLng;
  static const double _viewLat = 20.0;

  const _GlobePainter({required this.viewLng});

  Offset? _project(double lat, double lng, Size size) {
    final latR = lat * pi / 180;
    final lngR = lng * pi / 180;
    final viewLatR = _viewLat * pi / 180;
    final viewLngR = viewLng * pi / 180;

    final x = cos(latR) * sin(lngR - viewLngR);
    final y = cos(viewLatR) * sin(latR) -
        sin(viewLatR) * cos(latR) * cos(lngR - viewLngR);
    final z = sin(viewLatR) * sin(latR) +
        cos(viewLatR) * cos(latR) * cos(lngR - viewLngR);

    if (z < 0) return null;
    final r = min(size.width, size.height) * 0.46;
    return Offset(size.width / 2 + x * r, size.height / 2 - y * r);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = min(size.width, size.height) * 0.46;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center, r,
      Paint()..color = KuglaColors.pulse.withValues(alpha: 0.06),
    );
    canvas.drawCircle(
      center, r,
      Paint()
        ..color = KuglaColors.cyan.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final gridPaint = Paint()
      ..color = KuglaColors.cyan.withValues(alpha: 0.07)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (var latDeg = -60; latDeg <= 60; latDeg += 30) {
      final pts = <Offset>[];
      for (var lngDeg = -180; lngDeg <= 180; lngDeg += 4) {
        final p = _project(latDeg.toDouble(), lngDeg.toDouble(), size);
        if (p != null) pts.add(p);
      }
      if (pts.length > 1) {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final p in pts.skip(1)) { path.lineTo(p.dx, p.dy); }
        canvas.drawPath(path, gridPaint);
      }
    }
    for (var lngDeg = -150; lngDeg <= 180; lngDeg += 30) {
      final pts = <Offset>[];
      for (var latDeg = -90; latDeg <= 90; latDeg += 4) {
        final p = _project(latDeg.toDouble(), lngDeg.toDouble(), size);
        if (p != null) pts.add(p);
      }
      if (pts.length > 1) {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final p in pts.skip(1)) { path.lineTo(p.dx, p.dy); }
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
        final projected = _project(pt[0], pt[1], size);
        if (projected == null) { prev = null; continue; }
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
  bool shouldRepaint(_GlobePainter old) => old.viewLng != viewLng;
}
