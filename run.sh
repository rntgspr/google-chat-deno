#!/bin/sh
# Launch the CEF build with a durable browser profile.
#
# The CEF backend hardcodes its profile to $TMPDIR/laufey_cef_<pid>/ and offers
# no option to change it, so the Google session dies with every launch. The app
# must be opened as a bundle for macOS to provide its icon and application menu;
# its laufey child gets an unpredictable pid, so the profile link is installed
# by a short-lived watcher before CEF finishes starting.

set -e

APP="${APP:-./dist/GoogleChatDeno.app}"
LAUFEY="$APP/Contents/MacOS/laufey"
DURABLE="$HOME/Library/Application Support/com.rntgspr.google-chat-deno/cef"
TMP="${TMPDIR:-/tmp/}"

mkdir -p "$DURABLE"
find "$TMP" -maxdepth 1 -name 'laufey_cef_*' -type l -mmin +120 -delete 2>/dev/null || true

(
  n=0
  while [ "$n" -lt 6000 ]; do
    for p in $(pgrep -f "$LAUFEY" 2>/dev/null); do
      [ -e "${TMP}laufey_cef_$p" ] || ln -s "$DURABLE" "${TMP}laufey_cef_$p" 2>/dev/null
    done
    n=$((n + 1))
    sleep 0.01
  done
) &
WATCHER=$!
trap 'kill "$WATCHER" 2>/dev/null || true' EXIT

echo "[profile] watching for $LAUFEY -> $DURABLE"
exec open -n -W "$APP" --args "$@"
