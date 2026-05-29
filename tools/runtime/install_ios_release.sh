#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEVICE_ID="${DEVICE_ID:-00008030-000E09812150802E}"
XCODE_DEVELOPER_DIR="${XCODE_DEVELOPER_DIR:-/Users/wikki/Downloads/Xcode.app/Contents/Developer}"
BUNDLE_ID="${BUNDLE_ID:-com.example.erpnextStockMobile}"

if [[ ! -d "$XCODE_DEVELOPER_DIR" ]]; then
  echo "Xcode developer dir topilmadi: $XCODE_DEVELOPER_DIR" >&2
  exit 1
fi

cd "$ROOT_DIR"

export DEVELOPER_DIR="$XCODE_DEVELOPER_DIR"

echo "Release build boshlanyapti..."
flutter build ios --release

APP_PATH="build/ios/Release-iphoneos/Runner.app"
if [[ ! -d "$APP_PATH" ]]; then
  APP_PATH="build/ios/iphoneos/Runner.app"
fi
if [[ ! -d "$APP_PATH" ]]; then
  echo "Release .app topilmadi." >&2
  exit 1
fi

echo "iPhone'ga release app install qilinyapti: $APP_PATH"
xcrun devicectl device install app \
  --device "$DEVICE_ID" \
  "$APP_PATH"

echo "Release app install qilindi: $BUNDLE_ID"
