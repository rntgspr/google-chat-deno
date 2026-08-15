---
human_revised: false
name: Repository
summary: Repository ownership, version-control hygiene, and clone reproducibility for project and agent configuration.
depends-on: []
apps: [platform]
---

# Repository

## Overview

This area defines which project artifacts belong in version control and which machine-local or
generated artifacts stay outside it. The repository must remain usable from a fresh clone without
depending on files that exist only in one contributor's workspace.

## Requirements (EARS / RFC 2119)

- The repository MUST version project-owned source, configuration, documentation, and required
  agent integration artifacts.
- The repository MUST NOT version generated build output, runtime logs, or operating-system
  metadata.
- The repository MUST version the GitHub workflow that builds release candidates from pinned runtime artifacts and
  publishes final releases only after its validation gates pass.

## Decisions

- 2026-09-05: Repository hygiene is tracked as a platform concern because it applies across every
  application component.

## Files

- [version-control.md](version-control.md) — tracked-file and ignore-rule policy.

## Reference

Repository policy files are not part of the source coverage set, so this area has no source rows.

<!-- cumaru:reference -->
| Link | Description |
|------|-------------|
| [release workflow](.github/workflows/release.yml) | Builds and publishes guarded releases from pinned runtime artifacts. |
<!-- /cumaru:reference -->
