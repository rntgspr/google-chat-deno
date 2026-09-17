#!/bin/sh
# Adds the persistent CEF profile environment to a built macOS app bundle.

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/profile_env.sh"

APP="${1:?usage: configure_macos_profile.sh <app-bundle>}"
PLIST="$APP/Contents/Info.plist"
PLIST_BUDDY='/usr/libexec/PlistBuddy'

if ! "$PLIST_BUDDY" -c 'Print :LSEnvironment' "$PLIST" >/dev/null 2>&1; then
  "$PLIST_BUDDY" -c 'Add :LSEnvironment dict' "$PLIST"
fi

if "$PLIST_BUDDY" -c 'Print :LSEnvironment:LAUFEY_CEF_PROFILE_PATH' "$PLIST" >/dev/null 2>&1; then
  "$PLIST_BUDDY" -c "Set :LSEnvironment:LAUFEY_CEF_PROFILE_PATH $LAUFEY_CEF_PROFILE_PATH" "$PLIST"
else
  "$PLIST_BUDDY" -c "Add :LSEnvironment:LAUFEY_CEF_PROFILE_PATH string $LAUFEY_CEF_PROFILE_PATH" "$PLIST"
fi
