import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../menu/map_menu_page.dart';
import '../widgets/map_menu_button.dart';
import '../widgets/user_location_marker.dart';
import 'map_style.dart';
import 'user_location_service.dart';

/// Full-screen MapLibre map with OSM tiles and Mapterhorn relief.
class OsmMapPage extends StatefulWidget {
  const OsmMapPage({super.key});

  @override
  State<OsmMapPage> createState() => _OsmMapPageState();
}

class _OsmMapPageState extends State<OsmMapPage> {
  static const _initialCamera = CameraPosition(
    target: LatLng(46.82, 8.23),
    zoom: 10,
  );

  static const _styleLoadTimeout = Duration(seconds: 30);

  MapLibreMapController? _controller;
  bool _is3d = false;
  bool _isToggling3d = false;

  Completer<void>? _styleLoadCompleter;
  int _styleLoadGeneration = 0;

  late final UserLocationService _userLocation = UserLocationService(
    onPermissionDenied: _onLocationPermissionDenied,
  );

  Offset? _markerScreenPoint;

  @override
  void initState() {
    super.initState();
    _userLocation.addListener(_onUserLocationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_userLocation.start());
    });
  }

  void _onUserLocationChanged() {
    unawaited(_updateMarkerScreenPoint());
    setState(() {});
  }

  Future<void> _updateMarkerScreenPoint() async {
    final controller = _controller;
    final position = _userLocation.position;
    if (controller == null || position == null) {
      if (_markerScreenPoint != null && mounted) {
        setState(() => _markerScreenPoint = null);
      }
      return;
    }

    try {
      final point = await controller.toScreenLocation(
        LatLng(position.latitude, position.longitude),
      );
      if (!mounted) return;
      setState(
        () =>
            _markerScreenPoint = Offset(point.x.toDouble(), point.y.toDouble()),
      );
    } on Object catch (error, stackTrace) {
      developer.log(
        'toScreenLocation failed',
        name: 'mc_flutter.map',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _onStyleLoaded() {
    final completer = _styleLoadCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    unawaited(_updateMarkerScreenPoint());
  }

  void _onCameraMove(CameraPosition _) {
    unawaited(_updateMarkerScreenPoint());
  }

  void _onLocationPermissionDenied() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Location access is needed to show your position on the map.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _openMenu() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => MapMenuPage(
          is3d: _is3d,
          isBusy: _isToggling3d,
          onTerrainModeChanged: _setTerrain3d,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userLocation.removeListener(_onUserLocationChanged);
    _userLocation.dispose();
    super.dispose();
  }

  /// Updates terrain exaggeration (0 = flat 2D, 1 = 3D mesh) via style reload.
  Future<void> _applyTerrainStyle(bool terrain3d) async {
    final controller = _controller;
    if (controller == null) return;

    final generation = ++_styleLoadGeneration;
    final completer = Completer<void>();
    _styleLoadCompleter = completer;

    await controller.setStyle(buildMapStyle(terrain3d: terrain3d));

    await completer.future.timeout(_styleLoadTimeout);

    if (generation != _styleLoadGeneration) {
      throw StateError('Style load superseded');
    }
  }

  /// Switches between 2D (flat) and 3D terrain via style reload (no camera move).
  Future<void> _setTerrain3d(bool enable3d) async {
    final controller = _controller;
    if (controller == null || _isToggling3d || _is3d == enable3d) return;

    setState(() => _isToggling3d = true);

    try {
      await _applyTerrainStyle(enable3d);
      if (mounted) {
        setState(() => _is3d = enable3d);
      }
    } on TimeoutException {
      developer.log(
        'Timed out loading map style',
        name: 'mc_flutter.map',
        level: 1000,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Map style took too long to load. Try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      developer.log(
        'Terrain mode change failed',
        name: 'mc_flutter.map',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not switch map mode. Try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _styleLoadCompleter = null;
      if (mounted) {
        setState(() => _isToggling3d = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapBearing = _controller?.cameraPosition?.bearing ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: mapStyleString,
            initialCameraPosition: _initialCamera,
            onMapCreated: (controller) {
              _controller = controller;
            },
            onStyleLoadedCallback: _onStyleLoaded,
            onCameraMove: _onCameraMove,
            trackCameraPosition: true,
            compassEnabled: true,
            compassViewPosition: CompassViewPosition.topRight,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: _is3d,
            attributionButtonPosition: null,
          ),
          UserLocationMarker(
            screenPoint: _markerScreenPoint,
            bearingDegrees: _userLocation.bearing,
            mapBearingDegrees: mapBearing,
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: MapMenuButton(onPressed: () => unawaited(_openMenu())),
            ),
          ),
        ],
      ),
    );
  }
}
