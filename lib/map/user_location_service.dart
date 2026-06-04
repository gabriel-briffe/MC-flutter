import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'web_geolocation_stub.dart'
    if (dart.library.html) 'web_geolocation.dart';

/// Tracks device location and bearing for map overlays.
///
/// Permission flow follows the official geolocator example:
/// https://github.com/Baseflow/flutter-geolocator/tree/main/geolocator#example
///
/// On web, location uses [WebGeolocation] (JSON parsing) to avoid release-mode
/// interop errors from [geolocator_web]. Permission is requested via the
/// browser prompt when calling `getCurrentPosition`.
class UserLocationService extends ChangeNotifier {
  UserLocationService({this.onPermissionDenied});

  final void Function()? onPermissionDenied;

  static const _logName = 'mc_flutter.location';
  static const _minSpeedForHeading = 0.5;

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

  /// Begins permission checks (non-web), an immediate fix, then a stream.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      await _determinePositionAndTrack();
    } on PermissionDeniedException catch (error) {
      _status = 'Permission denied';
      developer.log(
        'Permission denied',
        name: _logName,
        level: 900,
        error: error,
      );
      _notifyPermissionDenied();
      notifyListeners();
    } on LocationServiceDisabledException {
      _status = 'Location services disabled';
      developer.log(_status, name: _logName, level: 900);
      _notifyPermissionDenied();
      notifyListeners();
    } on Object catch (error, stackTrace) {
      _status = 'Location error: ${_describeError(error)}';
      developer.log(
        'Location failed',
        name: _logName,
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
      notifyListeners();
    }
  }

  static String _describeError(Object error) {
    if (error is Exception && error.toString() == 'Exception') {
      return error.runtimeType.toString();
    }
    return error.toString();
  }

  /// Official geolocator pattern: services → permission → current position.
  Future<void> _determinePositionAndTrack() async {
    _status = 'Initializing…';
    notifyListeners();

    if (kIsWeb) {
      _status = 'Requesting location (browser prompt)…';
      notifyListeners();

      final initial = await WebGeolocation.getCurrentPosition();
      _applyPosition(initial);

      await _positionSub?.cancel();
      _positionSub = WebGeolocation.watchPosition().listen(
        _applyPosition,
        onError: _onStreamError,
      );
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      _status = 'Requesting permission…';
      notifyListeners();
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const PermissionDeniedException(
          'Location permissions are denied',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Location permissions are permanently denied',
      );
    }

    _status = 'Acquiring location…';
    notifyListeners();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
    );

    final initial = await Geolocator.getCurrentPosition(
      locationSettings: settings,
    );
    _applyPosition(initial);

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(_applyPosition, onError: _onStreamError);
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    _status = 'Stream error: ${_describeError(error)}';
    developer.log(
      'Position stream error',
      name: _logName,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    notifyListeners();
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
