#!/usr/bin/env bash
set -euo pipefail

APP_DEST="$HOME/Applications/Markdown Preview.app"
EXTENSION_PATH="$APP_DEST/Contents/PlugIns/Markdown Preview Extension.appex"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"

pluginkit -r "$EXTENSION_PATH" || true
"$LSREGISTER" -u "$APP_DEST" || true
rm -rf "$APP_DEST"

qlmanage -r >/dev/null
qlmanage -r cache >/dev/null
killall Finder >/dev/null 2>&1 || true

echo "Uninstalled Markdown Preview."
echo "If Finder still shows stale previews, log out and back in."
