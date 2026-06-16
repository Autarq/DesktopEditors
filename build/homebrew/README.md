# AUTARQ Office Homebrew Cask

This directory contains the cask that should be copied to the AUTARQ Homebrew
tap repository:

```text
Autarq/homebrew-tap
└── Casks
    └── autarq-office.rb
```

After the tap exists, users can install the macOS build with:

```sh
brew tap Autarq/tap
brew install --cask autarq-office
```

For a new release:

1. Build and publish the macOS ZIP through the `macOS ARM64` workflow.
2. Update `version`, `sha256`, and `url` in `Casks/autarq-office.rb`.
3. Run:

```sh
brew audit --cask --online autarq-office
brew install --cask --verbose ./Casks/autarq-office.rb
```

The current cask points to the first `beta-1` ARM64 build. Once Developer ID
notarization is enabled, update the cask to the notarized ZIP artifact.
