import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Tracks device location and bearing for map overlays.
///
/// Follows the official geolocator example:
/// https://github.com/Baseflow/flutter-geolocator/tree/main/geolocator#example
///
/// On web, [Geolocator.checkPermission] is skipped (Permissions API can hang);
/// the browser prompts when [Geolocator.getCurrentPosition] runs.
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
      _status = 'Location error: ${error.runtimeType}: $error';
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

  /// Official geolocator pattern: services → permission → position → stream.
  Future<void> _determinePositionAndTrack() async {
    _status = 'Initializing…';
    notifyListeners();

    if (!kIsWeb) {
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
    } else {
      _status = 'Requesting location (browser prompt)…';
      notifyListeners();
    }

    _status = 'Acquiring location…';
    notifyListeners();

    // Official example ends with plain getCurrentPosition(); keep settings minimal.
    final initial = await Geolocator.getCurrentPosition();
    _applyPosition(initial);

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream().listen(
      _applyPosition,
      onError: (Object error, StackTrace stackTrace) {
        _status = 'Stream error: ${error.runtimeType}: $error';
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
