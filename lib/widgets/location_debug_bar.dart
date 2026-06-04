import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Bottom overlay showing live location values for debugging.
class LocationDebugBar extends StatelessWidget {
  const LocationDebugBar({
    super.key,
    required this.status,
    this.position,
    this.screenPoint,
  });

  final String status;
  final Position? position;
  final Offset? screenPoint;

  @override
  Widget build(BuildContext context) {
    final pos = position;
    final screen = screenPoint;

    final coords = pos == null
        ? '—'
        : '${pos.latitude.toStringAsFixed(6)}, '
              '${pos.longitude.toStringAsFixed(6)}';

    final accuracy = pos == null
        ? '—'
        : '±${pos.accuracy.toStringAsFixed(0)} m';

    final screenText = screen == null
        ? '—'
        : '${screen.dx.toStringAsFixed(0)}, ${screen.dy.toStringAsFixed(0)}';

    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
              height: 1.35,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Status: $status'),
                Text('Lat, lng: $coords'),
                Text('Accuracy: $accuracy'),
                Text('Screen px: $screenText'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
