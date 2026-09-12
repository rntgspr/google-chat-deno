---
human_revised: false
scope: [specs/runtime/bootstrap.md, specs/repository]
status: in-progress
summary: Deploy persistent self-signed macOS application signing through GitHub Actions, with app installation as the only test.
apps: [bundle]
aux: [exploration.md]
---

# Stable macOS code signing

## Overview

Replace ad-hoc signing of official GoogleChatDeno.app releases with one persistent self-signed Code
Signing identity. GitHub Actions consumes the pinned Laufey runtime, assembles our application, imports
the signing identity into a temporary runner Keychain, signs embedded code and the main bundle, and
packages the release.

This is deployment work. The user's revised scope makes installing the released app the only test.
Do not add structural tests, signature-verification gates, prototype builds, cross-build comparisons,
credential migration experiments, negative controls, or clean-environment matrices.

The runner Keychain stores signing material only. Preserve the user's existing Keychain, credentials,
Laufey/CEF profile, and launch behavior. No credential-architecture change belongs to this plan.

## Acceptance Criteria (EARS / RFC 2119)

- Official releases MUST use the same persistent self-signed Code Signing certificate and private key,
  created once outside CI.
- The application MUST retain the bundle identifier com.rntgspr.google-chat-deno.
- The existing release workflow MUST sign the assembled GoogleChatDeno.app, including embedded code
  that requires signing, before packaging.
- Signing credentials MUST be imported into a dedicated temporary runner Keychain and cleaned up
  after the job, including failure paths.
- Private signing material MUST remain outside source control, logs, artifacts, and release archives.
- The repository MUST provide an operator-invoked provisioning script for production identity creation,
  encrypted offline backup, and repository Actions secret upload without exposing secret values.
- Maintainer instructions MUST describe one-time setup, required secrets, backup, and recovery.
- This deployment MUST NOT replace the user's Keychain, recreate credentials, alter credential ACLs,
  change certificate trust on the user's machine, or redesign Laufey/CEF credential storage.
- Release metadata MUST identify self-signed signing and the absence of notarization accurately.
- Manual installation of the released app MUST be the only test; record the actual installation
  outcome without claiming cross-release credential continuity or other untested behavior.

## Plan / DAG

| Task | Title | Status | Depends on |
|------|-------|--------|-----------|
| [T1](t1.md) | Map the existing deployment integration | done | — |
| [T2](t2.md) | Provision the production signing identity | pending | T1 |
| [T3](t3.md) | Integrate signing into the release workflow | pending | T2 |
| [T4](t4.md) | Install the released application | pending | T3 |

## Out of scope

- Automated suites, structural tests, signature-verification test steps, archive re-extraction checks,
  multi-build identity comparisons, migration experiments, negative controls, and clean-environment tests.
- Replacing or modifying the user's Keychain, stored credentials, trust policy, or credential ACLs.
- Changes to Laufey source, its upstream release pipeline, CEF profile persistence, or application code.
- Apple Developer ID, notarization, Gatekeeper workarounds, and Mac App Store distribution.
- New architectures, certificate rotation, or a credential migration project.
- Removing unrelated existing repository tests or safeguards; this revision changes this plan only.

## Risks

- Installation alone does not establish credential continuity between releases; no such proof is
  claimed by this plan.
- Losing the signing private key loses the persistent identity; maintainers need an encrypted offline
  backup and recovery instructions.
- Incorrect nested signing or packaging may produce an unusable app; the agreed test remains manual
  installation rather than additional validation gates.
- Secrets must target the intended GitHub repository, and temporary cleanup must preserve the backup.
