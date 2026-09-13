---
human_revised: false
plan: maintenance-stable-macos-code-signing
task: T2
status: complete
date: 2026-09-12
summary: Production signing identity provisioned with an encrypted backup, all three Actions secrets present, and temporary private staging removed.
---

# Hand-off — maintenance-stable-macos-code-signing / T2

## Files touched

<!-- cumaru:touched -->
| Link | Description |
|------|-------------|
| [Plan](index.md) | Marked T2 done. |
| [T2](t2.md) | Recorded completion at the operator-selected backup location and linked this handoff. |
| [Maintainer instructions](../../../scripts/README.md) | Created one-time setup and recovery instructions. |
| [Provisioning script](../../../scripts/provision_macos_signing_identity.sh) | Created the operator-invoked identity, backup, and Actions secret provisioning script. |
<!-- /cumaru:touched -->

## Decisions made during implementation

- The user selected /Users/gaspar/workspace/g-deno/crypto for the encrypted backup. It is outside
  Git repositories. Directory access is restricted to its owner.
- Backup is an AES-256 encrypted disk image containing the PKCS#12 identity and recovery credentials.
  Its password is entered at a hidden terminal prompt and is not sent through chat or uploaded.
- Provisioning uses OpenSSL without creating or modifying a local Keychain. A temporary signing
  Keychain belongs to the runner integration in T3.
- Maintainer instructions are canonical in scripts/README.md. Script implementation was delegated
  as a bounded subtask under Lead authority and reviewed by the Lead before production execution.
- The certificate uses RSA-4096, SHA256, digitalSignature and codeSigning extensions, and a 3650-day
  validity. The PKCS#12 explicitly uses PBE-SHA1-3DES with a SHA1 MAC and 100000 iterations for macOS
  import compatibility; this container choice does not change the certificate signature algorithm.
- The script refuses existing signing secrets, an existing backup, or unrecovered staging rather
  than accidentally generating a replacement identity. Backup failure preserves private staging.
- Password uploads strip trailing line breaks and use standard input. Shell tracing, automatic
  export, and GitHub debug output are disabled before handling private material.

## Commands run / verification

- Local prerequisites: OpenSSL 3.6.3, hdiutil, security, and GitHub CLI are available.
- gh reports authenticated repository administration access for rntgspr/google-chat-deno.
- The repository's Actions secret-name listing was empty before provisioning.
- No application build or test was run.
- The operator's first run created the encrypted private key and certificate but failed during
  PKCS#12 export: identical file arguments for passin and passout made OpenSSL read a nonexistent
  second password line. The export now uses a separate file descriptor for its output password.
- Exporting the existing production identity with the corrected command succeeded and produced
  certificate.p12 in the retained staging directory. No new key or certificate was generated.
- Added --resume for continuing that existing identity through backup and upload. The operator resumed
  /Users/gaspar/workspace/g-deno/crypto/.google-chat-signing.pNWeP7 and reported successful backup and
  all three uploads, followed by the script's successful completion message.
- A fresh gh secret list confirmed MACOS_CERTIFICATE_P12 and MACOS_CERTIFICATE_PASSWORD updated at
  2026-09-13T00:05:34Z, and MACOS_KEYCHAIN_PASSWORD at 2026-09-13T00:05:35Z. Only names and dates were read.
- A fresh directory listing showed only google-chat-deno-signing.dmg in the selected backup directory:
  146944 bytes, mode 600, inside a mode-700 directory. The temporary staging directory was removed.

## Production identity

Public metadata reported by the successful operator run:

| Field | Value |
|-------|-------|
| Repository | rntgspr/google-chat-deno |
| Subject | CN=GoogleChatDeno Release Signing |
| Serial | 4922D26F41A9068692E642B429B9E08CD109DA |
| Valid from | 2026-09-13 00:01:22 UTC |
| Expires | 2036-09-10 00:01:22 UTC |
| SHA256 fingerprint | 03:07:3D:29:F4:F0:93:CB:BB:86:39:8D:9D:08:8A:B3:5A:AD:0D:5D:7B:A7:CC:80:54:EF:0B:32:B7:C9:65:91 |
| Encrypted backup | /Users/gaspar/workspace/g-deno/crypto/google-chat-deno-signing.dmg |

The backup is at the local destination explicitly selected by the operator. An additional offline copy
and separate password retention remain maintainer responsibilities described in scripts/README.md;
no disconnected storage copy was observed or claimed.

## Pending / follow-ups

- T3 can consume the three provisioned secrets and integrate signing in the existing release workflow.
- Runtime import and signing have not been executed in T2; no application build or installation occurred.

## Suggestions for the Lead

Reuse this identity for every official release. Do not regenerate it in T3 or put private values in
plan records. Source backups and recovery instructions remain canonical in scripts/README.md.
