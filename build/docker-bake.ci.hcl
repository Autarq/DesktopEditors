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
}
