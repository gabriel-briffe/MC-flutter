import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'map_style.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const McFlutterApp());
}

class McFlutterApp extends StatelessWidget {
  const McFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OsmMapPage(),
    );
  }
}

/// Full-screen MapLibre map with OpenStreetMap raster tiles.
class OsmMapPage extends StatelessWidget {
  const OsmMapPage({super.key});

  static const _initialCamera = CameraPosition(
    target: LatLng(46.82, 8.23),
    zoom: 9,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: mapStyleString,
            initialCameraPosition: _initialCamera,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: true,
            attributionButtonPosition: AttributionButtonPosition.bottomLeft,
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: _AttributionBadge(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributionBadge extends StatelessWidget {
  const _AttributionBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            color: Color(0x33000000),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 11, color: Color(0xFF333333)),
        ),
      ),
    );
  }
}
