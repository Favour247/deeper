#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build/release"
APP_NAME="Deeper"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Building $APP_NAME for arm64..."
xcodebuild -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR/derived" \
  -arch arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  clean build

APP_PATH=$(find "$BUILD_DIR/derived" -name "$APP_NAME.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
  echo "Error: $APP_NAME.app not found"
  exit 1
fi

cp -R "$APP_PATH" "$BUILD_DIR/$APP_NAME.app"

echo "Creating DMG..."
hdiutil create -volname "$APP_NAME" \
  -srcfolder "$BUILD_DIR/$APP_NAME.app" \
  -ov -format UDZO \
  "$BUILD_DIR/$APP_NAME.dmg"

echo "Done: $BUILD_DIR/$APP_NAME.dmg"
