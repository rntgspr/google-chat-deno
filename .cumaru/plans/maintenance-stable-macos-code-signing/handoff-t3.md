---
human_revised: false
plan: maintenance-stable-macos-code-signing
task: T3
status: complete
date: 2026-09-12
summary: Persistent signing succeeded in GitHub Actions, temporary credentials were removed, and signed draft candidate v0.0.1-rc.1 is ready for installation.
---

# Hand-off — maintenance-stable-macos-code-signing / T3

## Files touched

<!-- cumaru:touched -->
| Link | Description |
|------|-------------|
| [Build script](../../../build.sh) | Added explicit inside-out signing with the CI identity and retained local ad-hoc builds. |
| [Release workflow](../../../.github/workflows/release.yml) | Added temporary signing credential import and cleanup and updated signing metadata. |
| [Plan](index.md) | Marked T3 done. |
| [T3](t3.md) | Recorded completion and linked the release evidence. |
<!-- /cumaru:touched -->

## Decisions made during implementation

- CI imports the T2 identity before build.sh and restricts its Keychain import to codesign. The three
  private secrets are supplied only to the import step; the build receives the public identity name
  and temporary Keychain path.
- The dedicated signing directory lives under RUNNER_TEMP. The PKCS#12 is removed immediately after
  import. An always-run cleanup step deletes the signing Keychain and removes its directory before
  packaging, including when import or build fails. GitHub-hosted runner disposal is the final fallback.
- Persistent signing discovers regular Mach-O files without following symlinks, then signs nested
  app/framework bundles in depth order and the main app last. It uses timestamp=none and adds no
  hardened-runtime flags, entitlements, trust changes, or credential-architecture changes.
- build.sh uses Bash with pipefail so failures in its NUL-delimited traversal stop the build. Missing
  parts of the CI signing configuration fail explicitly; local builds without that configuration keep
  the existing ad-hoc signature.
- No new tests or verification gates were added. Existing workflow checks predate this plan and remain
  unchanged. T4 remains the manual application installation task.
- The candidate is produced from a dedicated maintenance-stable-macos-code-signing branch through
  the existing manual draft-prerelease workflow, without moving main or publishing a final version.

## Commands run / verification

- Reviewed the implementation diff and confirmed there are no whitespace errors.
- Confirmed the remote already has the dispatchable Release workflow and no existing releases.
- Implementation commit: 05b071c on maintenance-stable-macos-code-signing. The working branch includes
  the user's existing local baseline commit 51b619e and the signing work; main was not advanced.
- Following explicit user authorization, the branch was pushed and candidate v0.0.1-rc.1 was dispatched.
  Run: https://github.com/rntgspr/google-chat-deno/actions/runs/34727753380.
- The first run imported the identity successfully but signing reported no identity found; cleanup
  succeeded. The import step omitted registering the Keychain in the runner user's search list,
  which the codesign manual requires even when an explicit Keychain selects the signing identity.
  Added that runner-only registration before repeating the candidate.
- The corrected run completed successfully: [Actions run 34727864638](https://github.com/rntgspr/google-chat-deno/actions/runs/34727864638),
  source commit 148f3f496360f49913fd16da680abc9ebdeccad3. Import, build/signing, temporary-credential
  cleanup, existing bundle validation, packaging, artifact upload, and draft release creation succeeded.
- The unchanged existing strict signature check reported PASS. No additional tests or cross-build
  validation were introduced or run; manual app installation remains T4.
- Release metadata identifies self-signed signing and no notarization. The uploaded package contains
  the app and launcher; private credential paths remain confined to the separately cleaned runner directory.

## Installation artifact

| Field | Value |
|-------|-------|
| Candidate | v0.0.1-rc.1 |
| Release state | Draft prerelease |
| Release | [GitHub draft](https://github.com/rntgspr/google-chat-deno/releases/tag/untagged-ae7208153a5b82dd7966) |
| Package | GoogleChatDeno-v0.0.1-aarch64-apple-darwin.tar.gz |
| Size | 147481883 bytes |
| SHA256 | 56ade47ac7866e32b37b874e34350f4f281a35dd35b017fdf139a29c3c9abfe3 |
| Companion asset | SHA256SUMS |
| Branch | maintenance-stable-macos-code-signing |

Both release assets report uploaded. Access to the draft requires an authorized GitHub account.
Extract the package and use its run.sh launcher for the existing durable-profile behavior.

## Pending / follow-ups

- T4 installs the resulting app; no installation or cross-release credential continuity is claimed here.
- The implementation branch is published; main has not been merged or advanced by this task.

## Suggestions for the Lead

The existing workflow metadata reports strict signature status. Keep that output consistent with the
unchanged existing check. The bootstrap spec should describe self-signed official releases and ad-hoc
local builds when the plan is absorbed.
