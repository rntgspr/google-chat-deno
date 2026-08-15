#!/bin/sh
# Run from source with hot module replacement, against the same browser profile
# the packaged app uses — so the Google session carries over between the two.
#
# The profile symlink has to exist before CEF initializes, and CEF names its
# directory after the process pid. `$$` is this shell's pid and `exec` replaces
# the process while keeping it, so the link is in place by the time the runtime
# starts. Same reasoning as run.sh; only the exec'd command differs.
#
# Sharing that profile also means this and ./run.sh cannot run at the same time:
# a second launch prints `Opening in existing browser session.` and exits 24.

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
LAUFEY_DEV_DIR="${LAUFEY_DEV_DIR:-$SCRIPT_DIR/../laufey}"
ENTRY="${ENTRY:-src/app.ts}"
DURABLE="$HOME/Library/Application Support/com.rntgspr.google-chat-deno/cef"
TMP="${TMPDIR:-/tmp/}"
INSPECTOR_PORT="${INSPECTOR_PORT:-9333}"
INSPECTOR_OPTION=""

export LAUFEY_DEV_DIR

if [ "${1:-}" = "--inspector" ]; then
  INSPECTOR_OPTION="--inspect=127.0.0.1:$INSPECTOR_PORT"
  shift
fi

mkdir -p "$DURABLE"

# run.sh links a single pid because `exec` hands the bundled binary this shell's
# pid. That does not work here: `deno desktop` compiles first and then spawns
# laufey as a child, and CEF names the profile after *that* pid — measured, the
# child's, not this shell's. The distance between them is whatever the build
# consumed, so it cannot be predicted; `--user-data-dir` does not help either,
# laufey overrides it. What can be done is watch for the process and lay the link
# down the moment it exists, before CEF has finished starting.
#
# DEBT: a hack on top of the undocumented profile path in specs/session, and it
# races CEF's own startup. If the runtime ever names its profile something
# predictable, delete all of this.
LAUFEY_BIN='cef/[^ ]*/laufey.app/Contents/MacOS/laufey'

find "$TMP" -maxdepth 1 -name 'laufey_cef_*' -type l -mmin +120 -delete 2>/dev/null || true

(
  n=0
  while [ "$n" -lt 6000 ]; do
    for p in $(pgrep -f "$LAUFEY_BIN" 2>/dev/null); do
      [ -e "${TMP}laufey_cef_$p" ] || ln -s "$DURABLE" "${TMP}laufey_cef_$p" 2>/dev/null
    done
    n=$((n + 1))
    sleep 0.01
  done
) &

echo "[profile] watching for laufey -> $DURABLE"
echo "[dev] hmr on $ENTRY"

if [ -n "$INSPECTOR_OPTION" ]; then
  echo "[dev] inspector on 127.0.0.1:$INSPECTOR_PORT"
fi

exec deno desktop --hmr \
  ${INSPECTOR_OPTION:+"$INSPECTOR_OPTION"} \
  --allow-net "$ENTRY" "$@"
