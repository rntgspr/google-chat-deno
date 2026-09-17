---
human_revised: false
plan: maintenance-persist-google-session
status: draft
date: 2026-09-16
summary: Replace launcher-managed profile symlinks with a bundle-provided Laufey profile contract.
---

# Delta draft — maintenance-persist-google-session

## specs/session/index.md

### Added Requirements

- WHEN Laufey starts with `LAUFEY_CEF_PROFILE_PATH` THE SYSTEM SHALL expand the path and use it for persistent CEF storage.
- WHEN the macOS application launches from Finder THE SYSTEM SHALL receive its profile path through the bundle's `LSEnvironment` configuration.
- WHEN a user relaunches the application after authentication THE SYSTEM SHALL reuse the same Google session profile.
- The development launcher MUST pass the same explicit profile environment used by packaged builds.

### Modified Requirements

- A distributed release MUST launch through `GoogleChatDeno.app` directly and MUST NOT require a wrapper script
  (was: A distributed release MUST include and launch through `run.sh`).
- The persistent profile MUST live under the application identifier's Application Support directory
  (was: Launchers MUST symlink PID-scoped temporary profiles to that directory).

### Removed Requirements

- Remove the process watcher, PID-derived symlink, stale-link sweep, and packaged-launcher requirements because Laufey now accepts the profile path before CEF initialization.

## specs/runtime/bootstrap.md

### Added Requirements

- The macOS build MUST configure `LAUFEY_CEF_PROFILE_PATH` in `Info.plist` before code signing.
- A release archive MUST place `GoogleChatDeno.app` at its root and MUST NOT include `run.sh`.
- The release workflow MUST verify the embedded profile value before publishing.

### Modified Requirements

- The build script MUST configure the icon and persistent profile before signing the application bundle.
- Release metadata MUST direct users to open `GoogleChatDeno.app` directly.
