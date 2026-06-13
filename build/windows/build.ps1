param (
    [ValidateSet("x64")]
    [string]$Arch = "x64",
    [string]$QtRoot = "C:/Qt/5.15.2",
    [string]$VsPath,
    [string]$BuildToolsRev = $env:BUILD_TOOLS_REV
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildRoot = Resolve-Path (Join-Path $ScriptDir "..")
$RepoRoot = Resolve-Path (Join-Path $BuildRoot "..")
$BuildToolsDir = Join-Path $RepoRoot "build_tools"
$ConfigPath = Join-Path $BuildToolsDir "config"

if (-not $BuildToolsRev) {
    $BuildToolsRev = "c5f6c2e02b50dfcc5c53a207f9a6cde84896de91"
}

function Invoke-Checked {
    param (
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][string[]]$ArgumentList
    )

    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $FilePath $($ArgumentList -join ' ')"
    }
}

function Apply-BuildToolsPatch {
    param (
        [Parameter(Mandatory=$true)][string]$PatchPath
    )

    if (-not (Test-Path $PatchPath)) {
        return
    }

    foreach ($UseZeroContext in @($false, $true)) {
        $PatchMode = @()
        if ($UseZeroContext) {
            $PatchMode = @("--unidiff-zero")
        }

        & git -C $BuildToolsDir apply @PatchMode --check $PatchPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Applying build_tools patch: $PatchPath"
            Invoke-Checked -FilePath "git" -ArgumentList (@("-C", $BuildToolsDir, "apply") + $PatchMode + @($PatchPath))
            return
        }

        & git -C $BuildToolsDir apply @PatchMode --reverse --check $PatchPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "build_tools patch already applied: $PatchPath"
            return
        }
    }

    throw "Unable to apply build_tools patch: $PatchPath"
}

if ($Arch -ne "x64") {
    throw "The hosted Windows source build currently supports x64 only."
}

if (-not $VsPath) {
    $Candidates = @(
        "${env:ProgramFiles}/Microsoft Visual Studio/2022/Enterprise/VC/Auxiliary/Build",
        "${env:ProgramFiles}/Microsoft Visual Studio/2022/Professional/VC/Auxiliary/Build",
        "${env:ProgramFiles}/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build",
        "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2019/Enterprise/VC/Auxiliary/Build",
        "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2019/Professional/VC/Auxiliary/Build",
        "${env:ProgramFiles(x86)}/Microsoft Visual Studio/2019/Community/VC/Auxiliary/Build"
    )
    $VsPath = $Candidates | Where-Object { $_ -and (Test-Path (Join-Path $_ "vcvarsall.bat")) } | Select-Object -First 1
}

if (-not $VsPath -or -not (Test-Path (Join-Path $VsPath "vcvarsall.bat"))) {
    throw "Unable to find vcvarsall.bat. Pass -VsPath or install Visual Studio Build Tools."
}

$VsInstallRoot = Resolve-Path (Join-Path $VsPath "../../..")
$env:vs2019_install = $VsInstallRoot.Path
$env:GYP_MSVS_OVERRIDE_PATH = $VsInstallRoot.Path
# Older build_tools scripts still key off vs-version=2019, while HEIF/x265 CMake needs the hosted VS2022 generator.
$env:EO_WINDOWS_CMAKE_VS_VERSION = "17 2022"

$QtRoot = $QtRoot.Replace("\", "/")
$Qmake = Join-Path $QtRoot "msvc2019_64/bin/qmake.exe"
if (-not (Test-Path $Qmake)) {
    throw "Missing Qt qmake for win_64: $Qmake"
}

if (-not (Test-Path (Join-Path $BuildToolsDir ".git"))) {
    if (Test-Path $BuildToolsDir) {
        throw "build_tools exists but is not a git checkout: $BuildToolsDir"
    }

    Write-Host "Cloning ONLYOFFICE/build_tools into $BuildToolsDir"
    Invoke-Checked -FilePath "git" -ArgumentList @(
        "clone",
        "--filter=blob:none",
        "https://github.com/ONLYOFFICE/build_tools.git",
        $BuildToolsDir
    )
}

Write-Host "Checking out build_tools $BuildToolsRev"
Invoke-Checked -FilePath "git" -ArgumentList @("-C", $BuildToolsDir, "fetch", "--tags", "origin")
Invoke-Checked -FilePath "git" -ArgumentList @("-C", $BuildToolsDir, "checkout", $BuildToolsRev)
Apply-BuildToolsPatch -PatchPath (Join-Path $ScriptDir "patches/build-tools-boost-win64-architecture.patch")
Apply-BuildToolsPatch -PatchPath (Join-Path $ScriptDir "patches/build-tools-heif-vs2022-cmake.patch")

$BrotliDir = Join-Path $RepoRoot "core/Common/3dParty/brotli"
$BrotliInclude = Join-Path $BrotliDir "brotli/c/include"
$BrotliDecodeHeader = Join-Path $BrotliInclude "brotli/decode.h"
if (-not (Test-Path $BrotliDecodeHeader)) {
    Write-Host "Preparing Brotli sources for Windows FreeType build"
    Push-Location $BrotliDir
    try {
        Invoke-Checked -FilePath "python" -ArgumentList @("make.py")
    }
    finally {
        Pop-Location
    }
}
if (-not (Test-Path $BrotliDecodeHeader)) {
    throw "Missing Brotli decode header after preparation: $BrotliDecodeHeader"
}
$BrotliIncludeForQmake = $BrotliInclude.Replace("\", "/")

$HarfBuzzDir = Join-Path $RepoRoot "core/Common/3dParty/harfbuzz"
$HarfBuzzInclude = Join-Path $HarfBuzzDir "harfbuzz/src"
$HarfBuzzHeader = Join-Path $HarfBuzzInclude "hb.h"
$HarfBuzzPri = Join-Path $HarfBuzzDir "harfbuzz.pri"
if ((Test-Path (Join-Path $HarfBuzzDir "harfbuzz")) -and -not (Test-Path $HarfBuzzPri)) {
    Remove-Item -Recurse -Force (Join-Path $HarfBuzzDir "harfbuzz")
}
if ((-not (Test-Path $HarfBuzzHeader)) -or (-not (Test-Path $HarfBuzzPri))) {
    Write-Host "Preparing HarfBuzz sources for Windows text shaper build"
    Push-Location $HarfBuzzDir
    try {
        Invoke-Checked -FilePath "python" -ArgumentList @("make.py")
    }
    finally {
        Pop-Location
    }
}
if (-not (Test-Path $HarfBuzzHeader)) {
    throw "Missing HarfBuzz header after preparation: $HarfBuzzHeader"
}
if (-not (Test-Path $HarfBuzzPri)) {
    throw "Missing HarfBuzz qmake project after preparation: $HarfBuzzPri"
}
$HarfBuzzIncludeForQmake = $HarfBuzzInclude.Replace("\", "/")

$HyphenDir = Join-Path $RepoRoot "core/Common/3dParty/hyphen"
$HyphenCheckout = Join-Path $HyphenDir "hyphen"
$HyphenHeader = Join-Path $HyphenDir "hyphen/hnjalloc.h"
if (-not (Test-Path $HyphenHeader)) {
    Write-Host "Preparing Hyphen sources for Windows hyphenation build"
    if (Test-Path $HyphenCheckout) {
        Remove-Item -Recurse -Force $HyphenCheckout
    }
    Invoke-Checked -FilePath "git" -ArgumentList @(
        "clone",
        "https://github.com/hunspell/hyphen.git",
        $HyphenCheckout
    )
}
if (-not (Test-Path $HyphenHeader)) {
    throw "Missing Hyphen header after preparation: $HyphenHeader"
}
$HyphenIncludeForQmake = $HyphenDir.Replace("\", "/")

$HunspellInclude = Join-Path $RepoRoot "core/Common/3dParty/hunspell/hunspell/src"
$HunspellHeader = Join-Path $HunspellInclude "hunspell/hunspell.h"
if (-not (Test-Path $HunspellHeader)) {
    Write-Host "Hunspell sources are not present yet; build_tools will fetch them before compiling the desktop app"
}
$HunspellIncludeForQmake = $HunspellInclude.Replace("\", "/")

$WebAppsBuildRoot = Join-Path $RepoRoot "web-apps/deploy"
$env:BUILD_ROOT = $WebAppsBuildRoot.Replace("\", "/")

@"
update="0"
branch="master"
clean="1"
module="desktop"
develop="0"
beta="0"
platform="win_64"
qt-dir="$QtRoot"
sql-type="postgres"
db-port="5432"
db-name="onlyoffice"
db-user="onlyoffice"
db-pass="onlyoffice"
no-apps="0"
git-protocol="https"
sdkjs-plugin="default"
sdkjs-plugin-server="default"
vs-version="2019"
vs-path="$($VsPath.Replace("\", "/"))"
siteUrl="127.0.0.1"
multiprocess="1"
sysroot="0"
branding-name="AUTARQ"
config_addon_windows="no_tests"
qmake_addon="INCLUDEPATH+=$BrotliIncludeForQmake INCLUDEPATH+=$HarfBuzzIncludeForQmake INCLUDEPATH+=$HyphenIncludeForQmake INCLUDEPATH+=$HunspellIncludeForQmake"
"@ | Set-Content -Encoding UTF8 -Path $ConfigPath

Write-Host @"
Windows source build configuration
Arch       = $Arch
QtRoot     = $QtRoot
Qmake      = $Qmake
VsPath     = $VsPath
VsRoot     = $($VsInstallRoot.Path)
BuildTools = $BuildToolsDir
BuildToolsRev = $BuildToolsRev
BUILD_ROOT = $env:BUILD_ROOT
"@

Push-Location $BuildToolsDir
try {
    $VcVarsAll = Join-Path $VsPath "vcvarsall.bat"
    $BuildCommand = "`"$VcVarsAll`" x64 && python make.py"
    Invoke-Checked -FilePath "cmd.exe" -ArgumentList @("/d", "/s", "/c", $BuildCommand)
}
finally {
    Pop-Location
}

$PayloadDir = Join-Path $RepoRoot "build_tools/out/win_64/AUTARQ/DesktopEditors"
if (-not (Test-Path $PayloadDir)) {
    throw "Windows payload was not created: $PayloadDir"
}

$DesktopEditorsExe = Join-Path $PayloadDir "DesktopEditors.exe"
if (-not (Test-Path $DesktopEditorsExe)) {
    throw "Windows launcher is missing: $DesktopEditorsExe"
}

Write-Host "Windows payload created: $PayloadDir"
