#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

swift test --enable-code-coverage

BIN_PATH="$(find .build -path '*/debug/CometransPackageTests.xctest/Contents/MacOS/CometransPackageTests' -print -quit)"
PROFILE_PATH="$(find .build -path '*/debug/codecov/default.profdata' -print -quit)"

if [[ -z "$BIN_PATH" || ! -f "$BIN_PATH" ]]; then
  echo "Coverage binary not found."
  exit 127
fi

if [[ -z "$PROFILE_PATH" || ! -f "$PROFILE_PATH" ]]; then
  echo "Coverage profile not found."
  exit 127
fi

echo ""
echo "CometransCore coverage summary:"
if command -v rg >/dev/null 2>&1; then
  xcrun llvm-cov report "$BIN_PATH" --instr-profile "$PROFILE_PATH" | rg 'Sources/CometransCore'
else
  xcrun llvm-cov report "$BIN_PATH" --instr-profile "$PROFILE_PATH" | grep 'Sources/CometransCore'
fi

UNCOVERED_LINES="$(
  xcrun llvm-cov show "$BIN_PATH" --instr-profile "$PROFILE_PATH" $(find Sources/CometransCore -name '*.swift' -print) \
    | awk '/^[[:space:]]*[0-9]+\|[[:space:]]*0\|/ { print }'
)"

if [[ -n "$UNCOVERED_LINES" ]]; then
  echo ""
  echo "Uncovered executable lines detected in CometransCore:"
  echo "$UNCOVERED_LINES"
  exit 1
fi

echo ""
echo "CometransCore executable lines are fully covered."
