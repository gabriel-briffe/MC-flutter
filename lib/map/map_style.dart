/// MapLibre style definitions for OSM and Mapterhorn terrain.
library;

/// Mapterhorn DEM tileset (terrain + hillshade).
const String mapterhornTileJsonUrl =
    'https://tiles.mapterhorn.com/tilejson.json';

/// Inline MapLibre style: OSM raster, Mapterhorn hillshade, and 3D terrain.
///
/// Inline JSON is required on Flutter web / GitHub Pages because
/// [MapLibreMap.styleString] asset paths are not resolved through the Flutter
/// asset bundle on web.
const String mapStyleString =
    '''
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
    "exaggeration": 1
  },
  "sky": {}
}
''';
