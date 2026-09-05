#!/bin/zsh
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIRECTORY="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
BUILD_DIRECTORY="$PROJECT_DIRECTORY/.build"
MODULE_CACHE="$BUILD_DIRECTORY/module-cache"
TEST_EXECUTABLE="$BUILD_DIRECTORY/CastorSwiftSmokeTests"
SDK_PATH="$(xcrun --show-sdk-path)"
SDK_INTERFACE_FILE="$(find "$SDK_PATH/usr/lib/swift/Swift.swiftmodule" -name '*-apple-macos.swiftinterface' | head -n 1)"
SDK_INTERFACE_VERSION="$(sed -n 's/.*-interface-compiler-version \([^ ]*\).*/\1/p' "$SDK_INTERFACE_FILE" | head -n 1)"

mkdir -p "$MODULE_CACHE"
cd "$PROJECT_DIRECTORY"

cargo build -p castor-ffi --release

swiftc \
  -sdk "$SDK_PATH" \
  -interface-compiler-version "$SDK_INTERFACE_VERSION" \
  -module-cache-path "$MODULE_CACHE" \
  -parse-as-library \
  macos/Sources/CastorApp/Localization.swift \
  macos/Sources/CastorApp/Models.swift \
  macos/Sources/CastorApp/KeyCodeMapper.swift \
  macos/Sources/CastorApp/ContextProvider.swift \
  macos/Sources/CastorApp/CoreBridge.swift \
  macos/Tests/SmokeTests.swift \
  -I macos/Sources/CCastorCore/include \
  -L target/release \
  -lcastor_ffi \
  -framework AppKit \
  -framework ApplicationServices \
  -o "$TEST_EXECUTABLE"

"$TEST_EXECUTABLE"
