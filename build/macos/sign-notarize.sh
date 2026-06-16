#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-}"
ZIP_PATH="${2:-}"

fail() {
  printf '[macos-sign] ERROR: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is required"
}

[[ -n "${APP_PATH}" ]] || fail "missing app path"
[[ -d "${APP_PATH}" ]] || fail "app does not exist: ${APP_PATH}"

CERT_P12_BASE64="${MACOS_DEVELOPER_ID_APPLICATION_P12_BASE64:-}"
CERT_PASSWORD="${MACOS_DEVELOPER_ID_APPLICATION_CERT_PASSWORD:-}"
SIGNING_IDENTITY="${MACOS_DEVELOPER_ID_APPLICATION_IDENTITY:-}"
NOTARY_KEY_P8_BASE64="${APPLE_NOTARY_KEY_P8_BASE64:-}"
NOTARY_KEY_ID="${APPLE_NOTARY_KEY_ID:-}"
NOTARY_ISSUER_ID="${APPLE_NOTARY_ISSUER_ID:-}"

if [[ -z "${CERT_P12_BASE64}" || -z "${CERT_PASSWORD}" || -z "${SIGNING_IDENTITY}" ]]; then
  printf '[macos-sign] Developer ID certificate secrets are not configured; leaving existing app signature unchanged.\n'
  exit 0
fi

need_cmd base64
need_cmd codesign
need_cmd security
need_cmd ditto
need_cmd xcrun

WORK_DIR="$(mktemp -d "${RUNNER_TEMP:-/tmp}/autarq-macos-sign.XXXXXX")"
KEYCHAIN_PATH="${WORK_DIR}/signing.keychain-db"
KEYCHAIN_PASSWORD="$(uuidgen)"
CERT_PATH="${WORK_DIR}/developer-id-application.p12"
NOTARY_KEY_PATH="${WORK_DIR}/notary-key.p8"

cleanup() {
  security delete-keychain "${KEYCHAIN_PATH}" >/dev/null 2>&1 || true
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

printf '%s' "${CERT_P12_BASE64}" | base64 --decode > "${CERT_PATH}"
security create-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"
security set-keychain-settings -lut 21600 "${KEYCHAIN_PATH}"
security unlock-keychain -p "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"
security import "${CERT_PATH}" -k "${KEYCHAIN_PATH}" -P "${CERT_PASSWORD}" -T /usr/bin/codesign -T /usr/bin/security
security list-keychains -d user -s "${KEYCHAIN_PATH}" $(security list-keychains -d user | tr -d '"')
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${KEYCHAIN_PASSWORD}" "${KEYCHAIN_PATH}"

printf '[macos-sign] Signing %s\n' "${APP_PATH}"
codesign --force --deep --options runtime --timestamp \
  --keychain "${KEYCHAIN_PATH}" \
  --sign "${SIGNING_IDENTITY}" \
  "${APP_PATH}"

codesign --verify --deep --strict --verbose=4 "${APP_PATH}"

if [[ -z "${NOTARY_KEY_P8_BASE64}" || -z "${NOTARY_KEY_ID}" || -z "${NOTARY_ISSUER_ID}" ]]; then
  printf '[macos-sign] Notarization secrets are not configured; skipping notarization.\n'
  exit 0
fi

[[ -n "${ZIP_PATH}" ]] || fail "notarization requires a submission zip path"

printf '%s' "${NOTARY_KEY_P8_BASE64}" | base64 --decode > "${NOTARY_KEY_PATH}"
mkdir -p "$(dirname "${ZIP_PATH}")"
rm -f "${ZIP_PATH}"
ditto -c -k --sequesterRsrc --keepParent "${APP_PATH}" "${ZIP_PATH}"

printf '[macos-sign] Submitting notarization request for %s\n' "${ZIP_PATH}"
xcrun notarytool submit "${ZIP_PATH}" \
  --key "${NOTARY_KEY_PATH}" \
  --key-id "${NOTARY_KEY_ID}" \
  --issuer "${NOTARY_ISSUER_ID}" \
  --wait

printf '[macos-sign] Stapling notarization ticket\n'
xcrun stapler staple "${APP_PATH}"
xcrun stapler validate "${APP_PATH}"
spctl -a -vv -t exec "${APP_PATH}"
