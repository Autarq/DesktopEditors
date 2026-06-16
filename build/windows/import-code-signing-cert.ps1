param (
    [Parameter(Mandatory=$true)]
    [string]$PfxBase64,
    [Parameter(Mandatory=$true)]
    [string]$Password,
    [string]$CertStoreLocation = "Cert:\CurrentUser\My"
)

$ErrorActionPreference = "Stop"

$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
$PfxPath = Join-Path $TempDir "code-signing.pfx"

New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
try {
    [System.IO.File]::WriteAllBytes($PfxPath, [System.Convert]::FromBase64String($PfxBase64))
    $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $cert = Import-PfxCertificate `
        -FilePath $PfxPath `
        -CertStoreLocation $CertStoreLocation `
        -Password $SecurePassword `
        -Exportable:$false

    if (-not $cert) {
        throw "Import-PfxCertificate did not return a certificate"
    }

    Write-Host "Imported Windows code signing certificate:"
    Write-Host "  Subject    = $($cert.Subject)"
    Write-Host "  Thumbprint = $($cert.Thumbprint)"
    Write-Host "  NotAfter   = $($cert.NotAfter.ToString('u'))"
}
finally {
    Remove-Item -Force -Recurse -LiteralPath $TempDir -ErrorAction SilentlyContinue
}
