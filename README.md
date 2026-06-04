# MC-flutter

Flutter **web** app with a full-screen [MapLibre](https://maplibre.org/) map: OpenStreetMap raster tiles plus DEM hillshading.

## Stack

- [Flutter](https://flutter.dev/) (web)
- [maplibre_gl](https://pub.dev/packages/maplibre_gl) — MapLibre GL JS on web
- Custom style in `assets/map_style.json` (OSM + terrain hillshade)

## Run locally

```bash
flutter pub get
flutter run -d chrome
```

Or build for production:

```bash
flutter build web
```

Serve `build/web` with any static host.

## Map style

The map uses:

1. **Base layer** — [OpenStreetMap](https://www.openstreetmap.org/) standard raster tiles (`tile.openstreetmap.org`). Follow the [OSM tile usage policy](https://operations.osmfoundation.org/policies/tiles/) for production (attribution, caching, traffic).
2. **Hillshade** — MapLibre demo terrain DEM (`demotiles.maplibre.org`) for relief shading over the basemap.

Initial view is centered on the Swiss Alps so terrain is easy to see. Pan and zoom with the mouse; use Ctrl+drag (or two-finger drag) to tilt if your browser sends those gestures to the map.

## Project layout

```
lib/main.dart           # App entry + MapLibreMap widget
assets/map_style.json   # MapLibre style (OSM raster + hillshade layer)
web/index.html          # MapLibre GL JS script tags for web
```
