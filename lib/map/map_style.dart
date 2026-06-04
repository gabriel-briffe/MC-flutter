/// MapLibre style definitions for OSM and Mapterhorn terrain.
library;

/// Mapterhorn DEM tileset (terrain + hillshade).
const String mapterhornTileJsonUrl =
    'https://tiles.mapterhorn.com/tilejson.json';

/// Builds inline MapLibre style JSON (required on Flutter web / GitHub Pages).
///
/// 3D relief is controlled via [terrain3d]: the `terrain` block is always
/// present so MapLibre can update it on style reload. Use `exaggeration: 0`
/// for 2D (no mesh); use `1` plus `sky` for 3D. Omitting `terrain` entirely
/// often leaves the previous 3D mesh active after `setStyle`.
String buildMapStyle({required bool terrain3d}) {
  final exaggeration = terrain3d ? 1 : 0;
  final skyBlock = terrain3d ? ',\n  "sky": {}' : '';

  return '''
{
  "version": 8,
  "name": "OSM + Mapterhorn",
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
      "tileSize": 256,
      "maxzoom": 19,
      "attribution": "&copy; OpenStreetMap contributors"
    },
    "mapterhorn-dem": {
      "type": "raster-dem",
      "url": "$mapterhornTileJsonUrl"
    }
  },
  "layers": [
    {
      "id": "osm-raster",
      "type": "raster",
      "source": "osm"
    },
    {
      "id": "hills",
      "type": "hillshade",
      "source": "mapterhorn-dem",
      "paint": {
        "hillshade-shadow-color": "#473B24"
      }
    }
  ],
  "terrain": {
    "source": "mapterhorn-dem",
    "exaggeration": $exaggeration
  }$skyBlock
}
''';
}

/// Default 2D: hillshade on, terrain mesh flattened (`exaggeration: 0`).
String get mapStyleString => buildMapStyle(terrain3d: false);
