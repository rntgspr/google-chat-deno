#!/bin/sh
# Runs the source entrypoint with HMR against the application's persistent CEF profile.

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/scripts/profile_env.sh"

LAUFEY_DEV_DIR="${LAUFEY_DEV_DIR:-$SCRIPT_DIR/../laufey}"
ENTRY="${ENTRY:-src/app/index.ts}"
INSPECTOR_PORT="${INSPECTOR_PORT:-9333}"
INSPECTOR_OPTION=""

export LAUFEY_DEV_DIR

if [ "${1:-}" = "--inspector" ]; then
  INSPECTOR_OPTION="--inspect=127.0.0.1:$INSPECTOR_PORT"
  shift
fi

echo "[profile] $LAUFEY_CEF_PROFILE_PATH"
echo "[dev] hmr on $ENTRY"

if [ -n "$INSPECTOR_OPTION" ]; then
  echo "[dev] inspector on 127.0.0.1:$INSPECTOR_PORT"
fi

exec deno desktop --hmr \
  ${INSPECTOR_OPTION:+"$INSPECTOR_OPTION"} \
  --allow-net "$ENTRY" "$@"
