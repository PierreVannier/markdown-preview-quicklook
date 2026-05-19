#!/usr/bin/env bash
set -euo pipefail

APP_DEST="$HOME/Applications/Markdown Preview.app"
EXTENSION_PATH="$APP_DEST/Contents/PlugIns/Markdown Preview Extension.appex"
APP_ID="local.pierrevannier.MarkdownPreview"
EXTENSION_ID="local.pierrevannier.MarkdownPreview.Extension"
THEME_FILE="$HOME/Library/Application Support/Markdown Preview/theme.txt"

section() {
  printf '\n## %s\n' "$1"
}

show_file_status() {
  local label="$1"
  local path="$2"

  if [[ -e "$path" ]]; then
    printf '%s: found at %s\n' "$label" "$path"
  else
    printf '%s: missing at %s\n' "$label" "$path"
  fi
}

section "System"
/usr/bin/sw_vers
printf 'Architecture: %s\n' "$(/usr/bin/uname -m)"

section "Install Paths"
show_file_status "App" "$APP_DEST"
show_file_status "Quick Look extension" "$EXTENSION_PATH"

if [[ -e "$APP_DEST/Contents/Info.plist" ]]; then
  printf 'App bundle id: '
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_DEST/Contents/Info.plist" 2>/dev/null || true
  printf 'App version: '
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DEST/Contents/Info.plist" 2>/dev/null || true
fi

if [[ -e "$EXTENSION_PATH/Contents/Info.plist" ]]; then
  printf 'Extension bundle id: '
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$EXTENSION_PATH/Contents/Info.plist" 2>/dev/null || true
fi

section "Theme Preference"
printf 'CFPreferences app theme: '
/usr/bin/defaults read "$APP_ID" PreviewTheme 2>/dev/null || printf 'not set\n'
printf 'CFPreferences extension theme: '
/usr/bin/defaults read "$EXTENSION_ID" PreviewTheme 2>/dev/null || printf 'not set\n'

if [[ -f "$THEME_FILE" ]]; then
  printf 'Shared theme file: %s\n' "$THEME_FILE"
  printf 'Shared theme value: '
  /bin/cat "$THEME_FILE"
else
  printf 'Shared theme file: missing at %s\n' "$THEME_FILE"
fi

section "pluginkit"
/usr/bin/pluginkit -m -i "$EXTENSION_ID" -D -v || true

section "Quick Look Markdown Plugins"
if ! /usr/bin/qlmanage -m plugins | /usr/bin/grep -Ei 'markdown|Markdown Preview|net.daringfireball.markdown|public.markdown|com.unknown.md'; then
  printf 'No Markdown-related Quick Look plugin entries found.\n'
fi

section "Next Checks"
printf 'Preview sample manually: qlmanage -p Samples/Preview.md\n'
printf 'Reset Quick Look: qlmanage -r && qlmanage -r cache && killall Finder\n'
