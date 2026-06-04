import 'package:geolocator/geolocator.dart';

/// Stub: web geolocation is only used when `dart.library.html` is available.
class WebGeolocation {
  static Future<Position> getCurrentPosition({bool enableHighAccuracy = true}) {
    throw UnsupportedError('WebGeolocation is only available on web');
  }

  static Stream<Position> watchPosition({bool enableHighAccuracy = true}) {
    throw UnsupportedError('WebGeolocation is only available on web');
  }
}
