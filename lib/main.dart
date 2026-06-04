import 'package:flutter/foundation.dart';
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

/// Full-screen MapLibre map: OSM + Mapterhorn hillshade, optional 3D view.
class OsmMapPage extends StatefulWidget {
  const OsmMapPage({super.key});

  @override
  State<OsmMapPage> createState() => _OsmMapPageState();
}

class _OsmMapPageState extends State<OsmMapPage> {
  static const _initialCamera = CameraPosition(
    target: LatLng(46.82, 8.23),
    zoom: 10,
  );

  static const _camera3d = (
    tilt: 60.0,
    bearing: -18.6,
  );

  MapLibreMapController? _controller;
  bool _is3d = false;
  bool _isToggling3d = false;

  /// Toggles oblique 3D view by pitching the camera. Terrain stays loaded in the
  /// style; we do not call [MapLibreMapController.setStyle] (broken/slow on web)
  /// or [MapLibreMapController.queryCameraPosition] (unimplemented on web).
  Future<void> _toggle3d() async {
    final controller = _controller;
    if (controller == null || _isToggling3d) return;

    setState(() => _isToggling3d = true);
    final enable3d = !_is3d;

    try {
      if (enable3d) {
        await controller.animateCamera(CameraUpdate.tiltTo(_camera3d.tilt));
        await controller.animateCamera(
          CameraUpdate.bearingTo(_camera3d.bearing),
        );
      } else {
        await controller.animateCamera(CameraUpdate.tiltTo(0));
        await controller.animateCamera(CameraUpdate.bearingTo(0));
      }
      if (mounted) {
        setState(() => _is3d = enable3d);
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('3D toggle failed: $e\n$stack');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not switch 3D view. Try zooming in closer.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isToggling3d = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: mapStyleString,
            initialCameraPosition: _initialCamera,
            onMapCreated: (controller) => _controller = controller,
            trackCameraPosition: true,
            compassEnabled: true,
            compassViewPosition: CompassViewPosition.topRight,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: true,
            attributionButtonPosition: AttributionButtonPosition.bottomLeft,
          ),
          Positioned(
            top: topInset + 52,
            right: 12,
            child: _ThreeDToggle(
              active: _is3d,
              busy: _isToggling3d,
              onPressed: _toggle3d,
            ),
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

/// Toggle control placed just below the map compass (top-right).
class _ThreeDToggle extends StatelessWidget {
  const _ThreeDToggle({
    required this.active,
    required this.busy,
    required this.onPressed,
  });

  final bool active;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(4),
      color: active ? const Color(0xFF2D3748) : Colors.white,
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: active ? Colors.white : const Color(0xFF2D3748),
                    ),
                  )
                : Text(
                    '3D',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : const Color(0xFF2D3748),
                    ),
                  ),
          ),
        ),
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
          '© OpenStreetMap · © Mapterhorn',
          style: TextStyle(fontSize: 11, color: Color(0xFF333333)),
        ),
      ),
    );
  }
}
