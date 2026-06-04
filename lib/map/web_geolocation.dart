import 'dart:async';
import 'dart:js_interop';

import 'package:geolocator/geolocator.dart';
import 'package:web/web.dart' as web;

/// Browser geolocation with JSON parsing to avoid release-mode interop issues
/// in [geolocator_web] (Invalid argument when reading [GeolocationPosition]).
class WebGeolocation {
  static const _timeoutMs = 30000;
  static const _maximumAgeMs = 60000;

  static Future<Position> getCurrentPosition({
    bool enableHighAccuracy = true,
  }) async {
    final completer = Completer<Position>();

    web.window.navigator.geolocation.getCurrentPosition(
      ((web.GeolocationPosition result) {
        try {
          completer.complete(_positionFromJson(result));
        } on Object catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      }).toJS,
      ((web.GeolocationPositionError error) {
        completer.completeError(_positionError(error));
      }).toJS,
      web.PositionOptions(
        enableHighAccuracy: enableHighAccuracy,
        timeout: _timeoutMs,
        maximumAge: _maximumAgeMs,
      ),
    );

    return completer.future;
  }

  static Stream<Position> watchPosition({bool enableHighAccuracy = true}) {
    late final StreamController<Position> controller;
    int? watchId;

    controller = StreamController<Position>(
      sync: true,
      onCancel: () {
        if (watchId != null) {
          web.window.navigator.geolocation.clearWatch(watchId!);
        }
      },
      onListen: () {
        watchId = web.window.navigator.geolocation.watchPosition(
          ((web.GeolocationPosition result) {
            try {
              controller.add(_positionFromJson(result));
            } on Object catch (error, stackTrace) {
              controller.addError(error, stackTrace);
            }
          }).toJS,
          ((web.GeolocationPositionError error) {
            controller.addError(_positionError(error));
          }).toJS,
          web.PositionOptions(
            enableHighAccuracy: enableHighAccuracy,
            timeout: _timeoutMs,
            maximumAge: _maximumAgeMs,
          ),
        );
      },
    );

    return controller.stream;
  }

  static Position _positionFromJson(web.GeolocationPosition result) {
    final root = result.toJSON().dartify()! as Map<Object?, Object?>;
    final coords = root['coords']! as Map<Object?, Object?>;
    final timestampMs = _num(root['timestamp']).round();

    return Position(
      latitude: _num(coords['latitude']),
      longitude: _num(coords['longitude']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      altitude: _numOrNull(coords['altitude']) ?? 0.0,
      altitudeAccuracy: _numOrNull(coords['altitudeAccuracy']) ?? 0.0,
      accuracy: _numOrNull(coords['accuracy']) ?? 0.0,
      heading: _numOrNull(coords['heading']) ?? 0.0,
      headingAccuracy: 0.0,
      speed: _numOrNull(coords['speed']) ?? 0.0,
      speedAccuracy: 0.0,
      isMocked: false,
    );
  }

  static double _num(Object? value) => (value as num).toDouble();

  static double? _numOrNull(Object? value) =>
      value == null ? null : (value as num).toDouble();

  static Exception _positionError(web.GeolocationPositionError error) {
    return switch (error.code) {
      1 => PermissionDeniedException(error.message),
      2 => PositionUpdateException(error.message),
      3 => TimeoutException(error.message),
      _ => Exception('Geolocation error (${error.code}): ${error.message}'),
    };
  }
}
