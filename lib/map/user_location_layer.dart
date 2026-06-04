import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Draws the device position on the map and a bearing needle when heading is known.
class UserLocationLayer {
  UserLocationLayer({this.onPermissionDenied});

  /// Called when the user denies location access or it is blocked.
  final VoidCallback? onPermissionDenied;

  static const _logName = 'mc_flutter.location';

  /// Minimum speed (m/s) before trusting GPS course as bearing.
  static const _minSpeedForHeading = 0.5;

  /// Needle length in meters on the ground.
  static const _needleMeters = 22.0;

  MapLibreMapController? _controller;
  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;
  double? _lastBearing;

  Circle? _dot;
  Line? _bearingNeedle;

  bool _started = false;
  bool _permissionDeniedNotified = false;

  void attach(MapLibreMapController controller) {
    _controller = controller;
  }

  /// Re-applies markers after a style reload and starts tracking on first load.
  Future<void> onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;

    await _clearMarkers();

    if (_lastPosition != null) {
      await _syncMarkers(_lastPosition!, _lastBearing);
    }

    if (!_started) {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    if (_started) return;
    _started = true;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      developer.log(
        'Location services are disabled',
        name: _logName,
        level: 900,
      );
      _notifyPermissionDenied();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      developer.log('Location permission denied', name: _logName, level: 900);
      _notifyPermissionDenied();
      return;
    }

    _positionSub ??=
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 2,
          ),
        ).listen(
          _onPosition,
          onError: (Object error, StackTrace stackTrace) {
            developer.log(
              'Position stream error',
              name: _logName,
              level: 1000,
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
  }

  void _onPosition(Position position) {
    _lastPosition = position;

    final bearing = _resolveBearing(position);
    if (bearing != null) {
      _lastBearing = bearing;
    }

    final controller = _controller;
    if (controller == null) return;

    unawaited(_syncMarkers(position, _lastBearing));
  }

  /// Uses GPS course when moving; keeps the last bearing when stationary.
  double? _resolveBearing(Position position) {
    if (position.speed >= _minSpeedForHeading) {
      return position.heading;
    }
    return _lastBearing;
  }

  Future<void> _syncMarkers(Position position, double? bearing) async {
    final controller = _controller;
    if (controller == null) return;

    final latLng = LatLng(position.latitude, position.longitude);

    if (_dot == null) {
      _dot = await controller.addCircle(
        CircleOptions(
          geometry: latLng,
          circleRadius: 8,
          circleColor: '#1E88E5',
          circleOpacity: 1,
          circleStrokeWidth: 2.5,
          circleStrokeColor: '#FFFFFF',
          circleStrokeOpacity: 1,
        ),
      );
    } else {
      await controller.updateCircle(_dot!, CircleOptions(geometry: latLng));
    }

    if (bearing == null) {
      if (_bearingNeedle != null) {
        await controller.removeLine(_bearingNeedle!);
        _bearingNeedle = null;
      }
      return;
    }

    final tip = _destination(latLng, bearing, _needleMeters);
    if (_bearingNeedle == null) {
      _bearingNeedle = await controller.addLine(
        LineOptions(
          geometry: [latLng, tip],
          lineColor: '#1565C0',
          lineWidth: 3.5,
          lineOpacity: 0.95,
          lineJoin: 'round',
        ),
      );
    } else {
      await controller.updateLine(
        _bearingNeedle!,
        LineOptions(geometry: [latLng, tip]),
      );
    }
  }

  Future<void> _clearMarkers() async {
    final controller = _controller;
    if (controller == null) return;

    if (_dot != null) {
      await controller.removeCircle(_dot!);
      _dot = null;
    }
    if (_bearingNeedle != null) {
      await controller.removeLine(_bearingNeedle!);
      _bearingNeedle = null;
    }
  }

  void _notifyPermissionDenied() {
    if (_permissionDeniedNotified) return;
    _permissionDeniedNotified = true;
    onPermissionDenied?.call();
  }

  void dispose() {
    unawaited(_positionSub?.cancel());
    _positionSub = null;
    final controller = _controller;
    if (controller != null) {
      unawaited(_clearMarkers());
    }
    _controller = null;
  }

  /// Point [distanceMeters] from [from] along [bearingDeg] (degrees, clockwise from north).
  static LatLng _destination(
    LatLng from,
    double bearingDeg,
    double distanceMeters,
  ) {
    const earthRadius = 6378137.0;
    final bearing = bearingDeg * math.pi / 180;
    final lat1 = from.latitude * math.pi / 180;
    final lng1 = from.longitude * math.pi / 180;
    final angular = distanceMeters / earthRadius;

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(angular) +
          math.cos(lat1) * math.sin(angular) * math.cos(bearing),
    );
    final lng2 =
        lng1 +
        math.atan2(
          math.sin(bearing) * math.sin(angular) * math.cos(lat1),
          math.cos(angular) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(lat2 * 180 / math.pi, lng2 * 180 / math.pi);
  }
}
