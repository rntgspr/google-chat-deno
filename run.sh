#!/bin/sh
# Launch the CEF build with a durable browser profile.
#
# The CEF backend hardcodes its profile to $TMPDIR/laufey_cef_<pid>/ and offers
# no option to change it, so the Google session dies with every launch. Creating
# the symlink from inside the app loses a race — CEF initializes before any user
# code runs. Doing it here works because `$$` is this shell's pid and `exec`
# replaces the process while keeping that pid: the link exists before the binary
# starts.

set -e

APP="${1:-./dist/GoogleChatDeno.app/Contents/MacOS/laufey}"
DURABLE="$HOME/Library/Application Support/com.rntgspr.google-chat-deno/cef"
TMP="${TMPDIR:-/tmp/}"

mkdir -p "$DURABLE"
rm -rf "${TMP}laufey_cef_$$"
ln -s "$DURABLE" "${TMP}laufey_cef_$$"

echo "[profile] ${TMP}laufey_cef_$$ -> $DURABLE"
exec "$APP"
