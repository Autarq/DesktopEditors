#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="$(cd "${BUILD_DIR}/.." && pwd)"

PRODUCT_VERSION="${PRODUCT_VERSION:-9.3.1}"
PACKAGE_ITERATION="${PACKAGE_ITERATION:-1}"
PACKAGE_NAME="${PACKAGE_NAME:-autarq-office}"
PRODUCT_NAME="${PRODUCT_NAME:-AUTARQ Office}"
MAINTAINER="${MAINTAINER:-AUTARQ <office@autarq.com>}"
INPUT_DIR="${INPUT_DIR:-${BUILD_DIR}/deploy/desktop}"
OUTPUT_DIR="${OUTPUT_DIR:-${BUILD_DIR}/deploy/linux/packages}"
WORK_DIR="${WORK_DIR:-${BUILD_DIR}/deploy/linux/pkgroot}"
INSTALL_DIR="/opt/autarq-office"

usage() {
  cat <<EOF
Usage: ./linux/package.sh [deb|rpm|all]

Packages the existing Linux desktop export from:
  ${INPUT_DIR}

Outputs packages to:
  ${OUTPUT_DIR}

Run the Linux build first:
  cd ${BUILD_DIR}
  docker buildx bake
EOF
}

fail() {
  printf '[linux-package] ERROR: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is required"
}

package_type="${1:-all}"
case "${package_type}" in
  deb|rpm|all|--help|-h) ;;
  *) usage; fail "unknown package type: ${package_type}" ;;
esac
if [[ "${package_type}" == "--help" || "${package_type}" == "-h" ]]; then
  usage
  exit 0
fi

need_cmd fpm

[[ -d "${INPUT_DIR}" ]] || fail "missing Linux desktop export: ${INPUT_DIR}"
[[ -x "${INPUT_DIR}/DesktopEditors" ]] || fail "missing executable: ${INPUT_DIR}/DesktopEditors"
[[ -f "${INPUT_DIR}/start_desktop.sh" ]] || fail "missing launcher: ${INPUT_DIR}/start_desktop.sh"

rm -rf "${WORK_DIR}" "${OUTPUT_DIR}"
mkdir -p "${WORK_DIR}${INSTALL_DIR}" \
  "${WORK_DIR}/usr/bin" \
  "${WORK_DIR}/usr/share/applications" \
  "${OUTPUT_DIR}"

cp -a "${INPUT_DIR}/." "${WORK_DIR}${INSTALL_DIR}/"

cat > "${WORK_DIR}/usr/bin/autarq-office" <<'EOF'
#!/usr/bin/env sh
cd /opt/autarq-office
exec ./start_desktop.sh "$@"
EOF
chmod 0755 "${WORK_DIR}/usr/bin/autarq-office"

cat > "${WORK_DIR}/usr/share/applications/autarq-office.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${PRODUCT_NAME}
Comment=Desktop editors for documents, spreadsheets, presentations and PDFs
Exec=autarq-office %U
Icon=autarq-office
Terminal=false
Categories=Office;WordProcessor;Spreadsheet;Presentation;
MimeType=application/vnd.openxmlformats-officedocument.wordprocessingml.document;application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;application/vnd.openxmlformats-officedocument.presentationml.presentation;application/pdf;
EOF

for icon in "${REPO_DIR}"/desktop-apps/package/common/linux/icons/*.png; do
  [[ -f "${icon}" ]] || continue
  size="$(basename "${icon}" .png)"
  mkdir -p "${WORK_DIR}/usr/share/icons/hicolor/${size}x${size}/apps"
  cp "${icon}" "${WORK_DIR}/usr/share/icons/hicolor/${size}x${size}/apps/autarq-office.png"
done

build_one() {
  local type="$1"
  local depends=()
  if [[ "${type}" == "deb" ]]; then
    depends=(
      --depends "x11-common"
      --depends "libasound2"
      --depends "curl | wget"
      --depends "desktop-file-utils"
      --depends "libxss1"
      --depends "libgtk-3-0"
      --depends "libxkbcommon-x11-0"
      --depends "xdg-utils"
    )
  else
    depends=(
      --depends "curl"
      --depends "libX11"
      --depends "gtk3"
      --depends "libXScrnSaver"
      --depends "libxkbcommon-x11"
      --depends "xdg-utils"
    )
  fi

  fpm \
    -s dir \
    -t "${type}" \
    -C "${WORK_DIR}" \
    -n "${PACKAGE_NAME}" \
    -v "${PRODUCT_VERSION}" \
    --iteration "${PACKAGE_ITERATION}" \
    --license "AGPL-3.0" \
    --maintainer "${MAINTAINER}" \
    --description "${PRODUCT_NAME} desktop editor suite" \
    --url "https://github.com/Autarq/DesktopEditors" \
    --architecture native \
    --package "${OUTPUT_DIR}" \
    "${depends[@]}" \
    .
}

if [[ "${package_type}" == "all" ]]; then
  build_one deb
  build_one rpm
else
  build_one "${package_type}"
fi

find "${OUTPUT_DIR}" -maxdepth 1 -type f -print
