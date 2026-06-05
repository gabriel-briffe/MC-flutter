import 'package:flutter/material.dart';

/// Burger control that opens the map settings menu.
class MapMenuButton extends StatelessWidget {
  const MapMenuButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open menu',
      child: FloatingActionButton(
        onPressed: onPressed,
        elevation: 2,
        child: const Icon(Icons.menu),
      ),
    );
  }
}
