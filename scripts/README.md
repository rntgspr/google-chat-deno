# macOS signing identity

The [provisioning script](provision_macos_signing_identity.sh) creates the persistent self-signed
Code Signing identity for official GoogleChatDeno.app releases. Run it once on a maintainer's Mac,
outside GitHub Actions. It does not modify the login Keychain, application credentials, or trust settings.

## One-time setup

Requirements: macOS, OpenSSL 3, Git, GitHub CLI authenticated with repository administration access,
and an interactive terminal. The origin must identify rntgspr/google-chat-deno.

Choose a new absolute .dmg path outside every Git repository, in an existing private backup directory.
From this repository, run:

```bash
./scripts/provision_macos_signing_identity.sh /absolute/backup/directory/google-chat-deno-signing.dmg
```

Enter and repeat a backup password of at least 16 characters at the hidden terminal prompts. Store it separately
in your password manager; do not enter it in chat, shell arguments, or repository files. The script
creates a persistent certificate/private key, a password-protected PKCS#12 export, and an encrypted
recovery disk image before it uploads anything to GitHub.

Immediately before upload, the script displays the repository and secret names. Type the exact
repository name when prompted. It refuses to generate another identity if any of these signing secrets
already exists, to avoid an accidental identity replacement.

## GitHub Actions secrets

| Secret | Content |
|--------|---------|
| MACOS_CERTIFICATE_P12 | Base64-encoded PKCS#12 certificate and private key. |
| MACOS_CERTIFICATE_PASSWORD | Random PKCS#12 password. |
| MACOS_KEYCHAIN_PASSWORD | Separate random password for the temporary CI signing Keychain. |

Secret values go to gh through standard input. The backup password is not uploaded. Official releases
reuse this identity; CI must not create a new certificate for each build.

## Backup and recovery

Keep the encrypted disk image and its password recoverable. Maintain an offline copy of the disk image
outside the repository. Losing the private key loses the current signing identity; generating another
certificate with the same name does not recover it.

Open the encrypted disk image through Finder and enter its password to access the recovery material.
It contains certificate.p12, certificate-password.txt, keychain-password.txt, certificate.pem, and
identity.txt. To restore Actions secrets after a failed or partial upload, use that same identity.
With the recovery image mounted at /Volumes/GoogleChatDenoSigning, run the following from an authenticated
terminal with shell tracing disabled:

```bash
set +x
set +v
unset GH_DEBUG
base64 < /Volumes/GoogleChatDenoSigning/certificate.p12 | tr -d '\r\n' | \
  gh secret set MACOS_CERTIFICATE_P12 --repo github.com/rntgspr/google-chat-deno --app actions
tr -d '\r\n' < /Volumes/GoogleChatDenoSigning/certificate-password.txt | \
  gh secret set MACOS_CERTIFICATE_PASSWORD --repo github.com/rntgspr/google-chat-deno --app actions
tr -d '\r\n' < /Volumes/GoogleChatDenoSigning/keychain-password.txt | \
  gh secret set MACOS_KEYCHAIN_PASSWORD --repo github.com/rntgspr/google-chat-deno --app actions
```

Use the actual mount path if macOS selects a different volume name. These commands replace the three
repository secrets with the backed-up identity. Do not regenerate the certificate or print passwords.
Eject the disk image when finished.

When export or backup creation fails, the script preserves its private staging directory and reports only
its location. If the certificate and encrypted private key were already generated, resume them with:

```bash
./scripts/provision_macos_signing_identity.sh /absolute/backup/directory/google-chat-deno-signing.dmg \
  --resume /absolute/backup/directory/.google-chat-signing.EXISTING
```

Use the actual staging path reported by the failed run. Resume keeps the existing certificate, key, and
generated passwords, then repeats export and prompts for the backup password. It never generates a
replacement identity. If key or certificate creation was incomplete, retain staging for manual recovery.
Once the encrypted backup exists, use the mounted-image recovery commands above instead; temporary
material can be cleaned up even if upload fails.

The PKCS#12 export reads its input and output password from separate streams. Reusing the same file
argument for both would make OpenSSL expect two password lines rather than reuse the first one.

The certificate is intended for ten years of use. Record its displayed expiration date; certificate
rotation is a separate maintenance action. This provisioning does not establish Developer ID trust,
notarization, or prove application credential continuity across releases.

## References

- [OpenSSL PKCS#12 export options](https://docs.openssl.org/3.6/man1/openssl-pkcs12/).
- [OpenSSL password-source semantics](https://docs.openssl.org/3.6/man1/openssl-passphrase-options/).
- [GitHub CLI secret upload](https://cli.github.com/manual/gh_secret_set).
- macOS disk-image encryption options: the locally installed hdiutil manual and hdiutil create -help.
