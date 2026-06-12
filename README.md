[![License](https://img.shields.io/badge/License-GNU%20AGPL%20V3-green.svg?style=flat)](https://www.gnu.org/licenses/agpl-3.0.en.html)
![Platforms Windows | macOS | Linux](https://img.shields.io/badge/Platforms-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg?style=flat)

## Welcome to the AUTARQ Office Desktop Editors repo!

[AUTARQ Office Desktop Editors](https://github.com/Autarq/DesktopEditors) is a free office suite that combines text, spreadsheet, presentation, PDF, and diagram editing in one desktop app. The application allows creating, viewing and editing documents stored on your Windows/Linux PC or Mac without an Internet connection. It is fully compatible with Office Open XML formats: .docx, .xlsx, .pptx.

## Features you'll love ✨

Take advantage of the powerful editors included in Desktop Editors.

* Document Editor
* Spreadsheet Editor
* Presentation Editor
* Form Creator
* PDF Editor
* Diagram Viewer

The suite empowers you to create, edit, save, and export text documents, spreadsheets, presentations, PDFs, fill out PDF forms, open diagrams, all while offering additional advanced features such as:

* Connection to the cloud (Moodle, Nextcloud, ownCloud, Seafile, Liferay, kDrive) for real-time collaboration ☁️
* AI-powered assistants 🤖
* Digital signatures ✍️🔏
* Password protection 🔒🔑
* Scalable UI options (including dark mode 🌓)

## Localization 🌐

 Constantly improving localization of the editors to make the suite accessible to all users, all over the world.

* Interface available in 46 languages
* RTL support
* Hieroglyph support 🈴

## Plugins 🧩

Desktop Editors offer support for plugins allowing developers to add specific features to the editors that are not directly related to the OOXML format.

## Components 📦

Desktop Editors contain the following components:

* [desktop-apps](desktop-apps) - the frontend for Desktop Editors which is used to build the program interface for the operating system selected.
* [desktop-sdk](desktop-sdk) - SDK which is a core part of Desktop Editors.
* [core](core) - server core components for [Document Server][1] which is a part of Desktop Editors and is used to enable the conversion between the most popular office document formats (DOC, DOCX, ODT, RTF, TXT, PDF, HTML, EPUB, XPS, DjVu, XLS, XLSX, ODS, CSV, PPT, PPTX, ODP).
* [sdkjs](sdkjs) - JavaScript SDK for the [Document Server][1] which is a part of Desktop Editors and contains API for all the included components client-side interaction.
* [web-apps](web-apps) - the frontend for [Document Server][1] which is a part of Desktop Editors that allows the user to create, edit, save and export text, spreadsheet and presentation documents using the common interface of a document editor.
* [dictionaries](dictionaries) - the dictionaries of various languages used for spellchecking in Desktop Editors.

## Build AUTARQ Office macOS apps

The AUTARQ macOS build is orchestrated from `DesktopEditors/build`, next to the
existing Linux build entrypoint. On Apple Silicon it produces one suite app:

* `AUTARQ Office.app`

### Requirements

* Apple Silicon Mac
* Xcode installed and selected with `xcode-select`
* Git and Python 3
* Qt 5, for example Homebrew `qt@5`
* At least 120 GiB free disk space for native dependencies and build output

### Build steps

Clone the AUTARQ GitHub fork with submodules:

```sh
mkdir -p ~/Dev/autarq-office-desktop
cd ~/Dev/autarq-office-desktop

git clone \
  --branch autarq-office \
  https://github.com/Autarq/DesktopEditors.git

cd DesktopEditors
git submodule sync --recursive
git submodule update --init --recursive
```

Run the macOS preflight and build:

```sh
cd build
./macos/build.sh --check
MIN_FREE_GIB=120 ./macos/build.sh arm64
```

The apps are written to:

```text
DesktopEditors/build/deploy/macos/arm64/AUTARQ Office.app
```

The macOS exporter also installs the pinned ONLYOFFICE draw.io plugin into the
suite bundle.

It also preconfigures the bundled AI agent with the AUTARQ OpenAI-compatible
endpoint. For private local builds, pass `AUTARQ_AI_API_KEY` to embed a key into
the generated `.app`; leave it unset for commits and shared source builds.

For local `desktop-apps` development, keep a sibling checkout and point the
build at it:

```sh
DESKTOP_APPS_DIR=~/Dev/autarq-office-desktop/desktop-apps \
  MIN_FREE_GIB=120 ./macos/build.sh arm64
```

Without a Developer ID identity the apps are ad-hoc signed and suitable for
local testing. Release signing and notarization require the usual Developer ID
and notarization credentials.

More details and troubleshooting notes live in [`build/README.md`](build/README.md).

## License 📄

Desktop Editors is licensed under the GNU Affero Public License, version 3.0,
with upstream legal notices retained. AUTARQ Office is a public fork of
Euro-Office/ONLYOFFICE Desktop Editors; see [`NOTICE-AUTARQ.md`](NOTICE-AUTARQ.md)
and the license files in each submodule before redistributing binaries.

  [1]: https://github.com/Autarq/DocumentServer
