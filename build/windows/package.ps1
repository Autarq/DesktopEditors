param (
    [System.Version]$Version = "9.3.1.0",
    [ValidateSet("x64", "x86", "arm64")]
    [string]$Arch = "x64",
    [string]$SourceDir,
    [string]$BuildDir,
    [switch]$Installer,
    [switch]$Sign,
    [string]$CertName = "AUTARQ",
    [string]$TimestampServer = "http://timestamp.digicert.com"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildRoot = Resolve-Path (Join-Path $ScriptDir "..")
$RepoRoot = Resolve-Path (Join-Path $BuildRoot "..")
$PackageDir = Join-Path $RepoRoot "desktop-apps\package"

if (-not $SourceDir) {
    $BuildPrefix = switch ($Arch) {
        "x64" { "win_64" }
        "x86" { "win_32" }
        "arm64" { "win_arm64" }
    }
    $SourceDir = Join-Path $RepoRoot "build_tools\out\$BuildPrefix\AUTARQ\DesktopEditors"
}

if (-not (Test-Path $SourceDir)) {
    throw @"
Missing native Windows build output:
  $SourceDir

Build the Windows desktop payload first with the pinned build_tools workflow,
then rerun this packaging wrapper. The wrapper intentionally does not download
or mutate build_tools itself.
"@
}

if (-not $BuildDir) {
    $BuildDir = Join-Path $BuildRoot "deploy\windows\$Arch"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $BuildDir) | Out-Null

Push-Location $PackageDir
try {
    & .\make.ps1 `
        -Version $Version `
        -Arch $Arch `
        -CompanyName "AUTARQ" `
        -ProductName "Office" `
        -SourceDir $SourceDir `
        -BuildDir $BuildDir `
        -Sign:$Sign `
        -CertName $CertName `
        -TimestampServer $TimestampServer

    & .\make_zip.ps1 `
        -Version $Version `
        -Arch $Arch `
        -CompanyName "AUTARQ" `
        -ProductName "Office" `
        -BuildDir $BuildDir

    if ($Installer) {
        & .\make_inno.ps1 `
            -Version $Version `
            -Arch $Arch `
            -CompanyName "AUTARQ" `
            -ProductName "Office" `
            -BuildDir $BuildDir `
            -Sign:$Sign `
            -CertName $CertName `
            -TimestampServer $TimestampServer
    }
}
finally {
    Pop-Location
}
