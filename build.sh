#!/bin/bash
# Build the signed macOS application bundle.

set -euo pipefail

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
  src/app/index.ts \
  "$@"

cp "$ICON_BUILD_DIR/Assets.car" "$ICON_BUILD_DIR/AppIcon.icns" "$APP/Contents/Resources/"

plutil -replace CFBundleIconName -string AppIcon "$APP/Contents/Info.plist" 2>/dev/null || \
  plutil -insert CFBundleIconName -string AppIcon "$APP/Contents/Info.plist"

if [ -n "${MACOS_SIGNING_IDENTITY:-}${MACOS_SIGNING_KEYCHAIN:-}" ]; then
  : "${MACOS_SIGNING_IDENTITY:?Set the persistent signing identity}"
  : "${MACOS_SIGNING_KEYCHAIN:?Set the temporary signing Keychain path}"

  # Sign one code unit using the imported release identity without a timestamp service.
  sign_code() {
    codesign --force \
      --sign "$MACOS_SIGNING_IDENTITY" \
      --keychain "$MACOS_SIGNING_KEYCHAIN" \
      --timestamp=none \
      "$1"
  }

  find "$APP" -type f -print0 |
    while IFS= read -r -d '' code; do
      code_type="$(file -b "$code")"

      case "$code_type" in
        *Mach-O*) sign_code "$code" ;;
      esac
    done

  find "$APP" -depth -type d \
    \( -name '*.app' -o -name '*.framework' \) ! -path "$APP" -print0 |
    while IFS= read -r -d '' bundle; do
      sign_code "$bundle"
    done

  sign_code "$APP"
else
  codesign --force --deep --sign - "$APP"
fi
