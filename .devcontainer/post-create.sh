#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Flutter doctor (web)"
flutter doctor -v

echo "==> Installing project dependencies"
flutter pub get

echo "==> Dev container ready."
echo "    Run the app:  flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080"
echo "    Or use task:  Flutter: Run web (Codespace)"
