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
  static const _permissionTimeout = Duration(seconds: 3);
  static const _fixTimeout = Duration(seconds: 30);

  Position? _position;
  double _bearing = 0;
  String _status = 'Waiting to start…';
  StreamSubscription<Position>? _positionSub;

  bool _started = false;
  bool _permissionDeniedNotified = false;

  Position? get position => _position;

  double get bearing => _bearing;

  /// Human-readable status for debugging (permission, errors, etc.).
  String get status => _status;

  LocationSettings get _locationSettings => kIsWeb
      ? WebSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 2,
          timeLimit: _fixTimeout,
          maximumAge: const Duration(seconds: 30),
        )
      : const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 2,
          timeLimit: _fixTimeout,
        );

  /// Begins permission checks, an immediate fix, then a position stream.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _status = 'Initializing…';
    notifyListeners();

    if (!kIsWeb) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _status = 'Location services disabled';
        developer.log(_status, name: _logName, level: 900);
        _notifyPermissionDenied();
        notifyListeners();
        return;
      }
    }

    final permission = await _resolvePermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _status = 'Permission denied';
      developer.log(_status, name: _logName, level: 900);
      _notifyPermissionDenied();
      notifyListeners();
      return;
    }

    await _beginLocationUpdates();
  }

  /// Web [Permissions API] can hang; [unableToDetermine] should still prompt via GPS.
  Future<LocationPermission> _resolvePermission() async {
    _status = 'Checking permission…';
    notifyListeners();

    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission().timeout(
        _permissionTimeout,
      );
    } on TimeoutException {
      developer.log(
        'checkPermission timed out; continuing (web Permissions API)',
        name: _logName,
        level: 900,
      );
      permission = LocationPermission.unableToDetermine;
    }

    if (permission == LocationPermission.denied) {
      _status = 'Requesting permission…';
      notifyListeners();
      try {
        permission = await Geolocator.requestPermission().timeout(_fixTimeout);
      } on TimeoutException {
        permission = LocationPermission.denied;
      }
    }

    return permission;
  }

  Future<void> _beginLocationUpdates() async {
    _status = 'Acquiring location…';
    notifyListeners();

    final settings = _locationSettings;

    try {
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      _applyPosition(initial);
    } on TimeoutException {
      _status = 'Location timed out ($_fixTimeout)';
      developer.log(_status, name: _logName, level: 900);
      notifyListeners();
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

    await _positionSub?.cancel();
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
