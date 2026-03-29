#!/bin/bash
# Build and run TruckRouteCalculator in iOS Simulator

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_ID="com.pivotallift.TruckRouteCalculator"
SIMULATOR="iPhone 17 Pro"
BUILD_DIR="$PROJECT_DIR/build"

echo "Building TruckRouteCalculator..."
xcodebuild -project "$PROJECT_DIR/TruckRouteCalculator.xcodeproj" \
    -scheme TruckRouteCalculator \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    -derivedDataPath "$BUILD_DIR" \
    build 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" || true

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Booting simulator..."
xcrun simctl boot "$SIMULATOR" 2>/dev/null || true

echo "Opening Simulator app..."
open -a Simulator

sleep 2

echo "Installing app..."
xcrun simctl install booted "$BUILD_DIR/Build/Products/Debug-iphonesimulator/TruckRouteCalculator.app"

echo "Launching app..."
xcrun simctl launch booted "$BUNDLE_ID"

echo "Done! App is running."
