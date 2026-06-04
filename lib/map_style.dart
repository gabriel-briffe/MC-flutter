/// Mapterhorn DEM tileset (terrain + hillshade).
const mapterhornTileJsonUrl = 'https://tiles.mapterhorn.com/tilejson.json';

/// Inline MapLibre style: OSM + Mapterhorn hillshade + 3D terrain.
///
/// Terrain and hillshade are always in the style; the UI "3D" control only
/// changes camera pitch (MapLibre GL JS on web does not support toggling
/// terrain via [MapLibreMapController.setStyle] reliably).
const String mapStyleString = '''
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
      "url": "https://tiles.mapterhorn.com/tilejson.json"
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
