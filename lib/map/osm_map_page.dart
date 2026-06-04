import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../widgets/attribution_badge.dart';
import '../widgets/three_d_toggle.dart';
import 'map_style.dart';

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

  void _onStyleLoaded() {
    final completer = _styleLoadCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
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

  /// Toggles 3D terrain mesh only (no camera movement).
  Future<void> _toggle3d() async {
    final controller = _controller;
    if (controller == null || _isToggling3d) return;

    setState(() => _isToggling3d = true);
    final enable3d = !_is3d;

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
        '3D toggle failed',
        name: 'mc_flutter.map',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not switch 3D terrain. Try again.'),
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
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: mapStyleString,
            initialCameraPosition: _initialCamera,
            onMapCreated: (controller) => _controller = controller,
            onStyleLoadedCallback: _onStyleLoaded,
            trackCameraPosition: true,
            compassEnabled: true,
            compassViewPosition: CompassViewPosition.topRight,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: true,
            attributionButtonPosition: AttributionButtonPosition.bottomLeft,
          ),
          Positioned(
            top: topInset + 52,
            right: 12,
            child: ThreeDToggle(
              active: _is3d,
              busy: _isToggling3d,
              onPressed: _toggle3d,
            ),
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: AttributionBadge(),
            ),
          ),
        ],
      ),
    );
  }
}
