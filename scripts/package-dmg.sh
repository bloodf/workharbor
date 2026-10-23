#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ "$(uname -s)" == Darwin ]] || { echo 'DMG packaging requires macOS.' >&2; exit 1; }
APP="${1:-dist/WorkHarbor.app}"
[[ -d "$APP/Contents" ]] || { echo 'Build the app first.' >&2; exit 1; }
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid app version' >&2; exit 1; }
ARCH=$(uname -m)
OUT="$PWD/dist/WorkHarbor-${VERSION}-${ARCH}.dmg"
[[ ! -e "$OUT" ]] || { echo "Refusing to overwrite $OUT" >&2; exit 1; }
codesign --verify --deep --strict "$APP"
command -v create-dmg >/dev/null || { echo 'Install the official Homebrew create-dmg formula: brew install create-dmg' >&2; exit 1; }
STAGE=$(mktemp -d "${TMPDIR:-/tmp/}workharbor-dmg.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT
ditto "$APP" "$STAGE/WorkHarbor.app"
mkdir -p dist
create-dmg --volname "WorkHarbor $VERSION" \
  --volicon Resources/AppIcon.icns \
  --background Resources/DMG/background.png \
  --window-pos 200 120 --window-size 660 440 \
  --icon-size 104 --text-size 14 \
  --icon WorkHarbor.app 175 220 \
  --hide-extension WorkHarbor.app \
  --app-drop-link 485 220 \
  "$OUT" "$STAGE"
hdiutil verify "$OUT"
(cd dist && shasum -a 256 "$(basename "$OUT")" > "$(basename "$OUT").sha256")
echo "Created $OUT"
echo 'Signature status follows build-app.sh configuration. This script does not notarize.'
