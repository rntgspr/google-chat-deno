---
human_revised: false
name: session
summary: Durable Google session storage through a bundle-provided Laufey CEF profile contract.
depends-on: [specs/runtime]
relates: [specs/chat-host, specs/runtime/bootstrap]
apps: [launcher, bundle]
---

# Session

## Overview

The application stores its CEF profile at
`~/Library/Application Support/com.rntgspr.google-chat-deno/cef`. The canonical value lives in
`scripts/profile_env.sh`; development sources it directly, while the macOS build writes it to the
bundle's `LSEnvironment` dictionary before signing.

Laufey reads `LAUFEY_CEF_PROFILE_PATH` before CEF initialization, expands a leading tilde with
Foundation, and assigns the resulting absolute path to both `cache_path` and `root_cache_path`. It
also enables session-cookie persistence for that explicit profile. Laufey retains its PID-scoped
temporary path as a compatibility fallback when the environment variable is absent.

The packaged application is opened directly as `GoogleChatDeno.app`; no launcher wrapper or profile
symlink watcher participates in startup. The development-only `dev.sh` launcher supplies the same
profile contract while retaining HMR and optional inspector behavior.

## Requirements (EARS / RFC 2119)

- The durable profile MUST live outside `$TMPDIR` under the application identifier's Application Support directory.
- WHEN Laufey starts with `LAUFEY_CEF_PROFILE_PATH` THE SYSTEM SHALL expand the path and use it as both the CEF cache and root cache.
- WHEN Laufey uses an explicit persistent profile THE SYSTEM SHALL enable persistence for session cookies.
- WHEN the macOS application launches through Launch Services THE SYSTEM SHALL receive the profile path from the signed bundle's `LSEnvironment` configuration.
- WHEN a user relaunches the application after authentication THE SYSTEM SHALL reuse the same Google session profile.
- The development launcher MUST pass the same explicit profile environment used by packaged builds.
- The development launcher MUST pass `--hmr` and the configured entrypoint to `deno desktop`.
- WHEN `dev.sh` is invoked with `--inspector` as its first argument THE SYSTEM SHALL enable the Deno
  inspector at `127.0.0.1:$INSPECTOR_PORT`.
- WHEN `dev.sh` is invoked without `--inspector` THE SYSTEM SHALL NOT enable or advertise the Deno
  inspector.
- WHEN the development launcher consumes `--inspector` THE SYSTEM SHALL preserve all remaining
  application arguments.
- A distributed release MUST launch through `GoogleChatDeno.app` directly and MUST NOT require a wrapper script.
- Development and packaged instances MUST NOT run simultaneously against the shared profile.

## Decisions

- 2026-09-16: Pass the profile through `LSEnvironment` because Launch Services applies it before the bundled Laufey process initializes CEF.
- 2026-09-16: Expand tilde paths in Laufey so the plist can remain user-independent and the CEF setting is absolute.
- 2026-09-16: Keep the profile under macOS Application Support and key it by the bundle identifier.
- 2026-09-16: Retain Laufey's temporary PID-scoped profile only when no explicit profile environment is provided.

## Known gaps

- Laufey single-instance behavior reports profile contention as exit code 24 rather than a clear
  lock error.

## Files

Single-concern area. Split development and packaged configuration only if their profile contracts diverge.

## Reference

<!-- cumaru:reference -->
| Link | Description |
|------|-------------|
| [development launcher](dev.sh) | Runs the source entrypoint with HMR and the explicit persistent profile environment. |
| [profile environment](scripts/profile_env.sh) | Owns the canonical profile path shared by development and bundle configuration. |
| [bundle profile configuration](scripts/configure_macos_profile.sh) | Writes the profile contract into `Info.plist` before signing. |
| [macOS profile test](tests/macos_profile_config_test.sh) | Proves idempotent plist configuration and preservation of existing environment entries. |
| [build script](build.sh) | Configures the profile in the application bundle before code signing. |
<!-- /cumaru:reference -->
