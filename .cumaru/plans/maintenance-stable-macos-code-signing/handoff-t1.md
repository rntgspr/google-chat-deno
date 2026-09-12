---
human_revised: false
plan: maintenance-stable-macos-code-signing
task: T1
status: complete
date: 2026-09-12
summary: Deployment integration mapped to the existing build signing call, runner-only credentials, embedded Laufey code, and current release packaging.
---

# Hand-off — maintenance-stable-macos-code-signing / T1

## Files touched

<!-- cumaru:touched -->
| Link | Description |
|------|-------------|
| [Plan](index.md) | Marked T1 done in the task sequence. |
| [T1](t1.md) | Recorded completion and linked this deployment map. |
| [Handoff](handoff-t1.md) | Created the source-backed deployment integration map for T2 and T3. |
<!-- /cumaru:touched -->

## Current deployment map

| Stage | Existing implementation | Integration consequence |
|-------|-------------------------|-------------------------|
| Release selection | [release.yml](../../../.github/workflows/release.yml), lines 3–80: version tags publish final releases; manual dispatch produces draft prerelease candidates and refuses an existing release tag. | Reuse these entry points and publication protections. |
| Toolchain | Same workflow, lines 21–28 and 82–94: macOS arm64, Xcode 26.6, Deno 2.9.6, CEF 150.0.14, Laufey v0.7.1-cef_150. | Signing belongs to the existing macOS release job; no new architecture or runtime build is needed. |
| Runtime acquisition | Same workflow, lines 96–142: downloads the pinned Laufey archive from rntgspr/laufey into RUNNER_TEMP and exports LAUFEY_DEV_DIR. | Consume that artifact unchanged; do not modify the Laufey release pipeline. |
| App assembly | [build.sh](../../../build.sh), lines 15–33: compiles icons, invokes deno desktop, installs icon resources, and updates Info.plist. | Complete all resource and metadata mutations before persistent signing. |
| Existing signing | Same script, line 35: codesign --force --deep --sign - on dist/GoogleChatDeno.app. | This is the replacement point for explicit persistent signing in official builds. |
| Package | [release.yml](../../../.github/workflows/release.yml), lines 192–260: creates a tar.gz containing dist/GoogleChatDeno.app, executable run.sh, and release metadata; produces SHA256SUMS and release notes. | Keep the package shape; update both current Signing: ad-hoc labels to self-signed. |
| Publication | Same workflow, lines 262–284: uploads the artifact and creates the GitHub release. | Publish through the existing mechanism after signing and packaging. |

## Application identity and embedded code

[deno.json](../../../deno.json), lines 12–23, declares the CEF backend, bundle identifier
com.rntgspr.google-chat-deno, and output base ./dist/GoogleChatDeno. The final signing target is
dist/GoogleChatDeno.app. The main executable inside our app is still named laufey; this does not make
the signing target the separately published Laufey runtime archive.

The release configuration names these incorporated code units:

| Location inside GoogleChatDeno.app | Code unit |
|----------------------------------|-----------|
| Contents/MacOS/laufey | Main executable, signed through the final app bundle. |
| Contents/MacOS/laufey.dylib | Embedded runtime library. |
| Contents/Frameworks/Chromium Embedded Framework.framework | CEF framework bundle. |
| Contents/Frameworks/laufey Helper.app | General helper application. |
| Contents/Frameworks/laufey Helper (Alerts).app | Alerts helper application. |
| Contents/Frameworks/laufey Helper (GPU).app | GPU helper application. |
| Contents/Frameworks/laufey Helper (Plugin).app | Plugin helper application. |
| Contents/Frameworks/laufey Helper (Renderer).app | Renderer helper application. |

Source evidence is release.yml, lines 155–175. The sibling
[Laufey CMake configuration](../../../../laufey/cef/CMakeLists.txt), lines 129–165, also shows the
framework copy and helper bundles copied into Contents/Frameworks. This local source corroborates
the layout; it is not a binary inspection of the pinned release artifact.

The T3 signing order is inside out: any executable leaves nested within a framework or helper first,
then their containing framework/helper bundles and the standalone laufey.dylib, then the main
GoogleChatDeno.app last. Sibling units need no artificial ordering. Do not sign symlink aliases as
independent code or mutate the bundle after its final signature. The configuration does not enumerate
CEF's internal leaf files; T3 must traverse the incorporated code during signing instead of hardcoding
an invented exhaustive list. No prototype build is required for T1.

## Integration decisions for T2 and T3

- T2 provides scripts/provision_macos_signing_identity.sh and the three planned Actions secrets.
  The scripts directory does not currently exist. Production material belongs outside the repository,
  with an encrypted offline backup, and is generated once outside CI.
- T3 imports the identity immediately before the existing Build the Chat bundle step. The current
  build.sh signs at the end of assembly, so the key must already be available when that call runs.
  This keeps signing at the established integration point without a second build path.
- T3 replaces the official-build ad-hoc operation with explicit nested signing and the final bundle
  signature. Keep ordinary local builds usable without production secrets; avoid reapplying ad-hoc
  signing after the persistent signature.
- Limit decoded PKCS#12 and signing Keychain files to dedicated RUNNER_TEMP paths. Configure signing-tool
  access on that Keychain only. Add unconditional cleanup that also handles a partially failed import;
  credentials must not enter the package or artifact upload paths.
- Preserve [run.sh](../../../run.sh), lines 12–34, and its existing profile directory and launch behavior.
  No application source, user Keychain, credential item, trust setting, or Laufey source change is needed
  for this deployment integration.

## Existing checks and the revised scope

The current workflow already includes toolchain assertions, runtime checksum/layout checks, a Validate
the Chat bundle step with codesign verification, and archive re-extraction checks. They predate this
plan. None were executed, added, or changed in T1. This inventory is not a new test requirement.

The revised plan excludes unrelated cleanup of existing safeguards and adds no tests or verification
gates. T4 manual installation is the only test assigned by this plan. If T3 changes any existing
workflow step, retain consistency with its outputs: STRICT_STATUS is currently consumed by both the
package metadata and release notes. Do not leave dangling references or report a check that did not run.

## Commands run / verification

- Read the current plan, task, exploration, handoff template, build.sh, deno.json, release.yml, and run.sh.
- Used source searches and read Laufey's local CMake packaging configuration to identify embedded units.
- Reviewed the written handoff and task status changes; no build, application test, signing command,
  Keychain operation, secret upload, installation, or release dispatch was executed.

## Pending / follow-ups

- T2: implement and provision the production signing identity and its backup.
- T3: integrate runner credential handling and signing at the mapped deployment points.
- T4: install the resulting released app and record the actual outcome.

## Suggestions for the Lead

On plan close, update the bootstrap spec's current ad-hoc signing statement to match the implemented
official-release behavior. The session spec requires no change when the launcher and profile remain
unchanged. Do not describe cross-release credential continuity as proven by this source inspection.
