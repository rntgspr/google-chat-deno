---
human_revised: false
name: Version control
summary: Git tracks project state while local agent adapters and generated artifacts remain only in the workspace.
depends-on: []
relates: []
apps: [platform]
---

# Version control

## Overview

Git is the canonical source for project-owned files. Ignore rules keep generated artifacts and local
agent adapters available in the workspace without including them in repository history.

## Requirements (EARS / RFC 2119)

- The ignore policy MUST use the narrowest rule that identifies each disposable artifact class.
- The tracked tree MUST contain project-owned source, configuration, documentation, and Cumaru knowledge.
- Git MUST NOT track `.DS_Store` operating-system metadata.
- The ignore policy MUST exclude root build output, generated application bundles, runtime logs, and
  local Claude adapter artifacts.
- Git MUST NOT track the local `.agents` and `.codex` adapter directories.
- Removing a local adapter from Git MUST preserve its files in the working directory.
- A tracked file MUST NOT also match the effective ignore policy.

## Decisions

- 2026-09-05: The tracked set and ignore policy require an explicit audit under `GH-5`.
- 2026-09-05: `.agents` and `.codex` are local adapter surfaces that remain on disk but outside Git;
  `.DS_Store`, build output, bundles, logs, and local Claude files are also excluded.

## Reference

Repository policy files are not part of the source coverage set, so this concern has no source rows.

<!-- cumaru:reference -->
| Link | Description |
|------|-------------|
<!-- /cumaru:reference -->
