---
human_revised: false
summary: Deployment scope clarified by the user, with persistent signing and installation as the only test.
---

# Exploration record — stable macOS code signing

## Direction

Use one persistent self-signed Code Signing identity for official macOS releases of GoogleChatDeno.app.
Create it outside CI, keep an encrypted offline backup, store the required secrets in GitHub Actions,
and import the identity into a dedicated temporary Keychain on the macOS runner.

The runner consumes the pinned Laufey runtime and assembles our application. Signing applies to the
incorporated executable code and then to the main app bundle, before release packaging. This does not
require changing the Laufey source repository or its release pipeline.

## User clarification

The current user instruction narrows this work to deployment. Installing the released app is the only
test. Earlier prototype, structural, signature-verification, archive re-extraction, cross-build,
credential migration, negative-control, and clean-environment test requirements are withdrawn.
There is no APPROVED/REJECTED investigation gate before implementation.

The source handoff's statement about manual SHA1/CDHash authorization is an unverified premise,
not a reason to replace the user's Keychain or redesign credential storage. The desired signing
identity remains persistent, but installation alone does not prove Keychain continuity across releases.

## Keychain boundary

- The temporary signing Keychain holds the certificate and private key used by deployment tools.
- The existing user Keychain holds application credentials and must not be replaced or reconfigured.
- Preserve the existing Laufey/CEF profile, credential items, access policies, and launcher behavior.
- Do not add manual hash setup, certificate trust setup, or broad credential permissions on user machines.

## Operational constraints

Generate the production identity once outside CI. Keep the private key, PKCS#12, passwords, and temporary
signing material outside source control, logs, artifacts, and release archives. Preserve the encrypted
offline backup when cleaning up temporary files.

Retain the bundle identifier and existing release path. Apple Developer ID, notarization, Gatekeeper
workarounds, additional platforms, and credential migration remain outside this deployment.

The current task sequence and acceptance criteria are canonical in [the plan](index.md).
