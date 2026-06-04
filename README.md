# MC-flutter

Flutter **web** app with a full-screen [MapLibre](https://maplibre.org/) map: OpenStreetMap raster tiles plus DEM hillshading.

**Live map:** https://gabriel-briffe.github.io/MC-flutter/

All source and config live on the **`main`** branch. Pushes to `main` automatically build and deploy the site via [GitHub Actions](.github/workflows/deploy-pages.yml).

## Stack

- [Flutter](https://flutter.dev/) (web)
- [maplibre_gl](https://pub.dev/packages/maplibre_gl) — MapLibre GL JS on web
- Custom style in `assets/map_style.json` (OSM + terrain hillshade)

## GitHub Codespaces (recommended)

This repo includes a [Dev Container](https://containers.dev/) under `.devcontainer/`.

1. Open the repo on GitHub → **Code** → **Codespaces** → **Create codespace on main**.
2. Wait for the container to build (Flutter SDK + web tooling are installed automatically).
3. In the terminal:

```bash
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080
```

4. When prompted, open the forwarded **port 8080** in your browser (or use the **Ports** tab).

You can also press **F5** (launch config **Flutter Web (Codespace)**) or run the default build task **Flutter: Run web (Codespace)** from the Command Palette.

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

### GitHub Pages (automatic)

On the first deploy, enable Pages once in the repo: **Settings → Pages → Build and deployment → Source: GitHub Actions**. After that, every push to `main` updates https://gabriel-briffe.github.io/MC-flutter/.

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
