import 'package:flutter/material.dart';

import 'map/osm_map_page.dart';

/// Root widget for the MC-flutter MapLibre web map.
class McFlutterApp extends StatelessWidget {
  const McFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D3748)),
        useMaterial3: true,
      ),
      home: const OsmMapPage(),
    );
  }
}
