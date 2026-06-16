# AUTARQ Office Release Signing

Release signing is wired through the GitHub environment `release-signing`.
Builds still work without signing secrets; the workflows skip signing when the
required secrets are absent.

## GitHub Environment

Create the environment:

```sh
gh api \
  --method PUT \
  repos/Autarq/DesktopEditors/environments/release-signing
```

Recommended environment settings:

- Restrict write access to maintainers.
- Require manual approval for release branches if the repository is used by
  contributors outside AUTARQ.
- Store signing material only as environment secrets, not repository secrets.

## macOS

Required secrets:

- `MACOS_DEVELOPER_ID_APPLICATION_P12_BASE64`
- `MACOS_DEVELOPER_ID_APPLICATION_CERT_PASSWORD`
- `MACOS_DEVELOPER_ID_APPLICATION_IDENTITY`
- `APPLE_NOTARY_KEY_P8_BASE64`
- `APPLE_NOTARY_KEY_ID`
- `APPLE_NOTARY_ISSUER_ID`

Required external setup:

1. Enroll the AUTARQ Apple Developer account in the Apple Developer Program.
2. Create a `Developer ID Application` certificate for AUTARQ.
3. Export the certificate plus private key from Keychain as `.p12`.
4. Base64 encode the `.p12` without line wrapping and store it in
   `MACOS_DEVELOPER_ID_APPLICATION_P12_BASE64`.
5. Create an App Store Connect API key with notarization access.
6. Base64 encode the `.p8` key and store it in `APPLE_NOTARY_KEY_P8_BASE64`.

The macOS workflow imports the certificate into a temporary keychain, signs the
app with hardened runtime, submits a ZIP to Apple notarization, staples the app,
verifies Gatekeeper with `spctl`, and then publishes the final ZIP artifact.

## Windows

Required secrets:

- `WINDOWS_CODE_SIGNING_PFX_BASE64`
- `WINDOWS_CODE_SIGNING_PFX_PASSWORD`
- `WINDOWS_CODE_SIGNING_CERT_SUBJECT`

Optional environment variable:

- `WINDOWS_TIMESTAMP_SERVER`, default: `http://timestamp.digicert.com`

Required external setup:

1. Buy or issue an AUTARQ organization code-signing certificate from a trusted
   CA, or use a managed cloud signing service.
2. Prefer EV or managed key storage for production releases.
3. If using PFX in GitHub Actions, export the certificate and private key as a
   password-protected `.pfx`.
4. Base64 encode the `.pfx` without line wrapping and store it in
   `WINDOWS_CODE_SIGNING_PFX_BASE64`.
5. Set `WINDOWS_CODE_SIGNING_CERT_SUBJECT` to the subject fragment used by
   `signtool /n`, for example `AUTARQ`.

The Windows workflow imports the PFX into the current-user certificate store
and passes `-Sign` to the existing packaging script. The package script signs
`.exe` and `.dll` files with SHA-256 and an RFC3161 timestamp before creating
the ZIP.

## Linux

Required secrets:

- `LINUX_GPG_PRIVATE_KEY`
- `LINUX_GPG_PASSPHRASE`
- `LINUX_GPG_KEY_ID`

The Linux workflow creates detached GPG signatures for every generated `.deb`
and `.rpm` file. RPM files are additionally signed in-place with `rpmsign`.
It also exports `autarq-office-packaging-key.asc` next to the packages so users
can import the public key.

For production-grade Linux distribution, publish an APT/YUM repository and sign
repository metadata as well. Package signatures are useful, but repository
metadata signatures are what package managers validate by default.

## Homebrew

The cask template lives in:

```text
build/homebrew/Casks/autarq-office.rb
```

Copy it into a public tap repository named `Autarq/homebrew-tap`:

```text
Autarq/homebrew-tap/Casks/autarq-office.rb
```

Users can then install with:

```sh
brew tap Autarq/tap
brew install --cask autarq-office
```

Update the cask `sha256` for every new macOS ZIP release.
