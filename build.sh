#!/bin/sh
# Build the signed macOS application bundle.

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
LAUFEY_DEV_DIR="${LAUFEY_DEV_DIR:-$SCRIPT_DIR/../laufey}"
APP="./dist/GoogleChatDeno.app"

export LAUFEY_DEV_DIR

ICON_BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/google-chat-icon.XXXXXX")"
trap 'rm -rf "$ICON_BUILD_DIR"' EXIT

xcrun actool "$SCRIPT_DIR/assets/AppIcon.icon" \
  --compile "$ICON_BUILD_DIR" \
  --platform macosx \
  --minimum-deployment-target 10.15 \
  --app-icon AppIcon \
  --output-partial-info-plist "$ICON_BUILD_DIR/icon-info.plist" \
  --warnings --errors --output-format human-readable-text

rm -rf "$APP" "$APP.app"

deno desktop \
  --allow-net \
  src/app.ts \
  "$@"

cp "$ICON_BUILD_DIR/Assets.car" "$ICON_BUILD_DIR/AppIcon.icns" "$APP/Contents/Resources/"

plutil -replace CFBundleIconName -string AppIcon "$APP/Contents/Info.plist" 2>/dev/null || \
  plutil -insert CFBundleIconName -string AppIcon "$APP/Contents/Info.plist"

codesign --force --deep --sign - "$APP"
