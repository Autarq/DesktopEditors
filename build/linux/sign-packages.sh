#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

OUTPUT_DIR="${OUTPUT_DIR:-${BUILD_DIR}/deploy/linux/packages}"
PRIVATE_KEY="${LINUX_GPG_PRIVATE_KEY:-}"
PASSPHRASE="${LINUX_GPG_PASSPHRASE:-}"
KEY_ID="${LINUX_GPG_KEY_ID:-}"

fail() {
  printf '[linux-sign] ERROR: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is required"
}

if [[ -z "${PRIVATE_KEY}" ]]; then
  printf '[linux-sign] LINUX_GPG_PRIVATE_KEY is not configured; leaving packages unsigned.\n'
  exit 0
fi

need_cmd gpg
need_cmd rpm
need_cmd rpmsign
need_cmd dpkg-sig

mapfile -t debs < <(find "${OUTPUT_DIR}" -maxdepth 1 -type f -name '*.deb' -print | sort)
mapfile -t rpms < <(find "${OUTPUT_DIR}" -maxdepth 1 -type f -name '*.rpm' -print | sort)

[[ "${#debs[@]}" -gt 0 || "${#rpms[@]}" -gt 0 ]] || fail "no deb/rpm packages found in ${OUTPUT_DIR}"

GNUPGHOME="$(mktemp -d "${RUNNER_TEMP:-/tmp}/autarq-linux-gpg.XXXXXX")"
PASSPHRASE_FILE="${GNUPGHOME}/passphrase"
PUBLIC_KEY_PATH="${OUTPUT_DIR}/autarq-office-packaging-key.asc"

cleanup() {
  rm -rf "${GNUPGHOME}"
}
trap cleanup EXIT

chmod 0700 "${GNUPGHOME}"
printf '%s' "${PASSPHRASE}" > "${PASSPHRASE_FILE}"
chmod 0600 "${PASSPHRASE_FILE}"

printf '%s' "${PRIVATE_KEY}" | gpg --batch --homedir "${GNUPGHOME}" --import

if [[ -z "${KEY_ID}" ]]; then
  KEY_ID="$(gpg --batch --homedir "${GNUPGHOME}" --with-colons --list-secret-keys | awk -F: '/^sec:/ { print $5; exit }')"
fi
[[ -n "${KEY_ID}" ]] || fail "could not resolve GPG signing key id"

gpg --batch --homedir "${GNUPGHOME}" --armor --export "${KEY_ID}" > "${PUBLIC_KEY_PATH}"

if [[ "${#debs[@]}" -gt 0 ]]; then
  printf '[linux-sign] Signing deb packages with key %s\n' "${KEY_ID}"
  for deb in "${debs[@]}"; do
    dpkg-sig \
      --gpg-options "--batch --pinentry-mode loopback --passphrase-file ${PASSPHRASE_FILE}" \
      -k "${KEY_ID}" \
      --sign builder \
      "${deb}"
    dpkg-sig --verify "${deb}"
  done
fi

if [[ "${#rpms[@]}" -gt 0 ]]; then
  printf '[linux-sign] Signing rpm packages with key %s\n' "${KEY_ID}"
  cat > "${GNUPGHOME}/rpmmacros" <<EOF
%_signature gpg
%_gpg_name ${KEY_ID}
%_gpg_path ${GNUPGHOME}
%__gpg /usr/bin/gpg
%__gpg_sign_cmd %{__gpg} --batch --no-verbose --no-armor --pinentry-mode loopback --passphrase-file ${PASSPHRASE_FILE} --local-user "%{_gpg_name}" -sbo %{__signature_filename} %{__plaintext_filename}
EOF
  export HOME="${GNUPGHOME}"
  for rpm_package in "${rpms[@]}"; do
    rpmsign --addsign "${rpm_package}"
    rpm --checksig "${rpm_package}"
  done
fi

printf '[linux-sign] Exported public key: %s\n' "${PUBLIC_KEY_PATH}"
