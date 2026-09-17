---
human_revised: false
plan: maintenance-persist-google-session
task: T1
status: complete
date: 2026-09-16
summary: Laufey now accepts and persists a macOS CEF profile path supplied through the environment.
---

# Hand-off — maintenance-persist-google-session / T1

## Files touched

<!-- cumaru:touched -->
| Link | Description |
|------|-------------|
| [runtime task record](plans/maintenance-persist-google-session/t1.md) | created — records the external Laufey change committed as `c4a65b9`. |
<!-- /cumaru:touched -->

## Decisions made during implementation

- Keep the PID-scoped temporary profile as the fallback so other Laufey consumers retain existing behavior.
- Set both `cache_path` and `root_cache_path`; enable session-cookie persistence only for the explicit durable profile.
- The external implementation is `rntgspr/laufey@c4a65b9` in `cef/src/main_mac.mm`.

## Commands run / verification

- `/opt/homebrew/opt/llvm/bin/clang-format --dry-run --Werror cef/src/main_mac.mm` — passed.
- `make cef` — passed with the local CEF 150.0.14 checkout.
- Direct application launch — CEF helper arguments contained the expanded persistent path as `--user-data-dir`.

## Pending / follow-ups

- The tagged runtime workflow and release are tracked by T3.

## Suggestions for the Lead

- None.
