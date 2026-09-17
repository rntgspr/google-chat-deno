---
human_revised: false
scope:
  - session
  - runtime/bootstrap
status: in-progress
summary: Persist the Google session in the macOS app bundle and publish the paired Laufey and application releases.
apps: [launcher, bundle]
aux: []
---

# Persist the Google session in the macOS app

## Overview

Replace the temporary PID-scoped CEF profile workaround with an explicit profile path delivered by
the macOS app bundle. Laufey will honor that path during CEF initialization, and the application build
will inject it into `Info.plist` before signing so launches from Finder preserve the Google session.

The packaged `run.sh` launcher will be removed. `dev.sh` remains a development-only entry point and
uses the same runtime contract directly through its environment.

## Acceptance Criteria (EARS / RFC 2119)

- WHEN a signed application bundle is built THE SYSTEM SHALL declare `LAUFEY_CEF_PROFILE_PATH` in its `Info.plist` before signing.
- WHEN Laufey starts with `LAUFEY_CEF_PROFILE_PATH` THE SYSTEM SHALL use the expanded absolute path as the persistent CEF root and cache path.
- WHEN a user signs in and relaunches the application from Finder THE SYSTEM SHALL restore the same Google session without requesting credentials again.
- The release archive MUST contain a directly launchable `GoogleChatDeno.app` and MUST NOT contain `run.sh`.
- The development launcher MUST remain development-only and MUST use the explicit profile environment instead of PID-scoped symlinks.
- The application release MUST pin a published Laufey artifact containing the persistent profile contract.
- The Laufey runtime and Google Chat application MUST each have a published versioned release for this change.

## Plan / DAG

| Task | Title | Status | Depends on |
|------|-------|--------|-----------|
| [T1](t1.md) | Add native persistent CEF profile support | done | — |
| [T2](t2.md) | Integrate the profile into build and packaging | done | T1 |
| [T3](t3.md) | Publish and verify the paired releases | in-progress | T1, T2 |

## Out of scope

- Persistent profile configuration for non-macOS Laufey backends.
- Apple notarization or Developer ID distribution.
- Changes to Google authentication behavior itself.

## Risks

- Launch Services only injects `LSEnvironment` for bundle launches; Laufey expands `~` before CEF initialization so the configured value becomes absolute.
- Two concurrent processes cannot safely own the same Chromium profile; the existing single-instance CEF behavior remains authoritative.
- The application release depends on the new Laufey tag and cannot publish until its runtime artifact is available.
