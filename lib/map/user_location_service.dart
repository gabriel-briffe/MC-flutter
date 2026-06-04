import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Tracks device location and bearing for map overlays.
class UserLocationService extends ChangeNotifier {
  UserLocationService({this.onPermissionDenied});

  final void Function()? onPermissionDenied;

  static const _logName = 'mc_flutter.location';
  static const _minSpeedForHeading = 0.5;

  Position? _position;
  double _bearing = 0;
  String _status = 'Starting…';
  StreamSubscription<Position>? _positionSub;

  bool _started = false;
  bool _permissionDeniedNotified = false;

  Position? get position => _position;

  double get bearing => _bearing;

  /// Human-readable status for debugging (permission, errors, etc.).
  String get status => _status;

  /// Begins permission checks, an immediate fix, then a position stream.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _status = 'Location services disabled';
      developer.log(_status, name: _logName, level: 900);
      _notifyPermissionDenied();
      notifyListeners();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      _status = 'Requesting permission…';
      notifyListeners();
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _status = 'Permission denied';
      developer.log(_status, name: _logName, level: 900);
      _notifyPermissionDenied();
      notifyListeners();
      return;
    }

    _status = 'Acquiring location…';
    notifyListeners();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 2,
    );

    try {
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      _applyPosition(initial);
    } on Object catch (error, stackTrace) {
      _status = 'Location error: $error';
      developer.log(
        'getCurrentPosition failed',
        name: _logName,
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
      notifyListeners();
    }

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          _applyPosition,
          onError: (Object error, StackTrace stackTrace) {
            _status = 'Stream error: $error';
            developer.log(
              'Position stream error',
              name: _logName,
              level: 1000,
              error: error,
              stackTrace: stackTrace,
            );
            notifyListeners();
          },
        );
  }

  void _applyPosition(Position position) {
    _position = position;

    if (position.speed >= _minSpeedForHeading) {
      _bearing = position.heading;
    }

    _status = 'Tracking';
    notifyListeners();
  }

  void _notifyPermissionDenied() {
    if (_permissionDeniedNotified) return;
    _permissionDeniedNotified = true;
    onPermissionDenied?.call();
  }

  @override
  void dispose() {
    unawaited(_positionSub?.cancel());
    _positionSub = null;
    super.dispose();
  }
}
