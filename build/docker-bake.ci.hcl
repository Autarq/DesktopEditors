# GitHub hosted runners do not have enough disk for a first build plus
# mode=max local cache exports. Keep the normal local caches for developer
# machines in docker-bake.hcl and disable them in CI.

target "core-base" {
  cache-from = []
  cache-to   = []
}

target "core-wasm" {
  cache-from = []
  cache-to   = []
}

target "desktop-js" {
  cache-from = []
  cache-to   = []
}

target "sdkjs-desktop" {
  cache-from = []
  cache-to   = []
}

target "web-apps" {
  cache-from = []
  cache-to   = []
}

target "desktop-builder" {
  cache-from = []
  cache-to   = []
}

target "desktop-export" {
  cache-from = []
  # GitHub hosted runners can spend hours copying the large desktop tree via
  # BuildKit's local directory exporter. Export one tar stream in CI and unpack
  # it in the workflow; local developer builds still use deploy/desktop.
  output = ["type=tar,dest=./deploy/desktop.tar"]
}
