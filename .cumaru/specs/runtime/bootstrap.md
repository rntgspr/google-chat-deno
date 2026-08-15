---
human_revised: false
name: bootstrap
summary: Application entrypoint, local boot-contract server, packaging, permissions, menus, diagnostics, and macOS assets.
depends-on: [specs/runtime]
relates: [specs/session, specs/chat-host]
apps: [host, bundle, launcher]
---

# Application bootstrap

## Overview

`src/app.ts` is the application entrypoint. It starts a loopback HTTP server, waits briefly for the experimental desktop
runtime, and delegates creation of the single Chat window to `src/main.ts`. The window is created directly through
`Deno.BrowserWindow`, receives its native menus and dimensions, waits one short construction interval, and navigates to
Chat. Local development resolves the dedicated sibling Laufey checkout through `LAUFEY_DEV_DIR`; release builds
point the same variable at a verified runtime extracted from the pinned Laufey release.

The local server exists to satisfy the measured `deno desktop` boot contract while the main window navigates directly
to Google Chat.

## Requirements (EARS / RFC 2119)

### Startup

- The packaged and development entrypoint MUST be `src/app.ts`.
- WHEN the application starts THE SYSTEM SHALL start the boot-contract server before creating a browser window.
- THE SYSTEM SHALL create exactly one main Chat window.
- THE SYSTEM SHALL NOT install attachment resolver, cache, or replacement plugins.
- THE SYSTEM SHALL NOT poll the Chat DOM, execute page probes, or expose host bindings during startup.
- Local development MUST default `LAUFEY_DEV_DIR` to the dedicated sibling checkout, while release builds MUST set it
  to a verified runtime extracted from the pinned Laufey release.

### Main window

- The main window MUST navigate to the configured Google Chat URL.
- The main window MUST be created directly through `Deno.BrowserWindow` without a shared multi-window manager.
- The main window MUST wait for its short construction delay before initial navigation.
- The main window SHALL expose the native application and edit menus declared by the host.
- The application menu MUST include the runtime's `quit` role; live Cmd+Q behavior remains tracked by its active
  maintenance plan.

### Server and bundle

- The boot server MUST bind to loopback on an ephemeral port and serve only the embedded bootstrap document.
- The server's `finished` promise MUST NOT block module evaluation.
- The desktop bundle MUST use the CEF backend and the `com.rntgspr.google-chat-deno` identifier.
- The build MUST grant only the network permission required by the loopback bootstrap server.
- The application MUST preserve the approved artwork and appearance settings in `assets/AppIcon.icon`.
- The macOS build MUST compile that document with Apple's `actool`, targeting macOS 10.15, and install the generated
  `Assets.car` and `AppIcon.icns` in the bundle before signing. Xcode with Icon Composer support is a build prerequisite.
- The Deno configuration MUST retain `assets/GoogleChat.icns` as its direct icon input. This checked-in fallback is
  derived from the approved document; the canonical build regenerates the packaged resources from `assets/AppIcon.icon`.
- `CFBundleIconFile` and `CFBundleIconName` MUST resolve to `AppIcon`; Finder, Dock, and Cmd+Tab MUST use the same
  bundled artwork. A fresh build MUST reproduce the icon without manual cache resets or resource replacement.
- The bundle MUST retain the compiled ICNS fallback for older supported macOS releases. The standalone light and
  dark PNGs remain branding sources rather than independently selected bundle appearances.
- The build script MUST compile `src/app.ts` with a suffix-free macOS output base, remove stale canonical and
  duplicated-suffix bundles, patch the icon name, and ad-hoc sign the single resulting `.app` bundle.
- The desktop configuration, build script, and packaged launcher MUST resolve one canonical macOS application bundle
  path.
- The build output MUST NOT contain a duplicated `.app.app` suffix.

### Release distribution

- The GitHub release workflow MUST pin its macOS arm64 runner, Xcode, Deno, Laufey release, CEF version, and target
  architecture.
- A release build MUST download the complete Laufey archive and checksum manifest from the pinned release, verify
  the checksum and architecture, and MUST NOT compile Laufey or download CEF independently.
- A release archive MUST include the complete Chat application bundle, executable packaged launcher,
  runtime-pairing metadata, and a portable checksum manifest while preserving executable modes and symlinks.
- Release metadata MUST describe signing and notarization accurately; ad-hoc signing MUST NOT be represented as
  Developer ID signing or notarization.
- Manual release dispatch MUST create a draft prerelease candidate, while a final release MUST require a tag matching
  the version in `deno.json` and MUST refuse to replace an existing release.

### Diagnostics

- Host diagnostics MUST use the shared prefixed logger.

## Decisions

- 2026-09-08: Remove the attachment resolver and its page plugins after the dedicated Laufey build upgraded to CEF
  150.0.14 and live validation confirmed native redirected image loading.
- 2026-09-08: Remove the shared window manager, DOM readiness observer, page probe loader, probe composer, and
  `executeJs` response types after the attachment plugins ceased to consume them.

## Verification limits

The icon catalog contains light (`NSAppearanceNameAqua`), dark (`NSAppearanceNameDarkAqua`), and tintable
(`ISAppearanceTintable`) image stacks. The user approved the visible result on macOS 26.5.2. The compiled fallback
decodes successfully, but execution on older macOS releases and separate recorded checks of Finder, Dock, and
Cmd+Tab remain unverified.

Normal and strict deep signature verification pass for bundles built from Laufey fork release `v0.7.1-cef_150`.
That published CEF 150.0.14 framework does not contain the previous self-referencing `Versions/A/A -> A` symlink.

## Files

Single concern file. Packaging can become a separate concern when another operating system target is actually
configured.

## Reference

<!-- cumaru:reference -->
| Link                                                   | Description                                                                                 |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| [entrypoint](src/app.ts)                               | Orders boot server startup and main Chat window creation.                                   |
| [main window](src/main.ts)                             | Creates the Chat window, menus, dimensions, and navigation target.                          |
| [boot server](src/server/index.ts)                     | Serves the embedded loopback bootstrap document.                                            |
| [bootstrap document](assets/bootstrap.html)            | Provides the minimal local HTML required by the measured runtime boot contract.             |
| [desktop configuration](deno.json)                     | Defines the entrypoint export, CEF backend, app identity, icon, output, and import aliases. |
| [build script](build.sh)                               | Compiles the appearance catalog and fallback, packages resources, and signs the bundle.                                  |
| [bundle path test](tests/bundle_path_test.sh)           | Enforces the canonical output base and bundle path across configuration and scripts.         |
| [constants](src/util/constants.ts)                     | Centralizes the Chat URL and runtime timing values.                                         |
| [delay](src/util/delay.js)                             | Supplies the startup and window-construction waits.                                         |
| [logger](src/util/logger.ts)                           | Emits prefixed host diagnostics while suppressing browser-side output.                      |
| [macOS icon](assets/GoogleChat.icns)                   | Checked-in compiled fallback used as Deno's direct icon input.                                 |
| [dark brand image](assets/google-chat-deno-dark.png)   | Retained dark-background application branding source.                                       |
| [light brand image](assets/google-chat-deno-light.png) | Retained light-background application branding source.                                      |
| [Icon Composer document](assets/AppIcon.icon/icon.json) | Canonical user-approved layers, fills, and appearance settings compiled by actool. |
| [embedded icon artwork](assets/AppIcon.icon/Assets/google-chat-deno-light.png) | Image layer embedded in the self-contained Icon Composer document. |
| [release workflow](.github/workflows/release.yml)       | Builds guarded macOS arm64 releases from the pinned Laufey runtime artifact.       |
<!-- /cumaru:reference -->
