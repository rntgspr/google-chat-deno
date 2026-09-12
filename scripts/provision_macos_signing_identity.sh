#!/bin/bash
set +x
set +v
set +a
set -euo pipefail
umask 077
unset GH_DEBUG backup_password backup_password_confirmation

SIGNING_REPOSITORY="rntgspr/google-chat-deno"
SIGNING_NAME="GoogleChatDeno Release Signing"
SIGNING_SECRETS=(MACOS_CERTIFICATE_P12 MACOS_CERTIFICATE_PASSWORD MACOS_KEYCHAIN_PASSWORD)
signing_staging=""
signing_backup=""
identity_started=false
backup_committed=false

# Report an operational failure without exposing signing material.
fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

# Remove staging only when no identity exists or its encrypted backup is committed.
cleanup() {
  local exit_status=$?
  trap - EXIT
  unset backup_password backup_password_confirmation

  if [[ -n "$signing_staging" && -d "$signing_staging" ]]; then
    if [[ "$backup_committed" == true || "$identity_started" == false ]]; then
      if ! rm -rf -- "$signing_staging"; then
        printf 'Could not remove private staging: %s\n' "$signing_staging" >&2
        exit_status=1
      fi
    else
      printf 'Recovery material retained in private staging: %s\n' "$signing_staging" >&2
      printf 'Recover this identity; do not generate a replacement. See scripts/README.md.\n' >&2
    fi
  fi

  if [[ "$backup_committed" == true && "$exit_status" != 0 ]]; then
    printf 'Recover or finish uploading the same identity from: %s\n' "$signing_backup" >&2
  fi

  exit "$exit_status"
}

# Refuse an existing Actions signing secret instead of rotating an established identity.
require_empty_signing_secrets() {
  local existing secret
  existing=$(gh secret list --repo "github.com/$SIGNING_REPOSITORY" --app actions --json name --jq '.[].name')

  for secret in "${SIGNING_SECRETS[@]}"; do
    if [[ $'\n'"$existing"$'\n' == *$'\n'"$secret"$'\n'* ]]; then
      fail "$secret already exists. Recover the original identity; this script does not rotate it."
    fi
  done
}

# Provision one identity, commit an encrypted recovery image, and upload Actions secrets.
main() {
  local resume_staging=""
  if [[ $# == 3 && "$2" == --resume ]]; then
    resume_staging=$3
  elif [[ $# != 1 ]]; then
    fail 'Usage: scripts/provision_macos_signing_identity.sh /absolute/backup.dmg [--resume /absolute/staging-directory]'
  fi
  [[ "$(uname -s)" == Darwin ]] || fail 'Run this script on macOS.'

  local tool openssl_bin script_directory repository_root origin backup_parent path_part
  local repository_details existing_staging confirmation recovery_file
  for tool in git gh hdiutil mktemp chmod base64 tr; do
    command -v "$tool" >/dev/null || fail "Required tool missing: $tool"
  done

  openssl_bin=$(command -v openssl) || fail 'OpenSSL 3 is required.'
  if [[ -x /opt/homebrew/bin/openssl ]]; then
    openssl_bin=/opt/homebrew/bin/openssl
  fi
  [[ "$("$openssl_bin" version)" == 'OpenSSL 3.'* ]] || fail 'OpenSSL 3 is required; install it before provisioning.'

  script_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
  repository_root=$(git -C "$script_directory" rev-parse --show-toplevel)
  origin=$(git -C "$repository_root" remote get-url origin)
  case "$origin" in
    https://github.com/rntgspr/google-chat-deno|https://github.com/rntgspr/google-chat-deno.git|git@github.com:rntgspr/google-chat-deno|git@github.com:rntgspr/google-chat-deno.git|ssh://git@github.com/rntgspr/google-chat-deno|ssh://git@github.com/rntgspr/google-chat-deno.git) ;;
    *) fail 'The origin remote must identify github.com/rntgspr/google-chat-deno exactly.' ;;
  esac

  repository_details=$(gh api --hostname github.com "repos/$SIGNING_REPOSITORY" --jq '[.full_name, (.permissions.admin | tostring)] | join(" ")')
  [[ "$repository_details" == "$SIGNING_REPOSITORY true" ]] || fail 'Authenticated GitHub administrator access to the intended repository is required.'
  require_empty_signing_secrets

  signing_backup=$1
  [[ "$signing_backup" == /*.dmg ]] || fail 'Choose an absolute backup filename ending in .dmg.'
  case "$signing_backup" in
    *$'\n'*|*'/../'*|*'/./'*|*'//'*) fail 'The backup path must not contain newlines, relative segments, or repeated slashes.' ;;
  esac
  path_part=$signing_backup
  while [[ "$path_part" != / ]]; do
    [[ ! -L "$path_part" ]] || fail 'Symlinks are not allowed in the backup path.'
    path_part=$(dirname -- "$path_part")
  done

  backup_parent=$(dirname -- "$signing_backup")
  [[ -d "$backup_parent" && -w "$backup_parent" ]] || fail 'The backup parent directory must already exist and be writable.'
  [[ ! -e "$signing_backup" ]] || fail 'The backup already exists. Recover that identity instead of generating another.'
  if git -C "$backup_parent" rev-parse --show-toplevel >/dev/null 2>&1; then
    fail 'The backup directory must be outside every Git working tree.'
  fi

  for existing_staging in "$backup_parent"/.google-chat-signing.*; do
    [[ ! -e "$existing_staging" || "$existing_staging" == "$resume_staging" ]] || fail "Recover existing signing staging with --resume: $existing_staging"
  done

  if [[ -n "$resume_staging" ]]; then
    [[ "$(dirname -- "$resume_staging")" == "$backup_parent" && "$(basename -- "$resume_staging")" == .google-chat-signing.* ]] || fail 'Resume staging must be an existing signing directory beside the requested backup.'
    [[ -d "$resume_staging" && ! -L "$resume_staging" && -O "$resume_staging" ]] || fail 'Resume staging must be a real directory owned by the current user.'
    [[ -d "$resume_staging/recovery" && ! -L "$resume_staging/recovery" ]] || fail 'The recovery directory must not be a symlink.'
    for recovery_file in private-key.pem recovery/certificate.pem recovery/certificate-password.txt recovery/keychain-password.txt; do
      [[ -f "$resume_staging/$recovery_file" && -s "$resume_staging/$recovery_file" && ! -L "$resume_staging/$recovery_file" ]] || fail "Required recovery file missing or unsafe: $recovery_file"
    done
  fi

  exec 3<>/dev/tty || fail 'An interactive terminal is required for the backup password and upload confirmation.'
  printf 'Store the backup password separately in your password manager.\n' >&3
  printf 'Backup password (at least 16 characters): ' >&3
  IFS= read -r -s backup_password <&3 || fail 'Backup password input was interrupted.'
  printf '\nRepeat backup password: ' >&3
  IFS= read -r -s backup_password_confirmation <&3 || fail 'Backup password confirmation was interrupted.'
  printf '\n' >&3
  [[ ${#backup_password} -ge 16 ]] || fail 'Use a backup password of at least 16 characters.'
  [[ "$backup_password" == "$backup_password_confirmation" ]] || fail 'Backup passwords do not match.'
  unset backup_password_confirmation

  if [[ -n "$resume_staging" ]]; then
    identity_started=true
    signing_staging=$resume_staging
    printf 'Resuming the existing certificate and private key from: %s\n' "$signing_staging"
  else
    signing_staging=$(mktemp -d "$backup_parent/.google-chat-signing.XXXXXX")
    chmod 700 "$signing_staging"
    mkdir -m 700 "$signing_staging/recovery"
    "$openssl_bin" rand -hex 32 > "$signing_staging/recovery/certificate-password.txt"
    "$openssl_bin" rand -hex 32 > "$signing_staging/recovery/keychain-password.txt"

    identity_started=true
    "$openssl_bin" genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -aes-256-cbc \
      -pass "file:$signing_staging/recovery/certificate-password.txt" \
      -out "$signing_staging/private-key.pem" 2> "$signing_staging/key-generation.log"
    "$openssl_bin" req -new -x509 -sha256 -days 3650 -batch -config /dev/null \
      -key "$signing_staging/private-key.pem" \
      -passin "file:$signing_staging/recovery/certificate-password.txt" \
      -subj "/CN=$SIGNING_NAME" -addext 'basicConstraints=critical,CA:FALSE' \
      -addext 'keyUsage=critical,digitalSignature' -addext 'extendedKeyUsage=critical,codeSigning' \
      -out "$signing_staging/recovery/certificate.pem"
  fi

  # Explicit PKCS#12 algorithms avoid OpenSSL 3 defaults unsupported by older macOS importers.
  "$openssl_bin" pkcs12 -export -name "$SIGNING_NAME" \
    -inkey "$signing_staging/private-key.pem" -in "$signing_staging/recovery/certificate.pem" \
    -passin "file:$signing_staging/recovery/certificate-password.txt" \
    -passout fd:4 \
    -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1 -iter 100000 \
    -out "$signing_staging/recovery/certificate.p12" \
    4< "$signing_staging/recovery/certificate-password.txt"

  {
    printf 'Repository: %s\nIdentity: %s\n' "$SIGNING_REPOSITORY" "$SIGNING_NAME"
    printf 'Reuse this identity for every official release. Never regenerate it in CI.\n'
    "$openssl_bin" x509 -in "$signing_staging/recovery/certificate.pem" \
      -noout -subject -serial -dates -fingerprint -sha256
  } > "$signing_staging/recovery/identity.txt"

  printf '%s\0' "$backup_password" | hdiutil create \
    -srcfolder "$signing_staging/recovery" -volname GoogleChatDenoSigning \
    -format UDZO -encryption AES-256 -stdinpass -quiet "$signing_backup"
  unset backup_password
  [[ -f "$signing_backup" && ! -L "$signing_backup" && -s "$signing_backup" ]] || fail 'Encrypted backup creation did not produce the expected file.'
  chmod 600 "$signing_backup"
  backup_committed=true
  printf 'Encrypted recovery backup created: %s\n' "$signing_backup"

  require_empty_signing_secrets
  printf '\nRepository: github.com/%s\nActions secrets:\n' "$SIGNING_REPOSITORY" >&3
  printf '  %s\n' "${SIGNING_SECRETS[@]}" >&3
  printf 'Type %s to upload these secrets: ' "$SIGNING_REPOSITORY" >&3
  IFS= read -r confirmation <&3 || fail 'Upload confirmation was interrupted.'
  [[ "$confirmation" == "$SIGNING_REPOSITORY" ]] || fail 'Upload cancelled; keep the encrypted backup for recovery.'

  base64 < "$signing_staging/recovery/certificate.p12" | tr -d '\r\n' | \
    gh secret set MACOS_CERTIFICATE_P12 --repo "github.com/$SIGNING_REPOSITORY" --app actions
  tr -d '\r\n' < "$signing_staging/recovery/certificate-password.txt" | \
    gh secret set MACOS_CERTIFICATE_PASSWORD --repo "github.com/$SIGNING_REPOSITORY" --app actions
  tr -d '\r\n' < "$signing_staging/recovery/keychain-password.txt" | \
    gh secret set MACOS_KEYCHAIN_PASSWORD --repo "github.com/$SIGNING_REPOSITORY" --app actions

  cat "$signing_staging/recovery/identity.txt"
  printf 'Signing secrets provisioned for %s. Keep the backup offline and its password separately.\n' "$SIGNING_REPOSITORY"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
main "$@"
