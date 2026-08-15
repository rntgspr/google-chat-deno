#!/bin/sh

set -eu

OUTPUT_PATH="$(deno eval 'const config = JSON.parse(await Deno.readTextFile("deno.json")); console.log(config.desktop.output.macos)')"
EXPECTED_OUTPUT="./dist/GoogleChatDeno"
EXPECTED_BUNDLE="${EXPECTED_OUTPUT}.app"

if [ "$OUTPUT_PATH" != "$EXPECTED_OUTPUT" ]; then
  echo "desktop.output.macos must be $EXPECTED_OUTPUT so deno desktop emits exactly one .app suffix" >&2
  exit 1
fi

if ! grep -Fqx "APP=\"$EXPECTED_BUNDLE\"" build.sh; then
  echo "build.sh does not use the canonical bundle path $EXPECTED_BUNDLE" >&2
  exit 1
fi

if ! grep -Fqx 'rm -rf "$APP" "$APP.app"' build.sh; then
  echo "build.sh does not remove the legacy duplicated bundle path" >&2
  exit 1
fi

if ! grep -Fqx "APP=\"\${APP:-$EXPECTED_BUNDLE}\"" run.sh; then
  echo "run.sh does not default to the canonical bundle path $EXPECTED_BUNDLE" >&2
  exit 1
fi

case "${OUTPUT_PATH}.app" in
  *.app.app)
    echo "configured output would produce a duplicated .app.app suffix" >&2
    exit 1
    ;;
esac

for script in build.sh dev.sh; do
  if ! grep -Fq 'LAUFEY_DEV_DIR="${LAUFEY_DEV_DIR:-$SCRIPT_DIR/../laufey}"' "$script"; then
    echo "$script does not default LAUFEY_DEV_DIR to the dedicated sibling checkout" >&2
    exit 1
  fi

  if ! grep -Fqx 'export LAUFEY_DEV_DIR' "$script"; then
    echo "$script does not export LAUFEY_DEV_DIR for deno desktop" >&2
    exit 1
  fi
done

echo "bundle path tests passed"
