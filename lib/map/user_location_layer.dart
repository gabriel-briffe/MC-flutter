import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Single arrowhead marker for device position and bearing.
class UserLocationLayer {
  UserLocationLayer({this.onPermissionDenied});

  /// Called when the user denies location access or it is blocked.
  final void Function()? onPermissionDenied;

  static const _logName = 'mc_flutter.location';
  static const _arrowImageId = 'user-location-arrow';

  /// Minimum speed (m/s) before trusting GPS course as bearing.
  static const _minSpeedForHeading = 0.5;

  MapLibreMapController? _controller;
  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;
  double? _lastBearing;

  Symbol? _arrow;

  bool _started = false;
  bool _permissionDeniedNotified = false;

  void attach(MapLibreMapController controller) {
    _controller = controller;
  }

  /// Re-applies the marker after a style reload and starts tracking on first load.
  Future<void> onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;

    await _clearMarker();
    await _registerArrowImage();

    if (_lastPosition != null) {
      await _syncMarker(_lastPosition!, _lastBearing ?? 0);
    }

    if (!_started) {
      await _startTracking();
    }
  }

  Future<void> _registerArrowImage() async {
    final controller = _controller;
    if (controller == null) return;

    final data = await rootBundle.load('assets/user_location_arrow.png');
    await controller.addImage(
      _arrowImageId,
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
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

    unawaited(_syncMarker(position, _lastBearing ?? 0));
  }

  /// Uses GPS course when moving; keeps the last bearing when stationary.
  double? _resolveBearing(Position position) {
    if (position.speed >= _minSpeedForHeading) {
      return position.heading;
    }
    return _lastBearing;
  }

  Future<void> _syncMarker(Position position, double bearing) async {
    final controller = _controller;
    if (controller == null) return;

    final latLng = LatLng(position.latitude, position.longitude);

    if (_arrow == null) {
      _arrow = await controller.addSymbol(
        SymbolOptions(
          geometry: latLng,
          iconImage: _arrowImageId,
          iconSize: 1.25,
          iconRotate: bearing,
          iconAnchor: 'center',
          iconOpacity: 1,
        ),
      );
    } else {
      await controller.updateSymbol(
        _arrow!,
        SymbolOptions(geometry: latLng, iconRotate: bearing),
      );
    }
  }

  Future<void> _clearMarker() async {
    final controller = _controller;
    if (controller == null) return;

    if (_arrow != null) {
      await controller.removeSymbol(_arrow!);
      _arrow = null;
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
      unawaited(_clearMarker());
    }
    _controller = null;
  }
}
