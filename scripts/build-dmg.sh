#!/bin/zsh
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIRECTORY="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
APP_DIRECTORY="$PROJECT_DIRECTORY/dist/TSS.app"
INFO_PLIST="$PROJECT_DIRECTORY/macos/Resources/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
OUTPUT_DMG="$PROJECT_DIRECTORY/dist/TSS-$VERSION.dmg"
STAGING_DIRECTORY="$(mktemp -d /tmp/tss-dmg-root.XXXXXX)"
TEMPORARY_DMG="$(mktemp /tmp/tss-dmg.XXXXXX).dmg"

cleanup() {
  rm -rf "$STAGING_DIRECTORY"
  rm -f "$TEMPORARY_DMG"
}
trap cleanup EXIT

"$SCRIPT_DIRECTORY/build-macos.sh"
codesign --verify --deep --strict "$APP_DIRECTORY"

ditto "$APP_DIRECTORY" "$STAGING_DIRECTORY/TSS.app"
xattr -cr "$STAGING_DIRECTORY/TSS.app"
codesign --verify --deep --strict "$STAGING_DIRECTORY/TSS.app"
ln -s /Applications "$STAGING_DIRECTORY/Applications"

hdiutil create \
  -volname "TSS" \
  -srcfolder "$STAGING_DIRECTORY" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -ov \
  "$TEMPORARY_DMG"

hdiutil verify "$TEMPORARY_DMG"
mkdir -p "$(dirname "$OUTPUT_DMG")"
ditto "$TEMPORARY_DMG" "$OUTPUT_DMG"
xattr -c "$OUTPUT_DMG" 2>/dev/null || true
hdiutil verify "$OUTPUT_DMG"

echo "Built $OUTPUT_DMG"
