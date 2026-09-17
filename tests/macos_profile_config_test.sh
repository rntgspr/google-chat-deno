#!/bin/sh

set -eu

FIXTURE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/google-chat-profile-test.XXXXXX")"
trap 'rm -rf "$FIXTURE_DIR"' EXIT

mkdir -p "$FIXTURE_DIR/Test.app/Contents"
plutil -create xml1 "$FIXTURE_DIR/Test.app/Contents/Info.plist"
plutil -insert LSEnvironment -xml '<dict><key>EXISTING_KEY</key><string>preserved</string></dict>' "$FIXTURE_DIR/Test.app/Contents/Info.plist"

./scripts/configure_macos_profile.sh "$FIXTURE_DIR/Test.app"

PROFILE_PATH="$(plutil -extract LSEnvironment.LAUFEY_CEF_PROFILE_PATH raw -o - "$FIXTURE_DIR/Test.app/Contents/Info.plist")"

if [ "$PROFILE_PATH" != '~/Library/Application Support/com.rntgspr.google-chat-deno/cef' ]; then
  echo "unexpected CEF profile path: $PROFILE_PATH" >&2
  exit 1
fi

./scripts/configure_macos_profile.sh "$FIXTURE_DIR/Test.app"
plutil -lint "$FIXTURE_DIR/Test.app/Contents/Info.plist" >/dev/null

EXISTING_VALUE="$(plutil -extract LSEnvironment.EXISTING_KEY raw -o - "$FIXTURE_DIR/Test.app/Contents/Info.plist")"

if [ "$EXISTING_VALUE" != 'preserved' ]; then
  echo "existing LSEnvironment value was not preserved" >&2
  exit 1
fi

echo "macOS profile configuration tests passed"
