#!/usr/bin/env bash
set -euo pipefail

APP_DEST="$HOME/Applications/Markdown Preview.app"
EXTENSION_PATH="$APP_DEST/Contents/PlugIns/Markdown Preview Extension.appex"
APP_ID="local.pierrevannier.MarkdownPreview"
EXTENSION_ID="local.pierrevannier.MarkdownPreview.Extension"
INSTALLER_RECEIPT_ID="local.pierrevannier.MarkdownPreview.installer"
PREF_KEY="PreviewTheme"
SETTINGS_DIR="$HOME/Library/Application Support/Markdown Preview"
CACHE_DIR="$HOME/Library/Caches/Markdown Preview"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"

echo "Unregistering Markdown Preview..."
pluginkit -e ignore -i "$EXTENSION_ID" || true
pluginkit -r "$EXTENSION_PATH" || true
"$LSREGISTER" -u "$APP_DEST" || true

echo "Removing app, settings, and caches..."
rm -rf "$APP_DEST"
rm -rf "$SETTINGS_DIR" "$CACHE_DIR"
/usr/bin/defaults delete "$APP_ID" "$PREF_KEY" >/dev/null 2>&1 || true
/usr/bin/defaults delete "$EXTENSION_ID" "$PREF_KEY" >/dev/null 2>&1 || true

if /usr/sbin/pkgutil --pkg-info "$INSTALLER_RECEIPT_ID" >/dev/null 2>&1; then
  /usr/sbin/pkgutil --forget "$INSTALLER_RECEIPT_ID" >/dev/null 2>&1 || {
    echo "Package receipt still exists. Remove it with: sudo pkgutil --forget $INSTALLER_RECEIPT_ID" >&2
  }
fi

echo "Resetting Quick Look and Finder..."
qlmanage -r >/dev/null || true
qlmanage -r cache >/dev/null || true
killall Finder >/dev/null 2>&1 || true

echo "Uninstalled Markdown Preview."
echo "If Finder still shows stale previews, log out and back in."
