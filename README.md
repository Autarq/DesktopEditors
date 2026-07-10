[![License](https://img.shields.io/badge/License-GNU%20AGPL%20V3-green.svg?style=flat)](https://www.gnu.org/licenses/agpl-3.0.en.html)
![Platforms Windows | macOS | Linux](https://img.shields.io/badge/Platforms-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg?style=flat)

## Welcome to AUTARQ Office

[AUTARQ Office](https://github.com/Autarq/DesktopEditors) is a free office suite that combines text, spreadsheet, presentation, PDF, forms, and diagram viewers in one desktop application. It creates, views, and edits local documents on Windows, Linux, and macOS without requiring an Internet connection and supports Office Open XML formats such as `.docx`, `.xlsx`, and `.pptx`.

## Features you'll love ✨

Take advantage of the editors included in AUTARQ Office.

* Document Editor
* Spreadsheet Editor
* Presentation Editor
* Form Creator
* PDF Editor
* Diagram Viewer

The suite empowers you to create, edit, save, and export text documents, spreadsheets, presentations, PDFs, fill out PDF forms, open diagrams, all while offering additional advanced features such as:

* Connection to the cloud (Moodle, Nextcloud, ownCloud, Seafile, Liferay, kDrive) for real-time collaboration ☁️
* Digital signatures ✍️🔏
* Password protection 🔒🔑
* Scalable UI options (including dark mode 🌓)

## Localization 🌐

Constantly improving localization of the editors to make the suite accessible to all users, all over the world.

* Interface available in 46 languages
* RTL support
* Hieroglyph support 🈴

## Plugins 🧩

AUTARQ Office supports plugins that extend the editors without changing the OOXML engine.

## Components 📦

AUTARQ Office contains the following components:

* [desktop-apps](https://github.com/Autarq/desktop-apps) - native desktop shell and start page.
* [desktop-sdk](https://github.com/Autarq/desktop-sdk) - shared desktop SDK.
* [core](https://github.com/Autarq/core) - document conversion and processing components.
* [sdkjs](https://github.com/Autarq/sdkjs) - client-side editor SDK.
* [web-apps](https://github.com/Autarq/web-apps) - document, spreadsheet, presentation, PDF, forms, and diagram editor UI.
* [dictionaries](https://github.com/Autarq/dictionaries) - spellchecking dictionaries.

## Build it yourself 🛠️

You can build AUTARQ Office from source on **Windows**, **Linux**, and **macOS**. This is a
super-repository, so the first step is always to check out the submodules:

```sh
git clone --branch autarq-office https://github.com/Autarq/DesktopEditors.git
cd DesktopEditors
git submodule update --init --recursive
```

Then head to the build docs:

* **[build/](./build/README.md)** — start here for the overall build model (the
  shared CMake definition, the common editors payload, vcpkg, and caching).
* **[build/windows/](./build/windows/README.md)** — the Windows build (`build.ps1`, MSVC + CMake).
* **[build/linux/](./build/linux/README.md)** — the Linux build (Docker / `docker buildx bake`).
* **[build/macos/](./build/macos/README.md)** — the Apple Silicon build (Xcode / `build.sh`).

## Get involved 🤝

Contributions are welcome! Whether it's a bug report, a feature idea, a
translation, or a pull request, here's how to take part:

* **Found a bug or have an idea?** Open an [issue](https://github.com/Autarq/DesktopEditors/issues)
  and describe what you ran into or what you'd like to see.
* **Want to contribute code?** Fork the relevant [component](#components-) repo,
  make your change, and open a pull request. For build changes, see the
  [build docs](./build/README.md) above.
* **Want to help translate?** Localization improvements to the editors'
  interfaces are always appreciated.

Please keep contributions compatible with the project's AGPL v3 license.

## License 📄

AUTARQ Office is licensed under the GNU Affero General Public License, version 3.0. It is based on Euro-Office and ONLYOFFICE; see [ATTRIBUTION](./ATTRIBUTION) for the retained upstream notices.
