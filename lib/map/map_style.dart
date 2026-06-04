/// MapLibre style definitions for OSM and Mapterhorn terrain.
library;

/// Mapterhorn DEM tileset (terrain + hillshade).
const String mapterhornTileJsonUrl =
    'https://tiles.mapterhorn.com/tilejson.json';

/// Builds inline MapLibre style JSON (required on Flutter web / GitHub Pages).
///
/// When [terrain3d] is false, only OSM and hillshade are included. When true,
/// adds `terrain` and `sky` for extruded 3D relief from Mapterhorn.
String buildMapStyle({required bool terrain3d}) {
  final terrainBlock = terrain3d
      ? '''
  "terrain": {
    "source": "mapterhorn-dem",
    "exaggeration": 1
  },
  "sky": {}'''
      : '';

  final terrainComma = terrain3d ? ',' : '';

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
  ]$terrainComma
  $terrainBlock
}
''';
}

/// Default 2D style: OSM + hillshade, no 3D terrain mesh.
String get mapStyleString => buildMapStyle(terrain3d: false);
