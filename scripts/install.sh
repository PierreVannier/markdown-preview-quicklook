#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/build/DerivedData"
APP_SOURCE="$DERIVED_DATA/Build/Products/Release/Markdown Preview.app"
APP_DEST="$HOME/Applications/Markdown Preview.app"
EXTENSION_ID="local.pierrevannier.MarkdownPreview.Extension"
BUILD_EXTENSION_PATH="$APP_SOURCE/Contents/PlugIns/Markdown Preview Extension.appex"
EXTENSION_PATH="$APP_DEST/Contents/PlugIns/Markdown Preview Extension.appex"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"

cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install XcodeGen and make sure it is available on PATH." >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/.build/ModuleCache"

xcodegen generate
xcodebuild \
  -project MarkdownPreview.xcodeproj \
  -scheme "Markdown Preview" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  SDK_STAT_CACHE_ENABLE=NO \
  build

mkdir -p "$HOME/Applications"
pluginkit -r "$BUILD_EXTENSION_PATH" || true
pluginkit -r "$EXTENSION_PATH" || true
"$LSREGISTER" -u "$APP_SOURCE" || true
"$LSREGISTER" -u "$APP_DEST" || true
ditto "$APP_SOURCE" "$APP_DEST"

"$LSREGISTER" -f -R -trusted "$APP_DEST"
pluginkit -a "$EXTENSION_PATH" || true
pluginkit -e use -i "$EXTENSION_ID" || true
CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/ModuleCache" /usr/bin/swift "$ROOT_DIR/scripts/set-viewer-handler.swift"

qlmanage -r >/dev/null
qlmanage -r cache >/dev/null

if ! pluginkit -m -i "$EXTENSION_ID" -D -v | grep -q "$EXTENSION_ID"; then
  echo "Install finished, but macOS did not list the Quick Look extension yet." >&2
  echo "Try opening $APP_DEST once, then run: qlmanage -r && qlmanage -r cache" >&2
  exit 1
fi

echo "Installed Markdown Preview."
echo "In Finder, select a .md file and press Space, or enable View > Show Preview for click-to-preview."
