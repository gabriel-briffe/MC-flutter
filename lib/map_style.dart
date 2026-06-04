/// Minimal MapLibre style: OpenStreetMap raster tiles only.
///
/// On web, `styleString: 'assets/map_style.json'` is passed to MapLibre GL JS
/// as a URL. It does not use Flutter's asset bundle, so the style often never
/// loads and the map stays blank. Inline JSON works on web, mobile, and Pages.
const String mapStyleString = '''
{
  "version": 8,
  "name": "OSM raster",
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
      "tileSize": 256,
      "maxzoom": 19,
      "attribution": "&copy; OpenStreetMap contributors"
    }
  },
  "layers": [
    {
      "id": "osm-raster",
      "type": "raster",
      "source": "osm"
    }
  ]
}
''';
