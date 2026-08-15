---
human_revised: false
name: session
summary: Durable Google session storage through launcher-managed symlinks to Laufey's pid-scoped CEF profile.
depends-on: [specs/runtime]
relates: [specs/chat-host, specs/runtime/bootstrap]
apps: [launcher, host]
---

# Session

## Overview

Laufey stores its CEF profile under `$TMPDIR/laufey_cef_<pid>/`. Without intervention every launch
uses a new process identifier and therefore a new profile, losing Google cookies and local storage.
The runtime and desktop configuration expose no supported cache/profile-path option, and Chromium's
`--user-data-dir` is overwritten by Laufey.

Both source and packaged launchers preserve the session by watching for the Laufey process and
creating a pid-named symlink to
`~/Library/Application Support/com.rntgspr.google-chat-deno/cef`. This is intentionally outside the
host process because CEF initializes storage before application code can redirect it.

## Launcher behavior

The development launcher starts its watcher before `deno desktop --hmr`. The actual CEF process is a
child created after compilation, so its pid cannot be derived from the shell or predicted safely.
The launcher enables the Deno inspector at `127.0.0.1:$INSPECTOR_PORT` only when `--inspector` is
its first argument; otherwise it neither enables nor advertises the inspector. Remaining arguments
continue to the application after the launcher consumes that option.
The packaged launcher similarly starts a watcher, then uses `open -n -W` to launch the `.app`; the
Laufey binary inside that bundle owns the profile pid.

Each watcher polls every 10 ms for at most 6,000 iterations. Before launch, stale pid symlinks older
than 120 minutes are removed. Development and packaged launches point to the same durable profile
and therefore cannot safely run concurrently.

## Requirements (EARS / RFC 2119)

- The application MUST be launched through `dev.sh` or `run.sh` when its Google session must persist.
- The durable profile MUST live outside `$TMPDIR` under the application identifier's support
  directory.
- A launcher MUST start its Laufey process watcher before starting the desktop runtime or app bundle.
- The watcher MUST derive the profile link name from the observed Laufey pid rather than the shell
  pid.
- Stale pid symlinks SHALL be swept before every launch.
- The development launcher MUST pass `--hmr` and the configured entrypoint to `deno desktop`.
- WHEN `dev.sh` is invoked with `--inspector` as its first argument THE SYSTEM SHALL enable the Deno
  inspector at `127.0.0.1:$INSPECTOR_PORT`.
- WHEN `dev.sh` is invoked without `--inspector` THE SYSTEM SHALL NOT enable or advertise the Deno
  inspector.
- WHEN the development launcher consumes `--inspector` THE SYSTEM SHALL preserve all remaining
  application arguments.
- The packaged launcher MUST open a new app instance and wait for it to terminate.
- A distributed release MUST include executable `run.sh` beside `dist/` and MUST direct users to launch through it so
  the durable profile contract is preserved.
- Development and packaged instances MUST NOT run simultaneously against the shared profile.

## Decisions

- 2026-09-04: Use the same process-watcher strategy for development and packaged launch because both
  paths ultimately place CEF in a Laufey process whose pid is not available before launch.
- 2026-09-04: Keep the profile under macOS Application Support and key it by the bundle identifier.

## Known gaps

- The profile directory naming convention is undocumented and may change without warning.
- The watcher races CEF initialization. Losing the race silently creates an empty profile and
  presents a login screen.
- Laufey single-instance behavior reports profile contention as exit code 24 rather than a clear
  lock error.

## Files

Single-concern area. Split development and packaged launch only if their profile strategies diverge.

## Reference

<!-- cumaru:reference -->
| Link | Description |
|------|-------------|
| [packaged launcher](run.sh) | Watches for packaged Laufey, links its pid profile, and waits for the app. |
| [development launcher](dev.sh) | Watches for the compiled Laufey child and runs the source entrypoint with HMR. |
<!-- /cumaru:reference -->
