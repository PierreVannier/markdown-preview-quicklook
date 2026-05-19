#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/MarkdownPreviewApp/Info.plist")"
RELEASE_DIR="$ROOT_DIR/release"
UNSIGNED_PKG="$RELEASE_DIR/MarkdownPreview-$VERSION.pkg"
SIGNED_PKG="$RELEASE_DIR/MarkdownPreview-$VERSION-signed.pkg"
SIGNED_CHECKSUM="$SIGNED_PKG.sha256"

usage() {
  cat <<USAGE
Usage:
  DEVELOPER_ID_APPLICATION="Developer ID Application: Name (TEAMID)" \\
  DEVELOPER_ID_INSTALLER="Developer ID Installer: Name (TEAMID)" \\
  NOTARYTOOL_PROFILE="markdown-preview" \\
  ./scripts/notarize.sh

Before running this script, create the notarytool keychain profile once:

  xcrun notarytool store-credentials "markdown-preview" \\
    --apple-id "you@example.com" \\
    --team-id "TEAMID" \\
    --password "app-specific-password"

The script builds a Developer ID signed app, signs the installer package,
submits the package to Apple's notarization service, staples the ticket,
and writes a SHA256 checksum for the signed package.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

required_env=(
  DEVELOPER_ID_APPLICATION
  DEVELOPER_ID_INSTALLER
  NOTARYTOOL_PROFILE
)

for name in "${required_env[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "$name is required." >&2
    echo >&2
    usage >&2
    exit 2
  fi
done

cd "$ROOT_DIR"

CODE_SIGN_IDENTITY="$DEVELOPER_ID_APPLICATION" \
ENABLE_HARDENED_RUNTIME=YES \
"$ROOT_DIR/scripts/package.sh"

rm -f "$SIGNED_PKG" "$SIGNED_CHECKSUM"

/usr/bin/productsign \
  --sign "$DEVELOPER_ID_INSTALLER" \
  "$UNSIGNED_PKG" \
  "$SIGNED_PKG"

/usr/bin/xcrun notarytool submit \
  "$SIGNED_PKG" \
  --keychain-profile "$NOTARYTOOL_PROFILE" \
  --wait

/usr/bin/xcrun stapler staple "$SIGNED_PKG"
/usr/bin/shasum -a 256 "$SIGNED_PKG" > "$SIGNED_CHECKSUM"

echo "Created notarized package: $SIGNED_PKG"
echo "Created checksum: $SIGNED_CHECKSUM"
