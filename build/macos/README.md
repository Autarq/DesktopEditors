# Building AUTARQ Office on macOS

The macOS build runs directly on an Apple Silicon Mac. Xcode builds cannot be
produced inside the Linux Docker setup used by the other platforms.

## Requirements

- Apple Silicon Mac
- Xcode and the Xcode command line tools
- Python 3 and Git
- Qt available through `QT_DIR` or Homebrew `qt@5`
- CMake, Ninja, jq, and ImageMagick
- About 120 GiB of free disk space for a clean local build

Install the Homebrew dependencies with:

```sh
brew install qt@5 cmake ninja jq imagemagick
```

## Build

Clone the integration branch with its pinned AUTARQ submodules:

```sh
git clone --branch autarq-office --recurse-submodules \
  https://github.com/Autarq/DesktopEditors.git
cd DesktopEditors/build
```

Run the preflight first, then build the suite:

```sh
./macos/build.sh --check
MIN_FREE_GIB=120 ./macos/build.sh arm64
```

The output is one suite application:

```text
build/deploy/macos/arm64/AUTARQ Office.app
```

The application is ad-hoc signed for local use when no Developer ID identity is
configured. `build.sh` verifies the executable architecture, bundle metadata,
application icon, and code signature before returning success.

The staging step removes the upstream AI Agent plugins while preserving the
generic plugin runtime and the other bundled plugins.

The pinned `build_tools` revision is patched from reviewable files in
`build/patches/`. The compatibility layer invokes the current Grunt-free
webpack pipeline for `web-apps` and retains Grunt for the native login page.

## Configuration

Common environment overrides:

```sh
QT_DIR=/absolute/path/to/qt
MIN_FREE_GIB=120
EO_SKIP_SPACE_CHECK=1
EO_SKIP_LAUNCH=1
DESKTOP_APPS_DIR=/absolute/path/to/desktop-apps
BUILD_TOOLS_REV=<commit>
CODESIGNING_IDENTITY="Developer ID Application: ..."
DEVELOPMENT_TEAM=<team-id>
```

`DESKTOP_APPS_DIR` is intended for frontend development. Release builds should
use the `desktop-apps` commit pinned by the super-repository.

## Release signing

The GitHub workflow imports the Developer ID certificate only from the
`release-signing` environment and calls `sign-notarize.sh` after the build.
Required certificate and notarization secrets are documented in
[../SIGNING.md](../SIGNING.md).

## Homebrew

The cask template and release update steps are documented in
[../homebrew/README.md](../homebrew/README.md).
