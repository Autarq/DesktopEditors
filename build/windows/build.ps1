param (
    [ValidateSet("x64")]
    [string]$Arch = "x64",
    [string]$QtRoot = "C:/Qt/5.15.2",
    [string]$VsPath
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildRoot = Resolve-Path (Join-Path $ScriptDir "..")
$RepoRoot = Resolve-Path (Join-Path $BuildRoot "..")
$BuildToolsDir = Join-Path $RepoRoot "build_tools"
$ConfigPath = Join-Path $BuildToolsDir "config"

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

$QtRoot = $QtRoot.Replace("\", "/")
$Qmake = Join-Path $QtRoot "msvc2019_64/bin/qmake.exe"
if (-not (Test-Path $Qmake)) {
    throw "Missing Qt qmake for win_64: $Qmake"
}

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
"@ | Set-Content -Encoding UTF8 -Path $ConfigPath

Write-Host @"
Windows source build configuration
Arch       = $Arch
QtRoot     = $QtRoot
Qmake      = $Qmake
VsPath     = $VsPath
BuildTools = $BuildToolsDir
"@

Push-Location $BuildToolsDir
try {
    python make.py
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
