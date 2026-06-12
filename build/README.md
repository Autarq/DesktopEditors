# AUTARQ Office Desktop Editors Builds

This directory contains the reproducible build entrypoints for AUTARQ Office
Desktop Editors.

## Clone

Clone the repository with submodules:

```sh
git clone --branch autarq-office --recurse-submodules https://github.com/Autarq/DesktopEditors.git
```

If the repository was cloned without submodules, initialize them before building:

```sh
git submodule update --init --recursive
```

## AUTARQ GitHub Quick Start

The AUTARQ desktop repositories are public forks in the GitHub organization:

```text
https://github.com/Autarq
```

For Apple Silicon development, clone the AUTARQ Office branch directly and then
initialize submodules from the branch-local `.gitmodules` file:

```sh
mkdir -p ~/Dev/autarq-office-desktop
cd ~/Dev/autarq-office-desktop

git clone \
  --branch autarq-office \
  https://github.com/Autarq/DesktopEditors.git

cd DesktopEditors
git submodule sync --recursive
git submodule update --init --recursive

cd build
./macos/build.sh --check
MIN_FREE_GIB=120 ./macos/build.sh arm64
```

The branch pins all desktop build submodules to matching public `Autarq/*`
forks:

```text
https://github.com/Autarq/desktop-apps.git
https://github.com/Autarq/desktop-sdk.git
https://github.com/Autarq/core.git
https://github.com/Autarq/sdkjs.git
https://github.com/Autarq/web-apps.git
```

Developers can still override the app checkout explicitly while testing local
changes:

```sh
DESKTOP_APPS_DIR=~/Dev/autarq-office-desktop/desktop-apps ./macos/build.sh arm64
```

## Linux

Linux builds continue to use Docker Buildx Bake:

```sh
cd DesktopEditors/build
docker buildx bake --allow=fs=/tmp --allow=fs.read=..
```

The exported desktop build is written to:

```text
DesktopEditors/build/deploy/desktop
```

To create Linux packages from that export, install `fpm` and run:

```sh
cd DesktopEditors/build
./linux/package.sh all
```

The package output is written to:

```text
DesktopEditors/build/deploy/linux/packages
```

## macOS

macOS builds must run on a macOS host with Xcode installed. Xcode application
builds are not wrapped in Docker; the host build entrypoint lives next to the
Linux bake file:

```sh
cd DesktopEditors/build
./macos/build.sh --check
./macos/build.sh arm64
```

For a fresh Apple Silicon machine, use this full flow:

```sh
mkdir -p ~/Dev/autarq-office-desktop
cd ~/Dev/autarq-office-desktop

git clone \
  --branch autarq-office \
  https://github.com/Autarq/DesktopEditors.git

cd DesktopEditors
git submodule sync --recursive
git submodule update --init --recursive

cd build
./macos/build.sh --check
MIN_FREE_GIB=120 ./macos/build.sh arm64
```

The default macOS output is one AUTARQ-branded suite app:

```text
DesktopEditors/build/deploy/macos/arm64/AUTARQ Office.app
```

The macOS build currently targets Apple Silicon first. Intel and universal
builds can be added later using the same `build/macos` layout.

## Windows

Windows x64 builds use the pinned `build_tools` checkout to create a native
payload under `build_tools/out/win_64/AUTARQ/DesktopEditors`, then package it
with the upstream PowerShell scripts under `desktop-apps/package`.

```powershell
cd DesktopEditors
.\build\windows\build.ps1 -Arch x64 -QtRoot C:/Qt/5.15.2
.\build\windows\package.ps1 -Arch x64
```

Expected native payload path:

```text
DesktopEditors\build_tools\out\win_64\AUTARQ\DesktopEditors
```

The package wrapper still supports prebuilt payloads. That keeps release runs
explicit when packaging is repeated on a workspace where the native payload was
already created.

## GitHub Actions

The AUTARQ fork includes three build workflows:

- `macOS ARM64`: preflight on PR/push and a manual full Apple Silicon app build.
- `Linux Packages`: Docker Buildx Bake plus `.deb` and `.rpm` packaging.
- `Windows Package`: validates the Windows build/package wrappers on PR/push,
  and on manual dispatch builds the hosted x64 payload plus ZIP package by
  default.

The Windows workflow has two manual modes:

- `full_build=true` builds the x64 payload from source on the hosted runner,
  then packages it.
- `package_prebuilt_payload=true` skips compilation and packages an existing
  `build_tools/out/win_64/AUTARQ/DesktopEditors` payload.

GitHub-hosted macOS ARM runners currently have much less free disk space than a
local release build machine. The hosted workflow keeps the preflight threshold
low enough to validate Xcode, Qt and script wiring. Full release builds should
run on an Apple Silicon runner with roughly 120 GiB free disk space.

### macOS Requirements

- macOS on Apple Silicon
- Xcode command line tools selected with `xcode-select`
- Python 3
- Git
- Qt available through `QT_DIR` or a Homebrew Qt install
- Enough free space for native dependencies and the Xcode build

Optional release tooling:

- `gh` for PR and release workflows
- Developer ID signing identity for distributable builds
- notarization credentials for a future signed release flow

### macOS Environment

The script has conservative defaults and can be tuned with environment
variables:

```sh
MIN_FREE_GIB=150                 # minimum free disk space check
EO_SKIP_SPACE_CHECK=1            # bypass the free-space guard
QT_DIR=/path/to/qt-root          # contains <version>/macos/bin/qmake or <version>/clang_64/bin/qmake
DESKTOP_APPS_DIR=/path/to/desktop-apps
EO_MACOS_PRODUCTS=suite          # default suite app; split/all/comma list are developer overrides
DRAWIO_PLUGIN_ARCHIVE=/path/to/drawio.plugin
AUTARQ_AI_BASE_URL=https://llm.autarq.now/v1/
AUTARQ_AI_PROVIDER_NAME="AUTARQ Office AI"
AUTARQ_AI_API_KEY=<optional local key>
AUTARQ_AI_MODEL=<optional default model id>
BUILD_TOOLS_REV=<commit>         # ONLYOFFICE/build_tools revision
CODESIGNING_IDENTITY="Developer ID Application: ..."
DEVELOPMENT_TEAM=<team-id>
EO_SKIP_LAUNCH=1                 # skip the local launch smoke test
```

The exporter installs the upstream ONLYOFFICE draw.io plugin into the staged
suite bundle. By default the plugin archive is downloaded once into
`build/deploy/macos/tools/drawio` and verified by SHA-256; set
`DRAWIO_PLUGIN_ARCHIVE` to use a locally cached archive.

The exporter also preconfigures the bundled AI agent plugin with the AUTARQ
OpenAI-compatible endpoint. Leave `AUTARQ_AI_API_KEY` unset for source builds;
set it only for a local/private build where embedding the key into the resulting
`.app` bundle is acceptable. The key is never written to tracked files.

If `QT_DIR` points at a root directory and Homebrew Qt is available, the script
creates a build-tools compatible layout such as `<QT_DIR>/5.15.18/macos`.

`DESKTOP_APPS_DIR` is optional. It is useful while the matching `desktop-apps`
macOS branding branch is still under review; after that branch is merged,
`DesktopEditors` can point its `desktop-apps` submodule at the upstream commit.
Upstream `build_tools` still reads `desktop-apps/common/loginpage` from the
`DesktopEditors` repo root, so the wrapper temporarily links the external
checkout into that submodule path during the build and restores the empty path
on exit. Xcode build phases also resolve `../../build_tools`, `../../core`,
`../../desktop-sdk`, and the dictionaries folder from the `desktop-apps/macos`
checkout, so the wrapper temporarily links those sibling paths under
`<desktop-apps-parent>` back to the matching `DesktopEditors` directories while
using an external checkout.

Without a Developer ID identity the app build is ad-hoc signed and suitable for
local testing. Release DMG signing and notarization remain gated on Developer ID
and notarization credentials.

Some upstream `build_tools` steps still call `python`. When macOS only provides
`python3`, `build/macos/build.sh` adds a local `python` shim under
`build/deploy/macos/tools/bin` for the duration of the build.

The JavaScript build steps call `grunt` directly after `npm install`. The macOS
wrapper adds a local `grunt` shim under `build/deploy/macos/tools/bin` that
executes the `node_modules/.bin/grunt` from the current project directory,
avoiding any global npm dependency. `build_tools` sets `NODE_ENV=production`
before those installs, so the wrapper also sets `NPM_CONFIG_INCLUDE=dev`; this
keeps npm 10+ from omitting Gruntfile helper packages such as `time-grunt`.

The HEIF dependency path in `build_tools` currently requires CMake `>= 3.21`
and `< 4`. If the host only has CMake 4 or no CMake, the script creates a
temporary local CMake venv under `build/deploy/macos/tools/cmake-venv`.

The macOS wrapper also exports fetched `katana-parser/src`, `gumbo-parser/src`,
`hyphen`, and `hunspell/hunspell/src` include paths for the qmake build, which
otherwise cannot resolve headers such as `katana.h`, `gumbo.h`,
`hyphen/hnjalloc.h`, and `hunspell/hunspell.h`.

If a previous run left an incomplete Boost output under
`core/Common/3dParty/boost/build/mac_arm64`, the wrapper removes that generated
directory before calling `build_tools` so `libboost_filesystem.a`,
`libboost_date_time.a`, and `libboost_regex.a` are rebuilt.

For current Xcode/Clang compatibility with the pinned Boost 1.72 headers, the
wrapper also patches the local Boost.DateTime `hours`, `minutes`, and `seconds`
helper constructors that otherwise instantiate Boost numeric conversion paths
rejected by current Clang.

For current Xcode/Clang compatibility with the pinned Boost 1.72 and iWork
sources, the wrapper prefetches the generated iWork third-party sources and
patches a small set of `libetonyek` `numeric_cast<int>` and
`numeric_cast<unsigned>` calls that otherwise trip Boost MPL enum constant
evaluation.

The same compatibility pass patches the ODF table border width casts used by
the PPTX and XLSX converters from `boost::lexical_cast<int>` to a direct cast,
avoiding another Boost numeric conversion instantiation rejected by current
Clang.

### macOS Verification

`build/macos/build.sh arm64` verifies the generated application by checking the
main executable architecture and running strict codesign verification. Unless
`EO_SKIP_LAUNCH=1` is set, it also opens the app once as a local launch smoke
test.
