import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_street_view/flutter_google_street_view.dart' as street_view;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KuglaApp());
}

class KuglaApp extends StatelessWidget {
  const KuglaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kugla',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const List<Map<String, double>> _regions = [
    // USA / Canada
    {'minLat': 24.0, 'maxLat': 49.0, 'minLng': -125.0, 'maxLng': -66.0},
    // Western Europe
    {'minLat': 36.0, 'maxLat': 60.0, 'minLng': -10.0, 'maxLng': 30.0},
    // Eastern Europe / Russia (west)
    {'minLat': 45.0, 'maxLat': 62.0, 'minLng': 30.0, 'maxLng': 60.0},
    // Australia
    {'minLat': -38.0, 'maxLat': -20.0, 'minLng': 114.0, 'maxLng': 153.0},
    // Brazil
    {'minLat': -30.0, 'maxLat': 5.0, 'minLng': -55.0, 'maxLng': -35.0},
    // Japan / South Korea
    {'minLat': 31.0, 'maxLat': 45.0, 'minLng': 129.0, 'maxLng': 145.0},
    // Mexico / Central America
    {'minLat': 15.0, 'maxLat': 30.0, 'minLng': -117.0, 'maxLng': -87.0},
    // South Africa
    {'minLat': -34.0, 'maxLat': -22.0, 'minLng': 16.0, 'maxLng': 32.0},
    // India
    {'minLat': 8.0, 'maxLat': 28.0, 'minLng': 68.0, 'maxLng': 88.0},
    // Thailand / SE Asia
    {'minLat': 1.0, 'maxLat': 20.0, 'minLng': 100.0, 'maxLng': 120.0},
  ];

  final _random = Random();

  LatLng _getRandomGlobalLocation() {
    final region = _regions[_random.nextInt(_regions.length)];
    final lat = region['minLat']! +
        _random.nextDouble() * (region['maxLat']! - region['minLat']!);
    final lng = region['minLng']! +
        _random.nextDouble() * (region['maxLng']! - region['minLng']!);
    return LatLng(lat, lng);
  }

  late LatLng _targetPosition;
  LatLng? _userGuess;
  bool _loadingNewLocation = false;
  double _distance = 0;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _targetPosition = _getRandomGlobalLocation();
  }

  void _startNewRound() {
    setState(() {
      _targetPosition = _getRandomGlobalLocation();
      _userGuess = null;
      _loadingNewLocation = false;
    });
  }

  /// Called when Street View panorama changes. If null it means no coverage —
  /// automatically retry with a new random location.
  void _onPanoramaChange(street_view.StreetViewPanoramaChange? change) {
    if (change == null || change.panoramaId == null) {
      if (!_loadingNewLocation) {
        setState(() => _loadingNewLocation = true);
        // Short delay to avoid hammering the API
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _startNewRound();
        });
      }
    } else {
      if (_loadingNewLocation) {
        setState(() => _loadingNewLocation = false);
      }
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

  double _toRad(double deg) => deg * pi / 180;

  void _onGuessPressed() {
    if (_userGuess == null) return;
    _distance = _calculateDistance(_userGuess!, _targetPosition);
    _score = max(0, (5000 - (_distance * 10)).toInt());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Round Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${_distance.toStringAsFixed(1)} km'),
            const SizedBox(height: 4),
            Text('Score: $_score / 5000 pts',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewRound();
            },
            child: const Text('NEXT ROUND'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kugla'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_loadingNewLocation)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Street View — top 70%
          Expanded(
            flex: 7,
            child: Stack(
              children: [
                street_view.FlutterGoogleStreetView(
                  key: ValueKey(_targetPosition),
                  initPos: _targetPosition,
                  streetNamesEnabled: false,
                  userNavigationEnabled: true,
                  onStreetViewPanoramaChange: _onPanoramaChange,
                ),
                if (_loadingNewLocation)
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 12),
                          Text('Finding a new location…',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Guessing map — bottom 30%
          Expanded(
            flex: 3,
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: const CameraPosition(
                target: LatLng(20, 0),
                zoom: 1,
              ),
              onTap: (pos) => setState(() => _userGuess = pos),
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
            ),
          ),
        ],
      ),
      floatingActionButton: (_userGuess != null && !_loadingNewLocation)
          ? FloatingActionButton.extended(
              onPressed: _onGuessPressed,
              label: const Text('GUESS'),
              icon: const Icon(Icons.location_on),
            )
          : null,
    );
  }
}
