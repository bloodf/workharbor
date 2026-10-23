#!/bin/zsh
set -eu
cd "${0:A:h}/.."
BUILD_ROOT="${WORKHARBOR_BUILD_ROOT:-${TMPDIR:-/tmp/}workharbor-20261022}"
export CLANG_MODULE_CACHE_PATH="$BUILD_ROOT/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$BUILD_ROOT/module-cache"
swift build --disable-sandbox --build-system native --cache-path "$BUILD_ROOT/cache" --manifest-cache local -c release --scratch-path "$BUILD_ROOT"
APP="$BUILD_ROOT/WorkHarbor.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BUILD_ROOT/release/WorkHarbor" "$APP/Contents/MacOS/WorkHarbor"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
for locale in Resources/*.lproj; do cp -R "$locale" "$APP/Contents/Resources/"; done
codesign --force --sign - --identifier local.workharbor.mac "$APP"
codesign --verify --strict "$APP"
mkdir -p dist
ditto "$APP" "$PWD/dist/WorkHarbor.app"
codesign --verify --strict "$PWD/dist/WorkHarbor.app" || print "Metadados do provedor de arquivos afetam o bundle nesta pasta; use o ZIP em uma pasta local."
ditto -c -k --norsrc --keepParent "$APP" "$PWD/dist/WorkHarbor.zip"
print "Aplicativo local: $PWD/dist/WorkHarbor.app"
print "Arquivo protegido de metadados do provedor: $PWD/dist/WorkHarbor.zip"
