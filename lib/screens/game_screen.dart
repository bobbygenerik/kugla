import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_google_street_view/flutter_google_street_view.dart'
    as street_view;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/theme.dart';
import '../models/app_state.dart';

class GameScreen extends StatefulWidget {
  final AppSettings settings;
  final GameMode gameMode;

  const GameScreen({
    super.key,
    required this.settings,
    this.gameMode = GameMode.worldAtlas,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _random = Random();
  final List<RoundResult> _results = [];

  late final DateTime _startedAt;
  late List<LocationSeed> _roundSeeds;
  street_view.StreetViewController? _streetViewController;
  int _roundIndex = 0;
  int _streetViewGeneration = 0;
  LatLng? _userGuess;
  bool _mapExpanded = false;
  bool _streetViewReady = false;
  bool _streetViewFailed = false;
  String? _streetViewErrorMessage;
  Timer? _streetViewTimeout;
  Timer? _roundTimer;
  int _secondsLeft = 90;
  int _streak = 0;

  LocationSeed get _currentSeed => _roundSeeds[_roundIndex];

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    final seedPool = widget.gameMode == GameMode.landmarkLock
        ? landmarkSeeds
        : streetViewSeeds;
    final roundCount = widget.gameMode == GameMode.worldAtlas
        ? widget.settings.roundsPerMission
        : 5;
    if (widget.gameMode == GameMode.dailyPulse) {
      final now = DateTime.now();
      final dateSeed = now.year * 10000 + now.month * 100 + now.day;
      _roundSeeds = [...seedPool]..shuffle(Random(dateSeed));
    } else {
      _roundSeeds = [...seedPool]..shuffle(_random);
    }
    _roundSeeds = _roundSeeds.take(roundCount).toList();
    _beginRound();
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _streetViewTimeout?.cancel();
    super.dispose();
  }

  void _beginRound() {
    _roundTimer?.cancel();
    if (widget.gameMode == GameMode.dailyPulse) {
      _secondsLeft = 90;
      _roundTimer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);
    }
    _streetViewTimeout?.cancel();
    _streetViewGeneration += 1;
    _streetViewController = null;
    _userGuess = null;
    _mapExpanded = false;
    _streetViewReady = false;
    _streetViewFailed = false;
    _streetViewErrorMessage = null;
    _streetViewTimeout = Timer(const Duration(seconds: 12), () {
      if (!mounted || _streetViewReady || _streetViewController != null) return;
      setState(() {
        _streetViewFailed = true;
        _streetViewErrorMessage =
            'The panorama took too long to respond. This usually means Street View is unavailable for this spot or the API request was rejected.';
      });
    });
  }

  void _retryRound() {
    setState(_beginRound);
  }

  void _onTimerTick(Timer timer) {
    if (!mounted) return;
    setState(() => _secondsLeft--);
    if (_secondsLeft <= 0) {
      timer.cancel();
      if (_userGuess != null) {
        unawaited(_onGuessPressed());
      } else {
        _skipRound();
      }
    }
  }

  double _streakMultiplier() {
    if (_streak <= 0) return 1.0;
    if (_streak == 1) return 1.10;
    if (_streak == 2) return 1.15;
    return 1.20;
  }

  void _toggleMapExpanded([bool? expanded]) {
    setState(() {
      _mapExpanded = expanded ?? !_mapExpanded;
    });
  }

  void _skipRound() {
    _roundTimer?.cancel();
    if (widget.gameMode == GameMode.dailyPulse) _streak = 0;
    final seed = _currentSeed;
    final skipped = RoundResult(
      locationId: seed.id,
      locationName: seed.name,
      country: seed.country,
      targetLatitude: seed.latitude,
      targetLongitude: seed.longitude,
      guessLatitude: seed.latitude,
      guessLongitude: seed.longitude,
      distanceKm: 0,
      score: 0,
      playedAt: DateTime.now(),
    );
    _results.add(skipped);
    _advanceOrFinish();
  }

  void _onPanoramaChange(
    street_view.StreetViewPanoramaLocation? location,
    Exception? error,
  ) {
    if (!mounted) return;
    if (error != null) {
      _streetViewTimeout?.cancel();
      setState(() {
        _streetViewFailed = true;
        _streetViewErrorMessage = error.toString();
      });
      return;
    }
    if (location?.panoId == null) return;
    _markStreetViewReady();
  }

  void _onStreetViewCreated(street_view.StreetViewController controller) {
    _streetViewController = controller;
    final generation = _streetViewGeneration;

    unawaited(_configureStreetViewController(controller, generation));

    // The native Street View surface can be visibly alive before the plugin
    // emits a panorama-change callback, so don't keep the player blocked.
    Future<void>.delayed(const Duration(milliseconds: 1200), () async {
      if (!mounted ||
          generation != _streetViewGeneration ||
          _streetViewFailed) {
        return;
      }
      _markStreetViewReady();
      await _probeStreetViewLocation(generation);
    });
  }

  Future<void> _configureStreetViewController(
    street_view.StreetViewController controller,
    int generation,
  ) async {
    try {
      await controller.setPanningGesturesEnabled(true);
      await controller.setZoomGesturesEnabled(true);
      await controller.setStreetNamesEnabled(widget.settings.showStreetNames);
      await controller.setUserNavigationEnabled(widget.settings.allowMovement);
    } catch (_) {
      if (!mounted || generation != _streetViewGeneration) return;
    }
  }

  Future<void> _probeStreetViewLocation(int generation) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      if (!mounted ||
          generation != _streetViewGeneration ||
          _streetViewFailed) {
        return;
      }

      final controller = _streetViewController;
      if (controller == null) return;

      try {
        final location = await controller.getLocation();
        if (!mounted || generation != _streetViewGeneration) return;
        if (location?.panoId != null) {
          _markStreetViewReady();
          return;
        }
      } catch (_) {
        // Ignore probe failures and let the native view continue rendering.
      }

      await Future<void>.delayed(const Duration(milliseconds: 900));
    }
  }

  void _markStreetViewReady() {
    _streetViewTimeout?.cancel();
    if (!_streetViewReady ||
        _streetViewFailed ||
        _streetViewErrorMessage != null) {
      setState(() {
        _streetViewReady = true;
        _streetViewFailed = false;
        _streetViewErrorMessage = null;
      });
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    const radius = 6371.0;
    final dLat = _toRad(p2.latitude - p1.latitude);
    final dLon = _toRad(p2.longitude - p1.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(p1.latitude)) *
            cos(_toRad(p2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return radius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double degrees) => degrees * pi / 180;

  Future<void> _onGuessPressed() async {
    _roundTimer?.cancel();
    final guess = _userGuess;
    if (guess == null) return;

    final target = LatLng(_currentSeed.latitude, _currentSeed.longitude);
    final distance = _calculateDistance(guess, target);

    final int baseScore;
    if (widget.gameMode == GameMode.landmarkLock) {
      baseScore = max(0, (5000 - (distance * 2.5)).round());
    } else {
      baseScore = max(0, (5000 - (distance * 0.25)).round());
    }

    final multiplier = widget.gameMode == GameMode.dailyPulse && _streak > 0
        ? _streakMultiplier()
        : 1.0;
    final score = (baseScore * multiplier).round().clamp(0, 5000);

    final prevStreak = _streak;
    if (widget.gameMode == GameMode.dailyPulse) {
      _streak = baseScore >= 3500 ? _streak + 1 : 0;
    }

    final result = RoundResult(
      locationId: _currentSeed.id,
      locationName: _currentSeed.name,
      country: _currentSeed.country,
      targetLatitude: _currentSeed.latitude,
      targetLongitude: _currentSeed.longitude,
      guessLatitude: guess.latitude,
      guessLongitude: guess.longitude,
      distanceKm: distance,
      score: score,
      playedAt: DateTime.now(),
    );

    _results.add(result);

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 360),
      transitionBuilder: (context, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity:
              CurvedAnimation(parent: anim, curve: const Interval(0, 0.55)),
          child: ScaleTransition(
            scale: Tween(begin: 0.86, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) => _RoundResultOverlay(
        result: result,
        city: _currentSeed.city,
        roundIndex: _roundIndex,
        totalRounds: _roundSeeds.length,
        gameMode: widget.gameMode,
        streakLength: prevStreak,
        multiplier: multiplier,
      ),
    );

    if (!mounted) return;
    _advanceOrFinish();
  }

  void _advanceOrFinish() {
    if (_roundIndex >= _roundSeeds.length - 1) {
      final session = MissionSession(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        startedAt: _startedAt,
        completedAt: DateTime.now(),
        rounds: List<RoundResult>.from(_results),
        gameMode: widget.gameMode,
      );
      Navigator.of(context).pop(session);
      return;
    }

    setState(() {
      _roundIndex += 1;
      _beginRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final target = LatLng(_currentSeed.latitude, _currentSeed.longitude);
    final missionScore =
        _results.fold<int>(0, (sum, result) => sum + result.score);
    final canOpenMap = _streetViewReady && !_streetViewFailed;
    final mapHeight = min(media.size.height * 0.56, 430.0);
    final cluePanelWidth = min(media.size.width - 32, 440.0);

    return Scaffold(
      backgroundColor: KuglaColors.deepSpace,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: street_view.FlutterGoogleStreetView(
              key: ValueKey(
                  '${_currentSeed.id}-${_streetViewFailed ? 'retry' : 'live'}'),
              initPos: target,
              initRadius: 1200,
              initSource: street_view.StreetViewSource.def,
              streetNamesEnabled: widget.settings.showStreetNames,
              userNavigationEnabled: widget.settings.allowMovement,
              onStreetViewCreated: _onStreetViewCreated,
              onPanoramaChangeListener: _onPanoramaChange,
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xB0060D18),
                      Color(0x3A08111F),
                      Color(0x1408111F),
                      Color(0xC408111F),
                    ],
                    stops: [0, 0.22, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
          if (!_streetViewReady && !_streetViewFailed)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xAA050B14),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: KuglaColors.cyan),
                      SizedBox(height: 14),
                      Text(
                        'Locking onto Street View...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_streetViewFailed)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xD9050B14),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: KuglaColors.panel.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: KuglaColors.stroke),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: KuglaColors.amber,
                                size: 44,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Street View failed to load',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _streetViewErrorMessage ??
                                    'The panorama could not be opened for this round. Retry this location or skip to the next one.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: KuglaColors.textMuted,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  FilledButton.icon(
                                    onPressed: _retryRound,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Retry round'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _skipRound,
                                    icon: const Icon(Icons.skip_next_rounded),
                                    label: const Text('Skip round'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _HudIconButton(
                            icon: Icons.arrow_back_rounded,
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Leave mission',
                          ),
                          const Spacer(),
                          if (widget.gameMode == GameMode.dailyPulse) ...[
                            _HudChip(
                              icon: Icons.timer_rounded,
                              label: _secondsLeft > 0
                                  ? '${_secondsLeft}s'
                                  : 'Time!',
                              color: _secondsLeft <= 5
                                  ? KuglaColors.rose
                                  : _secondsLeft <= 15
                                      ? KuglaColors.amber
                                      : KuglaColors.cyan,
                            ),
                            if (_streak > 0) ...[
                              const SizedBox(width: 8),
                              _HudChip(
                                icon: Icons.local_fire_department_rounded,
                                label: '${_streak}x',
                                color: KuglaColors.amber,
                              ),
                            ],
                            const SizedBox(width: 8),
                          ],
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 380),
                            transitionBuilder: (child, anim) => SlideTransition(
                              position: Tween(
                                begin: const Offset(0, -0.9),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutCubic)),
                              child:
                                  FadeTransition(opacity: anim, child: child),
                            ),
                            child: _HudChip(
                              key: ValueKey(missionScore),
                              icon: Icons.track_changes_rounded,
                              label: 'Score $missionScore',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: cluePanelWidth),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: KuglaColors.panel.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: KuglaColors.stroke),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HudChip(
                                  icon: Icons.explore_rounded,
                                  label:
                                      'Round ${_roundIndex + 1} of ${_roundSeeds.length}',
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _currentSeed.clue,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.settings.allowMovement
                                      ? 'Free roam'
                                      : 'Locked view',
                                  style: const TextStyle(
                                    color: KuglaColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_mapExpanded)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _toggleMapExpanded(false),
                        child: Container(color: Colors.black26),
                      ),
                    ),
                  Align(
                    alignment: _mapExpanded
                        ? Alignment.bottomCenter
                        : Alignment.bottomRight,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: _mapExpanded ? media.size.width - 32 : 168,
                      height: _mapExpanded ? mapHeight : 128,
                      decoration: BoxDecoration(
                        color: KuglaColors.panel.withValues(alpha: 0.94),
                        borderRadius:
                            BorderRadius.circular(_mapExpanded ? 30 : 26),
                        border: Border.all(color: KuglaColors.stroke),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x44000000),
                            blurRadius: 28,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(_mapExpanded ? 30 : 26),
                        child: !_mapExpanded
                            ? Stack(
                                children: [
                                  const Positioned.fill(
                                    child: GoogleMap(
                                      mapType: MapType.normal,
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(20, 0),
                                        zoom: 1.2,
                                      ),
                                      zoomControlsEnabled: false,
                                      myLocationButtonEnabled: false,
                                      compassEnabled: false,
                                      mapToolbarEnabled: false,
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
                                              Colors.black
                                                  .withValues(alpha: 0.10),
                                              Colors.black
                                                  .withValues(alpha: 0.52),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: canOpenMap
                                            ? () => _toggleMapExpanded(true)
                                            : null,
                                        child: const Padding(
                                          padding: EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _HudChip(
                                                icon: Icons.place_rounded,
                                                label: 'Map',
                                              ),
                                              Text(
                                                'Tap to guess',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const _HudChip(
                                          icon: Icons.place_rounded,
                                          label: 'Drop your pin',
                                        ),
                                        const Spacer(),
                                        _HudIconButton(
                                          icon: Icons.close_rounded,
                                          onPressed: () =>
                                              _toggleMapExpanded(false),
                                          tooltip: 'Close map',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: GoogleMap(
                                          mapType: MapType.normal,
                                          initialCameraPosition:
                                              const CameraPosition(
                                            target: LatLng(20, 0),
                                            zoom: 1.2,
                                          ),
                                          onTap: (pos) =>
                                              setState(() => _userGuess = pos),
                                          markers: _userGuess == null
                                              ? {}
                                              : {
                                                  Marker(
                                                    markerId:
                                                        const MarkerId('guess'),
                                                    position: _userGuess!,
                                                  ),
                                                },
                                          zoomControlsEnabled: false,
                                          myLocationButtonEnabled: false,
                                          compassEnabled: false,
                                          mapToolbarEnabled: false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xCC08111F),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: KuglaColors.stroke,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _userGuess == null
                                                  ? 'Tap anywhere on the map to place your guess.'
                                                  : 'Pinned at ${_userGuess!.latitude.toStringAsFixed(3)}, ${_userGuess!.longitude.toStringAsFixed(3)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => setState(
                                                      () => _userGuess = null,
                                                    ),
                                                    icon: const Icon(
                                                      Icons.restart_alt_rounded,
                                                    ),
                                                    label:
                                                        const Text('Clear pin'),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: FilledButton.icon(
                                                    onPressed:
                                                        _userGuess != null
                                                            ? _onGuessPressed
                                                            : null,
                                                    icon: const Icon(
                                                      Icons
                                                          .check_circle_rounded,
                                                    ),
                                                    label: const Text(
                                                      'Lock guess',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundResultOverlay extends StatefulWidget {
  final RoundResult result;
  final String city;
  final int roundIndex;
  final int totalRounds;
  final GameMode gameMode;
  final int streakLength;
  final double multiplier;

  const _RoundResultOverlay({
    required this.result,
    required this.city,
    required this.roundIndex,
    required this.totalRounds,
    required this.gameMode,
    required this.streakLength,
    required this.multiplier,
  });

  @override
  State<_RoundResultOverlay> createState() => _RoundResultOverlayState();
}

class _RoundResultOverlayState extends State<_RoundResultOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countController;
  late final Animation<double> _countAnim;

  @override
  void initState() {
    super.initState();
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _countAnim = CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    );
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) _countController.forward();
    });
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.result.score;
    final isLast = widget.roundIndex == widget.totalRounds - 1;

    final Color accent;
    final String label;
    final IconData icon;
    if (score >= 4000) {
      accent = KuglaColors.cyan;
      label = 'Sharp eye';
      icon = Icons.my_location_rounded;
    } else if (score >= 2500) {
      accent = KuglaColors.amber;
      label = 'On target';
      icon = Icons.track_changes_rounded;
    } else {
      accent = KuglaColors.lilac;
      label = 'Off course';
      icon = Icons.gps_off_rounded;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: BoxDecoration(
                color: KuglaColors.panel,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: accent.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 48,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLast
                          ? 'MISSION COMPLETE'
                          : 'ROUND ${widget.roundIndex + 1} OF ${widget.totalRounds}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: KuglaColors.textMuted,
                            letterSpacing: 1.4,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accent, size: 30),
                    ),
                    const SizedBox(height: 14),
                    AnimatedBuilder(
                      animation: _countAnim,
                      builder: (context, _) {
                        final displayed = (score * _countAnim.value).round();
                        return Text(
                          '$displayed',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '/ 5000',
                      style: TextStyle(
                        color: KuglaColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedBuilder(
                      animation: _countAnim,
                      builder: (context, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: (score / 5000) * _countAnim.value,
                          minHeight: 10,
                          color: accent,
                          backgroundColor: KuglaColors.midnight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (widget.gameMode == GameMode.dailyPulse &&
                        widget.streakLength > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: KuglaColors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: KuglaColors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                size: 14, color: KuglaColors.amber),
                            const SizedBox(width: 5),
                            Text(
                              '${widget.streakLength}x streak · +${((widget.multiplier - 1) * 100).round()}% bonus',
                              style: const TextStyle(
                                color: KuglaColors.amber,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (widget.gameMode == GameMode.landmarkLock) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: KuglaColors.amber.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: KuglaColors.amber.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.terrain_rounded,
                                size: 14, color: KuglaColors.amber),
                            SizedBox(width: 5),
                            Text(
                              'Landmark Lock · precision scoring',
                              style: TextStyle(
                                color: KuglaColors.amber,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    // Mini map showing target and guess
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              (widget.result.targetLatitude +
                                      widget.result.guessLatitude) /
                                  2,
                              (widget.result.targetLongitude +
                                      widget.result.guessLongitude) /
                                  2,
                            ),
                            zoom: 2,
                          ),
                          onMapCreated: (controller) {
                            final target = LatLng(
                              widget.result.targetLatitude,
                              widget.result.targetLongitude,
                            );
                            final guess = LatLng(
                              widget.result.guessLatitude,
                              widget.result.guessLongitude,
                            );
                            final bounds = LatLngBounds(
                              southwest: LatLng(
                                target.latitude < guess.latitude
                                    ? target.latitude
                                    : guess.latitude,
                                target.longitude < guess.longitude
                                    ? target.longitude
                                    : guess.longitude,
                              ),
                              northeast: LatLng(
                                target.latitude > guess.latitude
                                    ? target.latitude
                                    : guess.latitude,
                                target.longitude > guess.longitude
                                    ? target.longitude
                                    : guess.longitude,
                              ),
                            );
                            controller.animateCamera(
                              CameraUpdate.newLatLngBounds(bounds, 48),
                            );
                          },
                          markers: {
                            Marker(
                              markerId: const MarkerId('target'),
                              position: LatLng(
                                widget.result.targetLatitude,
                                widget.result.targetLongitude,
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                            ),
                            Marker(
                              markerId: const MarkerId('guess'),
                              position: LatLng(
                                widget.result.guessLatitude,
                                widget.result.guessLongitude,
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                            ),
                          },
                          polylines: {
                            Polyline(
                              polylineId: const PolylineId('line'),
                              points: [
                                LatLng(
                                  widget.result.targetLatitude,
                                  widget.result.targetLongitude,
                                ),
                                LatLng(
                                  widget.result.guessLatitude,
                                  widget.result.guessLongitude,
                                ),
                              ],
                              color: accent,
                              width: 2,
                            ),
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          mapToolbarEnabled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KuglaColors.midnight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.result.locationName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.city}, ${widget.result.country}',
                            style: const TextStyle(
                                color: KuglaColors.textMuted),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.pin_drop_rounded,
                                  size: 14, color: KuglaColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.result.distanceKm.toStringAsFixed(1)} km from target',
                                style: const TextStyle(
                                  color: KuglaColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          isLast
                              ? Icons.emoji_events_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(
                            isLast ? 'See mission results' : 'Next round'),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: KuglaColors.deepSpace,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HudChip({
    super.key,
    required this.icon,
    required this.label,
    this.color = KuglaColors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC08111F),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KuglaColors.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const _HudIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC08111F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KuglaColors.stroke),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
      ),
    );
  }
}
