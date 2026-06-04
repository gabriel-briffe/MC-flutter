import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG arrowhead aligned to GPS bearing, drawn above the map in screen space.
class UserLocationMarker extends StatelessWidget {
  const UserLocationMarker({
    super.key,
    required this.screenPoint,
    required this.bearingDegrees,
    required this.mapBearingDegrees,
  });

  static const markerSize = 48.0;

  final Offset? screenPoint;
  final double bearingDegrees;
  final double mapBearingDegrees;

  @override
  Widget build(BuildContext context) {
    final point = screenPoint;
    if (point == null) {
      return const SizedBox.shrink();
    }

    // Bearing relative to the map canvas (accounts for map rotation).
    final rotationRad = (bearingDegrees - mapBearingDegrees) * math.pi / 180;

    return Positioned(
      left: point.dx - markerSize / 2,
      top: point.dy - markerSize / 2,
      width: markerSize,
      height: markerSize,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: rotationRad,
          child: SvgPicture.asset(
            'assets/user_location_arrow.svg',
            width: markerSize,
            height: markerSize,
          ),
        ),
      ),
    );
  }
}
