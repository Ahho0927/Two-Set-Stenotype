#!/bin/zsh
set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIRECTORY="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"

cd "$PROJECT_DIRECTORY"
cargo test --workspace
"$SCRIPT_DIRECTORY/test-swift.sh"
"$SCRIPT_DIRECTORY/build-macos.sh"

