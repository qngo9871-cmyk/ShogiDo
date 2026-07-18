#!/bin/bash
# Full clean rebuild script for Shogi Do
# Usage: ./rebuild.sh

set -e

echo "=== Regenerating Xcode project ==="
xcodegen generate

echo "=== Cleaning build artifacts ==="
xcodebuild clean -project ShogiDo.xcodeproj -scheme ShogiDo -quiet 2>/dev/null || true

echo "=== Building for simulator ==="
xcodebuild -project ShogiDo.xcodeproj \
    -scheme ShogiDo \
    -destination 'generic/platform=iOS Simulator' \
    -quiet build

echo "=== Building for device (archive) ==="
xcodebuild -project ShogiDo.xcodeproj \
    -scheme ShogiDo \
    -destination 'generic/platform=iOS' \
    -quiet build

echo "=== BUILD SUCCEEDED ==="
echo "To archive for App Store: open Xcode → Product → Archive"
echo "Make sure target is 'Any iOS Device (arm64)'"
