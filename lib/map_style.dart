/// Mapterhorn DEM tileset (terrain + hillshade).
const mapterhornTileJsonUrl = 'https://tiles.mapterhorn.com/tilejson.json';

/// Builds the MapLibre style as inline JSON (required for Flutter web / Pages).
///
/// [terrain3d] adds the `terrain` and `sky` spec entries used for 3D relief.
/// Hillshade from Mapterhorn is always drawn above the OSM raster layer.
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

/// Initial 2D view: OSM + hillshade, no 3D terrain mesh.
String get mapStyleString => buildMapStyle(terrain3d: false);
