#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/build/DerivedData"
APP_SOURCE="$DERIVED_DATA/Build/Products/Release/Markdown Preview.app"
PACKAGE_WORK_DIR="$ROOT_DIR/.build/package"
PKG_ROOT="$PACKAGE_WORK_DIR/root"
PKG_SCRIPTS="$PACKAGE_WORK_DIR/scripts"
PAYLOAD_DIR="$PKG_ROOT/private/tmp/markdown-preview-quicklook"
RELEASE_DIR="$ROOT_DIR/release"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/MarkdownPreviewApp/Info.plist")"
PKG_PATH="$RELEASE_DIR/MarkdownPreview-$VERSION.pkg"
CODE_SIGN_IDENTITY_VALUE="${CODE_SIGN_IDENTITY:-"-"}"
DEVELOPMENT_TEAM_VALUE="${DEVELOPMENT_TEAM:-""}"
ENABLE_HARDENED_RUNTIME_VALUE="${ENABLE_HARDENED_RUNTIME:-"NO"}"

cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install it with: brew install xcodegen" >&2
  exit 1
fi

rm -rf "$PACKAGE_WORK_DIR"
mkdir -p "$PAYLOAD_DIR" "$PKG_SCRIPTS" "$RELEASE_DIR" "$ROOT_DIR/.build/ModuleCache"

xcodegen generate
xcodebuild \
  -project MarkdownPreview.xcodeproj \
  -scheme "Markdown Preview" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY_VALUE" \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM_VALUE" \
  ENABLE_HARDENED_RUNTIME="$ENABLE_HARDENED_RUNTIME_VALUE" \
  SDK_STAT_CACHE_ENABLE=NO \
  build

ditto --norsrc --noextattr "$APP_SOURCE" "$PAYLOAD_DIR/Markdown Preview.app"
cp "$ROOT_DIR/scripts/set-viewer-handler.swift" "$PAYLOAD_DIR/set-viewer-handler.swift"
/usr/bin/xattr -cr "$PAYLOAD_DIR" >/dev/null 2>&1 || true
find "$PKG_ROOT" -exec /usr/bin/xattr -d com.apple.provenance {} + >/dev/null 2>&1 || true

cat > "$PKG_SCRIPTS/postinstall" <<'POSTINSTALL'
#!/usr/bin/env bash
set -euo pipefail

EXTENSION_ID="local.pierrevannier.MarkdownPreview.Extension"
PAYLOAD_DIR="/private/tmp/markdown-preview-quicklook"
APP_SOURCE="$PAYLOAD_DIR/Markdown Preview.app"
HANDLER_SCRIPT="$PAYLOAD_DIR/set-viewer-handler.swift"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"

CONSOLE_USER="$(/usr/bin/stat -f %Su /dev/console)"
if [[ -z "$CONSOLE_USER" || "$CONSOLE_USER" == "root" || "$CONSOLE_USER" == "_mbsetupuser" ]]; then
  echo "Markdown Preview installer requires a logged-in macOS user." >&2
  exit 1
fi

USER_ID="$(/usr/bin/id -u "$CONSOLE_USER")"
USER_GROUP="$(/usr/bin/id -gn "$CONSOLE_USER")"
USER_HOME="$(/usr/bin/dscl . -read "/Users/$CONSOLE_USER" NFSHomeDirectory | /usr/bin/sed 's/^NFSHomeDirectory: //')"
APP_DEST="$USER_HOME/Applications/Markdown Preview.app"
EXTENSION_PATH="$APP_DEST/Contents/PlugIns/Markdown Preview Extension.appex"
MODULE_CACHE="$USER_HOME/Library/Caches/Markdown Preview/ModuleCache"

run_as_user() {
  /bin/launchctl asuser "$USER_ID" /usr/bin/sudo -u "$CONSOLE_USER" "$@"
}

mkdir -p "$USER_HOME/Applications" "$MODULE_CACHE"
chown -R "$CONSOLE_USER:$USER_GROUP" "$USER_HOME/Applications" "$USER_HOME/Library/Caches/Markdown Preview"

run_as_user /usr/bin/pluginkit -r "$EXTENSION_PATH" || true
"$LSREGISTER" -u "$APP_DEST" || true

ditto "$APP_SOURCE" "$APP_DEST"
chown -R "$CONSOLE_USER:$USER_GROUP" "$APP_DEST"
/usr/bin/xattr -dr com.apple.quarantine "$APP_DEST" >/dev/null 2>&1 || true

run_as_user "$LSREGISTER" -f -R -trusted "$APP_DEST"
run_as_user /usr/bin/pluginkit -a "$EXTENSION_PATH" || true
run_as_user /usr/bin/pluginkit -e use -i "$EXTENSION_ID" || true
run_as_user /usr/bin/env CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" /usr/bin/swift "$HANDLER_SCRIPT"

run_as_user /usr/bin/qlmanage -r >/dev/null || true
run_as_user /usr/bin/qlmanage -r cache >/dev/null || true

if ! run_as_user /usr/bin/pluginkit -m -i "$EXTENSION_ID" -D -v | /usr/bin/grep -q "$EXTENSION_ID"; then
  echo "Markdown Preview was copied, but macOS did not list the Quick Look extension yet." >&2
  echo "Open $APP_DEST once, then run: qlmanage -r && qlmanage -r cache" >&2
  exit 1
fi

rm -rf "$PAYLOAD_DIR"
echo "Installed Markdown Preview for $CONSOLE_USER."
POSTINSTALL

chmod +x "$PKG_SCRIPTS/postinstall"
rm -f "$PKG_PATH"

COPYFILE_DISABLE=1 /usr/bin/pkgbuild \
  --root "$PKG_ROOT" \
  --scripts "$PKG_SCRIPTS" \
  --identifier "local.pierrevannier.MarkdownPreview.installer" \
  --version "$VERSION" \
  --install-location "/" \
  --filter '(^|/)\._[^/]*$' \
  --filter '(^|/)\.DS_Store$' \
  "$PKG_PATH"

/usr/bin/xattr -c "$PKG_PATH" >/dev/null 2>&1 || true
echo "Created $PKG_PATH"
