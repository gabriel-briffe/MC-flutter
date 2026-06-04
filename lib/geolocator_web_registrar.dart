import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:geolocator_web/geolocator_web.dart';

/// Registers [GeolocatorPlugin] for Flutter web (html only).
void registerGeolocatorWebPlugin() {
  GeolocatorPlugin.registerWith(webPluginRegistrar);
}
