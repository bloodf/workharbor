#!/bin/zsh
set -eu
cd "${0:A:h}/.."
BUILD_ROOT="${WORKHARBOR_BUILD_ROOT:-${TMPDIR:-/tmp/}workharbor-20261022}"
export CLANG_MODULE_CACHE_PATH="$BUILD_ROOT/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$BUILD_ROOT/module-cache"
swift test --disable-sandbox --build-system native --cache-path "$BUILD_ROOT/cache" --manifest-cache local --scratch-path "$BUILD_ROOT"
