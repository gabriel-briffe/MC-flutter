import 'dart:async';

import 'package:flutter/material.dart';

/// Settings menu opened from the map (terrain mode, etc.).
class MapMenuPage extends StatefulWidget {
  const MapMenuPage({
    super.key,
    required this.is3d,
    required this.isBusy,
    required this.onTerrainModeChanged,
  });

  final bool is3d;
  final bool isBusy;
  final Future<void> Function(bool enable3d) onTerrainModeChanged;

  @override
  State<MapMenuPage> createState() => _MapMenuPageState();
}

class _MapMenuPageState extends State<MapMenuPage> {
  late bool _is3d = widget.is3d;
  bool _busy = widget.isBusy;

  Future<void> _selectMode(bool enable3d) async {
    if (_busy || _is3d == enable3d) return;

    setState(() => _busy = true);
    try {
      await widget.onTerrainModeChanged(enable3d);
      if (mounted) {
        setState(() => _is3d = enable3d);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Map display',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '2D uses a flat map without terrain mesh. 3D reloads the map '
            'style with terrain relief; tilting is only available in 3D.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('2D'),
                icon: Icon(Icons.map_outlined),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('3D'),
                icon: Icon(Icons.terrain_outlined),
              ),
            ],
            selected: {_is3d},
            emptySelectionAllowed: false,
            showSelectedIcon: false,
            onSelectionChanged: _busy
                ? null
                : (selection) {
                    final enable3d = selection.first;
                    unawaited(_selectMode(enable3d));
                  },
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            const Center(child: Text('Updating map…')),
          ],
        ],
      ),
    );
  }
}
