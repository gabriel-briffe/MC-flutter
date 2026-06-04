import 'package:flutter/material.dart';

/// Map data attribution overlay (OSM + Mapterhorn).
class AttributionBadge extends StatelessWidget {
  const AttributionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: const Color(0xFF333333));

    return Semantics(
      label: 'Map data attribution: OpenStreetMap and Mapterhorn',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Color(0x33000000))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text('© OpenStreetMap · © Mapterhorn', style: labelStyle),
        ),
      ),
    );
  }
}
