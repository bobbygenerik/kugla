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

  const GameScreen({
    super.key,
    required this.settings,
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

  LocationSeed get _currentSeed => _roundSeeds[_roundIndex];

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _roundSeeds = [...streetViewSeeds]..shuffle(_random);
    _roundSeeds = _roundSeeds.take(widget.settings.roundsPerMission).toList();
    _beginRound();
  }

  @override
  void dispose() {
    _streetViewTimeout?.cancel();
    super.dispose();
  }

  void _beginRound() {
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

  void _toggleMapExpanded([bool? expanded]) {
    setState(() {
      _mapExpanded = expanded ?? !_mapExpanded;
    });
  }

  void _skipRound() {
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
    final guess = _userGuess;
    if (guess == null) return;

    final target = LatLng(_currentSeed.latitude, _currentSeed.longitude);
    final distance = _calculateDistance(guess, target);
    final score = max(0, (5000 - (distance * 8)).round());

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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          _roundIndex == _roundSeeds.length - 1
              ? 'Mission complete'
              : 'Round results',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${_currentSeed.name}, ${_currentSeed.country}'),
            const SizedBox(height: 6),
            Text('Distance: ${distance.toStringAsFixed(1)} km'),
            const SizedBox(height: 6),
            Text(
              'Score: $score / 5000',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              _roundIndex == _roundSeeds.length - 1 ? 'Finish' : 'Next round',
            ),
          ),
        ],
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
                          _HudChip(
                            icon: Icons.track_changes_rounded,
                            label: 'Score $missionScore',
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
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: !_mapExpanded,
                                child: GoogleMap(
                                  mapType: MapType.normal,
                                  initialCameraPosition: const CameraPosition(
                                    target: LatLng(20, 0),
                                    zoom: 1.2,
                                  ),
                                  onTap: (pos) =>
                                      setState(() => _userGuess = pos),
                                  markers: _userGuess == null
                                      ? {}
                                      : {
                                          Marker(
                                            markerId: const MarkerId('guess'),
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
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(
                                          alpha: _mapExpanded ? 0.12 : 0.10),
                                      Colors.black.withValues(
                                          alpha: _mapExpanded ? 0.22 : 0.52),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (!_mapExpanded)
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
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Tap to guess',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Padding(
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
                                    const Spacer(),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xCC08111F),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                            color: KuglaColors.stroke),
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
                                                        () =>
                                                            _userGuess = null),
                                                    icon: const Icon(Icons
                                                        .restart_alt_rounded),
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
                                                    icon: const Icon(Icons
                                                        .check_circle_rounded),
                                                    label: const Text(
                                                        'Lock guess'),
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
                          ],
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

class _HudChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HudChip({
    required this.icon,
    required this.label,
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
            Icon(icon, size: 16, color: KuglaColors.cyan),
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
