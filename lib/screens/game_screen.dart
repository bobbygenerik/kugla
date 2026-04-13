import 'dart:async';
import 'dart:math';

import 'package:flutter_google_street_view/flutter_google_street_view.dart'
    as street_view;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as map_view;

import '../app/theme.dart';
import '../models/app_state.dart';

const _mapsConfigChannel = MethodChannel('kugla/maps_config');

class GameScreen extends StatefulWidget {
  final AppSettings settings;
  final GameMode gameMode;
  final List<String> seenLocationIds;

  const GameScreen({
    super.key,
    required this.settings,
    this.gameMode = GameMode.worldAtlas,
    this.seenLocationIds = const [],
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _random = Random();
  final List<RoundResult> _results = [];

  late final DateTime _startedAt;
  late List<LocationSeed> _roundSeeds;
  int _roundIndex = 0;
  int _streetViewGeneration = 0;
  map_view.LatLng? _userGuess;
  bool _mapExpanded = false;
  bool _streetViewReady = false;
  bool _streetViewFailed = false;
  String? _streetViewErrorMessage;
  Timer? _streetViewTimeout;
  Timer? _roundTimer;
  int _secondsLeft = 90;
  int _streak = 0;
  bool _nativeMapAvailable = false;

  LocationSeed get _currentSeed => _roundSeeds[_roundIndex];

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    final roundCount = widget.gameMode == GameMode.worldAtlas
        ? widget.settings.roundsPerMission
        : 5;
    _roundSeeds = _buildRoundSeeds(roundCount);
    unawaited(_loadNativeMapAvailability());
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
    _userGuess = null;
    _mapExpanded = false;
    _streetViewReady = false;
    _streetViewFailed = false;
    _streetViewErrorMessage = null;
    final capturedGeneration = _streetViewGeneration;
    _streetViewTimeout = Timer(const Duration(seconds: 16), () {
      if (!mounted ||
          _streetViewReady ||
          capturedGeneration != _streetViewGeneration) {
        return;
      }
      setState(() {
        _streetViewFailed = true;
        _streetViewErrorMessage =
            'The panorama took too long to respond. This usually means Street View is unavailable for this spot or the API request was rejected.';
      });
    });
  }

  Future<void> _loadNativeMapAvailability() async {
    try {
      final available = await _mapsConfigChannel
              .invokeMethod<bool>('isGoogleMapsAvailable') ??
          false;
      if (!mounted) return;
      setState(() {
        _nativeMapAvailable = available;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _nativeMapAvailable = false;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _nativeMapAvailable = true;
      });
    }
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

  Future<void> _handleStreetViewCreated(
    street_view.StreetViewController controller,
  ) async {
    try {
      await controller.setUserNavigationEnabled(widget.settings.allowMovement);
      await controller.setZoomGesturesEnabled(true);
      await controller.setPanningGesturesEnabled(true);
    } catch (_) {
      // Keep loading even if a platform gesture toggle is unsupported.
    }
    final location = await controller.getLocation();
    if (!mounted) return;
    if (location == null) {
      _streetViewTimeout?.cancel();
      setState(() {
        _streetViewFailed = true;
        _streetViewErrorMessage =
            'Street View is not available at this location.';
      });
    } else {
      _markStreetViewReady();
    }
  }

  void _handleStreetViewChange(
    street_view.StreetViewPanoramaLocation? location,
    Exception? error,
  ) {
    if (!mounted) return;
    if (error != null || location == null) {
      _streetViewTimeout?.cancel();
      setState(() {
        _streetViewFailed = true;
        _streetViewErrorMessage = error?.toString() ??
            'Street View is not available at this location.';
      });
      return;
    }

    _markStreetViewReady();
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

  List<LocationSeed> _buildRoundSeeds(int roundCount) {
    final seedPool = widget.gameMode == GameMode.landmarkLock
        ? landmarkSeeds
        : streetViewSeeds;
    final shuffled = [...seedPool]..shuffle(_seedRandomizer());
    final recentIds = widget.gameMode == GameMode.dailyPulse
        ? const <String>{}
        : widget.seenLocationIds.toSet();
    final prioritized = <LocationSeed>[
      ...shuffled.where((seed) => !recentIds.contains(seed.id)),
      ...shuffled.where((seed) => recentIds.contains(seed.id)),
    ];
    return prioritized.take(roundCount).toList();
  }

  Random _seedRandomizer() {
    if (widget.gameMode != GameMode.dailyPulse) return _random;
    final now = DateTime.now();
    final dateSeed = now.year * 10000 + now.month * 100 + now.day;
    return Random(dateSeed);
  }

  double _calculateDistance(map_view.LatLng p1, map_view.LatLng p2) {
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

    final target =
        map_view.LatLng(_currentSeed.latitude, _currentSeed.longitude);
    final distance = _calculateDistance(guess, target);

    // Exponential drop-off: 5000 * exp(-distance/2000)
    // This makes far-off guesses get very low points.
    final double baseScoreRaw = 5000 *
        (distance >= 0
            ? (distance < 20000
                ? (distance == 0 ? 1.0 : (exp(-distance / 2000)))
                : 0.0)
            : 0.0);
    final int baseScore = baseScoreRaw.round().clamp(0, 5000);

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
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
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
    final textTheme = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    final missionScore =
        _results.fold<int>(0, (sum, result) => sum + result.score);
    final canOpenMap =
        _streetViewReady && !_streetViewFailed && _nativeMapAvailable;
    final mapHeight = min(media.size.height * 0.56, 430.0);
    // Responsive max width for panels/overlays (90% of width, max 440)
    final double maxPanelWidth = min(media.size.width * 0.9, 440.0);
    final double maxErrorWidth = min(media.size.width * 0.92, 440.0);

    return Scaffold(
      backgroundColor: KuglaColors.deepSpace,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Main content and HUD
          Positioned.fill(
            child: _nativeMapAvailable
                ? street_view.FlutterGoogleStreetView(
                    key: ValueKey(
                      '${_currentSeed.id}:$_streetViewGeneration',
                    ),
                    initPos: street_view.LatLng(
                      _currentSeed.latitude,
                      _currentSeed.longitude,
                    ),
                    initSource: street_view.StreetViewSource.def,
                    onStreetViewCreated: _handleStreetViewCreated,
                    onPanoramaChangeListener: _handleStreetViewChange,
                    streetNamesEnabled: widget.settings.showStreetNames,
                    userNavigationEnabled: widget.settings.allowMovement,
                    zoomGesturesEnabled: true,
                    panningGesturesEnabled: true,
                  )
                : ColoredBox(
                    color: KuglaColors.deepSpace,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxPanelWidth),
                          child: Text(
                            'Street View is not configured for this iOS build yet. Add a valid `GMS_API_KEY` in `ios/Flutter/Secrets.xcconfig` to enable missions.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
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
                      const Color(0xB00E0C09),
                      KuglaColors.deepSpace.withValues(alpha: 0.28),
                      KuglaColors.deepSpace.withValues(alpha: 0.10),
                      KuglaColors.midnight.withValues(alpha: 0.78),
                    ],
                    stops: const [0, 0.22, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
          if (_nativeMapAvailable && !_streetViewReady && !_streetViewFailed)
            Positioned.fill(
              child: ColoredBox(
                color: KuglaColors.deepSpace.withValues(alpha: 0.67),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: KuglaColors.cyan),
                      SizedBox(height: 14),
                      Text(
                        'Locking onto Street View...',
                        style: textTheme.titleSmall?.copyWith(
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
                color: KuglaColors.deepSpace.withValues(alpha: 0.85),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxErrorWidth),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: KuglaColors.panel.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: KuglaColors.stroke),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: KuglaColors.amber,
                                size: 44,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Street View failed to load',
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge?.copyWith(
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
                                style: textTheme.bodyMedium?.copyWith(
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                                  parent: anim, curve: Curves.easeOutCubic)),
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
                        constraints: BoxConstraints(maxWidth: maxPanelWidth),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: KuglaColors.panel.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: KuglaColors.stroke),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.settings.allowMovement
                                      ? 'Free roam'
                                      : 'Locked view',
                                  style: textTheme.labelLarge?.copyWith(
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
                            BorderRadius.circular(_mapExpanded ? 22 : 20),
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
                            BorderRadius.circular(_mapExpanded ? 22 : 20),
                        child: !_mapExpanded
                            ? Stack(
                                children: [
                                  const Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF2A2520),
                                            KuglaColors.midnight,
                                            Color(0xFF1E2822),
                                          ],
                                        ),
                                      ),
                                      child: CustomPaint(
                                        painter: _MiniMapPreviewPainter(),
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
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const _HudChip(
                                                icon: Icons.place_rounded,
                                                label: 'Map',
                                              ),
                                              Text(
                                                canOpenMap
                                                    ? 'Tap to guess'
                                                    : _nativeMapAvailable
                                                        ? 'Waiting for Street View'
                                                        : 'Map unavailable on this build',
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
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
                                        borderRadius: BorderRadius.circular(18),
                                        child: _nativeMapAvailable
                                            ? map_view.GoogleMap(
                                                mapType:
                                                    map_view.MapType.normal,
                                                initialCameraPosition:
                                                    const map_view
                                                        .CameraPosition(
                                                  target:
                                                      map_view.LatLng(20, 0),
                                                  zoom: 1.2,
                                                ),
                                                onTap: (pos) => setState(
                                                    () => _userGuess = pos),
                                                markers: _userGuess == null
                                                    ? {}
                                                    : {
                                                        map_view.Marker(
                                                          markerId:
                                                              const map_view
                                                                  .MarkerId(
                                                                  'guess'),
                                                          position: _userGuess!,
                                                        ),
                                                      },
                                                zoomControlsEnabled: false,
                                                myLocationButtonEnabled: false,
                                                compassEnabled: false,
                                                mapToolbarEnabled: false,
                                              )
                                            : ColoredBox(
                                                color: KuglaColors.midnight,
                                                child: Center(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            20),
                                                    child: Text(
                                                      'Google Maps is not configured for this iOS build yet. Add a valid `GMS_API_KEY` in `ios/Flutter/Secrets.xcconfig` to enable pin drops.',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: textTheme.bodyLarge
                                                          ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: KuglaColors.midnight
                                            .withValues(alpha: 0.88),
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
                                              style: textTheme.titleSmall
                                                  ?.copyWith(
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
                                                        _nativeMapAvailable &&
                                                                _userGuess !=
                                                                    null
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
          // Overlays: always last so they render above the HUD
          if (_nativeMapAvailable && !_streetViewReady && !_streetViewFailed)
            Positioned.fill(
              child: ColoredBox(
                color: KuglaColors.deepSpace.withValues(alpha: 0.67),
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 40, horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: KuglaColors.cyan),
                        SizedBox(height: 14),
                        Text(
                          'Locking onto Street View...',
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_streetViewFailed)
            Positioned.fill(
              child: ColoredBox(
                color: KuglaColors.deepSpace.withValues(alpha: 0.85),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxErrorWidth),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: KuglaColors.panel.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: KuglaColors.stroke),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: KuglaColors.amber,
                                  size: 44,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Street View failed to load',
                                  textAlign: TextAlign.center,
                                  style: textTheme.titleLarge?.copyWith(
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
                                  style: textTheme.bodyMedium?.copyWith(
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
    final textTheme = Theme.of(context).textTheme;
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

    final media = MediaQuery.of(context);
    final double maxDialogWidth = min(media.size.width * 0.95, 480.0);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxDialogWidth),
            child: Container(
              decoration: BoxDecoration(
                color: KuglaColors.panel,
                borderRadius: BorderRadius.circular(22),
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
                    Text(
                      '/ 5000',
                      style: textTheme.bodyLarge?.copyWith(
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
                        style: textTheme.labelLarge?.copyWith(
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
                              style: textTheme.labelMedium?.copyWith(
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.terrain_rounded,
                                size: 14, color: KuglaColors.amber),
                            const SizedBox(width: 5),
                            Text(
                              'Landmark Lock · precision scoring',
                              style: textTheme.labelMedium?.copyWith(
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
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _ResultMapPainter(
                            targetLat: widget.result.targetLatitude,
                            targetLng: widget.result.targetLongitude,
                            guessLat: widget.result.guessLatitude,
                            guessLng: widget.result.guessLongitude,
                            lineColor: accent,
                          ),
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
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.city}, ${widget.result.country}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: KuglaColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.pin_drop_rounded,
                                  size: 14, color: KuglaColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.result.distanceKm.toStringAsFixed(1)} km from target',
                                style: textTheme.bodySmall?.copyWith(
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
                        label:
                            Text(isLast ? 'See mission results' : 'Next round'),
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
        color: KuglaColors.midnight.withValues(alpha: 0.88),
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
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
        color: KuglaColors.midnight.withValues(alpha: 0.88),
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

class _ResultMapPainter extends CustomPainter {
  final double targetLat;
  final double targetLng;
  final double guessLat;
  final double guessLng;
  final Color lineColor;

  const _ResultMapPainter({
    required this.targetLat,
    required this.targetLng,
    required this.guessLat,
    required this.guessLng,
    required this.lineColor,
  });

  // Equirectangular projection: lat/lng → fractional (x, y) in [0,1]
  Offset _project(double lat, double lng, Size size) {
    final x = (lng + 180) / 360 * size.width;
    final y = (90 - lat) / 180 * size.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = KuglaColors.midnight,
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 0.5;
    for (var lng = -180; lng <= 180; lng += 30) {
      final x = (lng + 180) / 360 * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var lat = -90; lat <= 90; lat += 30) {
      final y = (90 - lat) / 180 * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final targetPt = _project(targetLat, targetLng, size);
    final guessPt = _project(guessLat, guessLng, size);

    // Line between guess and target
    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(targetPt, guessPt, linePaint);

    // Target marker (green)
    canvas.drawCircle(
      targetPt,
      7,
      Paint()..color = KuglaColors.amber,
    );
    canvas.drawCircle(
      targetPt,
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Guess marker (red/lilac)
    canvas.drawCircle(
      guessPt,
      6,
      Paint()..color = KuglaColors.lilac,
    );
    canvas.drawCircle(
      guessPt,
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ResultMapPainter old) =>
      old.targetLat != targetLat ||
      old.targetLng != targetLng ||
      old.guessLat != guessLat ||
      old.guessLng != guessLng;
}

class _MiniMapPreviewPainter extends CustomPainter {
  const _MiniMapPreviewPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 0.8;

    for (var lng = -180; lng <= 180; lng += 45) {
      final x = (lng + 180) / 360 * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (var lat = -90; lat <= 90; lat += 30) {
      final y = (90 - lat) / 180 * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final continentPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.18, size.width * 0.20,
          size.height * 0.44),
      continentPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.34, size.height * 0.14, size.width * 0.22,
          size.height * 0.20),
      continentPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.46, size.height * 0.28, size.width * 0.18,
          size.height * 0.38),
      continentPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.68, size.height * 0.18, size.width * 0.20,
          size.height * 0.28),
      continentPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.78, size.height * 0.58, size.width * 0.10,
          size.height * 0.12),
      continentPaint,
    );
  }

  @override
  bool shouldRepaint(_MiniMapPreviewPainter oldDelegate) => false;
}
