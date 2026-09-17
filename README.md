# Google Chat Deno

Experimental, unofficial macOS desktop wrapper for [Google Chat](https://chat.google.com/), built with
[`deno desktop`](https://docs.deno.com/runtime/reference/cli/desktop/) and the CEF backend.

The application opens the remote Google Chat client in a native window and stores its CEF profile under the app's macOS
Application Support directory so authenticated sessions survive relaunches.

## Status

This project depends on experimental Deno Desktop and a dedicated Laufey build. It currently targets Apple Silicon macOS
only. Runtime APIs, packaging behavior, and Google Chat compatibility may change.

Known constraints:

- The CEF backend is required because Google Chat rejects the macOS WebView backend as an unsupported browser.
- Passkey authentication is unavailable in the measured CEF build; Google's fallback verification flow works.
- The host cannot intercept external navigation before it replaces the Chat document.
- Development and packaged instances must not use the shared browser profile at the same time.

## Requirements

- Apple Silicon Mac
- Deno 2.9.6
- Xcode with Icon Composer support for application builds
- Laufey `v0.7.2-cef_150`, checked out at `../laufey` or selected with `LAUFEY_DEV_DIR`

The pinned runtime embeds CEF 150.0.14. The release workflow uses Xcode 26.6 on macOS 26.

## Development

Run the application with hot module replacement:

```bash
./dev.sh
```

Start the Deno inspector on `127.0.0.1:9333`:

```bash
./dev.sh --inspector
```

To use a Laufey checkout outside the default sibling directory:

```bash
LAUFEY_DEV_DIR=/absolute/path/to/laufey ./dev.sh
```

The persistent browser profile lives at:

```text
~/Library/Application Support/com.rntgspr.google-chat-deno/cef
```

## Verification

Run linting and the source checks used by the release workflow:

```bash
deno lint
deno test --allow-read src/app/index_test.ts
./tests/macos_profile_config_test.sh
./tests/bundle_path_test.sh
```

## Build

Build and ad-hoc sign the macOS application:

```bash
./build.sh
```

The resulting bundle is written to `dist/GoogleChatDeno.app`. The build compiles the application icon, embeds the
persistent profile configuration, and signs the complete bundle. Official releases use the repository's guarded GitHub
Actions workflow and a separately provisioned signing identity.

## Project structure

```text
assets/    Bootstrap page and macOS artwork
scripts/   Profile and signing utilities
src/       Deno host, boot server, shared utilities, and overlay experiments
tests/     Shell-level packaging and profile checks
```
