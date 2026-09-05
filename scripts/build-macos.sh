#!/bin/zsh
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIRECTORY="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
BUILD_DIRECTORY="$PROJECT_DIRECTORY/.build"
MODULE_CACHE="$BUILD_DIRECTORY/module-cache"
APP_EXECUTABLE="$BUILD_DIRECTORY/CastorApp-release"
APP_DIRECTORY="$PROJECT_DIRECTORY/dist/Castor.app"
RUST_BUILD_DIRECTORY="/tmp/castor-cargo-target"
STAGING_DIRECTORY="$(mktemp -d /tmp/castor-app-build.XXXXXX)"
STAGED_APP="$STAGING_DIRECTORY/Castor.app"
trap 'rm -rf "$STAGING_DIRECTORY"' EXIT

mkdir -p "$MODULE_CACHE"
cd "$PROJECT_DIRECTORY"

CARGO_TARGET_DIR="$RUST_BUILD_DIRECTORY" cargo build -p castor-ffi --release

SDK_PATH="$(xcrun --show-sdk-path)"
SDK_INTERFACE_FILE="$(find "$SDK_PATH/usr/lib/swift/Swift.swiftmodule" -name '*-apple-macos.swiftinterface' | head -n 1)"
SDK_INTERFACE_VERSION="$(sed -n 's/.*-interface-compiler-version \([^ ]*\).*/\1/p' "$SDK_INTERFACE_FILE" | head -n 1)"

SWIFT_ARGUMENTS=(
  -sdk "$SDK_PATH"
  -module-cache-path "$MODULE_CACHE"
  -parse-as-library
  -swift-version 6
  -O
  -whole-module-optimization
)
if [[ -n "$SDK_INTERFACE_VERSION" ]]; then
  SWIFT_ARGUMENTS+=(-interface-compiler-version "$SDK_INTERFACE_VERSION")
fi

swiftc \
  "${SWIFT_ARGUMENTS[@]}" \
  "$PROJECT_DIRECTORY"/macos/Sources/CastorApp/*.swift \
  -I "$PROJECT_DIRECTORY/macos/Sources/CCastorCore/include" \
  -L "$RUST_BUILD_DIRECTORY/release" \
  -lcastor_ffi \
  -framework AppKit \
  -framework ApplicationServices \
  -framework CoreGraphics \
  -o "$APP_EXECUTABLE"

mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"
mkdir -p "$STAGED_APP/Contents/Resources/Dictionaries"
cp "$APP_EXECUTABLE" "$STAGED_APP/Contents/MacOS/CastorApp"
cp "$PROJECT_DIRECTORY/macos/Resources/Info.plist" "$STAGED_APP/Contents/Info.plist"
cp "$PROJECT_DIRECTORY/macos/Resources/AppIcon.icns" "$STAGED_APP/Contents/Resources/AppIcon.icns"
cp "$PROJECT_DIRECTORY/examples/main.json" "$STAGED_APP/Contents/Resources/Dictionaries/main.json"
cp "$PROJECT_DIRECTORY/examples/main_hangul.json" "$STAGED_APP/Contents/Resources/Dictionaries/main_hangul.json"
ditto "$PROJECT_DIRECTORY/macos/Resources/ko.lproj" "$STAGED_APP/Contents/Resources/ko.lproj"
ditto "$PROJECT_DIRECTORY/macos/Resources/en.lproj" "$STAGED_APP/Contents/Resources/en.lproj"
# Assemble and sign outside iCloud Drive so Finder metadata cannot be attached
# between resource copying and code signing.
xattr -cr "$STAGED_APP"
codesign --force --deep --sign - "$STAGED_APP"

rm -rf "$APP_DIRECTORY"
mkdir -p "$(dirname "$APP_DIRECTORY")"
ditto "$STAGED_APP" "$APP_DIRECTORY"
# iCloud Drive can attach Finder metadata during the final copy. It is not
# executable content, but strict code-signature verification rejects it.
xattr -cr "$APP_DIRECTORY"
for ATTRIBUTE in com.apple.FinderInfo com.apple.ResourceFork; do
  xattr -d "$ATTRIBUTE" "$APP_DIRECTORY" 2>/dev/null || true
done
codesign --verify --deep --strict "$APP_DIRECTORY"

echo "Built $APP_DIRECTORY"
