---
human_revised: false
plan: maintenance-persist-google-session
task: T2
status: complete
date: 2026-09-16
summary: The application build now embeds the profile contract and releases the app without a launcher wrapper.
---

# Hand-off — maintenance-persist-google-session / T2

## Files touched

<!-- cumaru:touched -->
| Link | Description |
|------|-------------|
| [`build.sh`](build.sh) | modified — configures the profile before signing. |
| [`dev.sh`](dev.sh) | modified — uses the runtime environment directly without a symlink watcher. |
| [`scripts/configure_macos_profile.sh`](scripts/configure_macos_profile.sh) | created — idempotently configures `LSEnvironment`. |
| [`scripts/profile_env.sh`](scripts/profile_env.sh) | created — owns the canonical application profile path. |
| [`tests/bundle_path_test.sh`](tests/bundle_path_test.sh) | modified — enforces direct bundle distribution and the development profile contract. |
| [`tests/macos_profile_config_test.sh`](tests/macos_profile_config_test.sh) | created — proves idempotent plist configuration and preservation of existing values. |
| [`.github/workflows/release.yml`](.github/workflows/release.yml) | modified — pins the new runtime, validates the plist, and packages the app at archive root. |
| [`deno.json`](deno.json) | modified — bumps the application to 0.0.3. |
<!-- /cumaru:touched -->

## Decisions made during implementation

- Keep the profile path in one sourced shell file so development and packaged builds share the same identity.
- Place `GoogleChatDeno.app` at the archive root because it is now the release entry point.
- Run focused source-contract tests in the release workflow before building.
- Remove `run.sh`; the absence contract is enforced by the bundle-path test and release packaging checks.

## Commands run / verification

- `./tests/macos_profile_config_test.sh` — passed.
- `./tests/bundle_path_test.sh` — passed.
- `deno test --allow-read src/app/index_test.ts` — 2 passed, 0 failed.
- `./build.sh` — passed and produced an ad-hoc signed bundle.
- `codesign --verify --deep dist/GoogleChatDeno.app` — passed.
- Direct launch after authentication — opened `chat.google.com/u/0/app/home` without requesting credentials.

## Pending / follow-ups

- The repository-wide `deno test --allow-read` remains blocked by the pre-existing stale `src/main.ts` import in `src/overlay/probe_test.ts`.
- Publication and release-asset validation are tracked by T3.

## Suggestions for the Lead

- Remove or relocate the stale overlay test in a separate maintenance change; it is unrelated to session persistence.
