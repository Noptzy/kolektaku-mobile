param(
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$MinSupported = "0.0.0",
    [string]$NotesFile = "",
    [switch]$Publish
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root "app"
$repo = "Noptzy/kolektaku-mobile"
$abis = @("arm64-v8a", "armeabi-v7a")

function Invoke-Step($name, $scriptBlock) {
    Write-Output "=== $name ==="
    & $scriptBlock
    if ($LASTEXITCODE -ne 0) {
        Write-Error "$name gagal (exit code $LASTEXITCODE)"
        exit 1
    }
}

if ($Version -notmatch "^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$") {
    Write-Error "versi '$Version' bukan semver (contoh 0.1.0 atau 0.1.0-rc1)"
    exit 1
}
if ($MinSupported -notmatch "^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$") {
    Write-Error "minSupported '$MinSupported' bukan semver"
    exit 1
}

$pubspec = Get-Content (Join-Path $app "pubspec.yaml") -Raw
if ($pubspec -notmatch "(?m)^version:\s*([^\s+]+)") {
    Write-Error "versi tidak ditemukan di pubspec.yaml"
    exit 1
}
if ($Matches[1] -ne $Version) {
    Write-Error "pubspec.yaml berversi $($Matches[1]), bukan $Version; ubah dulu lalu ulangi"
    exit 1
}

$notes = ""
if ($NotesFile -ne "") {
    $notes = (Get-Content -LiteralPath $NotesFile -Raw).Trim()
}

$dist = Join-Path $root "dist\v$Version"
if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
New-Item -ItemType Directory -Path $dist | Out-Null

Invoke-Step "verify" { & "$PSScriptRoot\verify.ps1" }

Invoke-Step "build APK rilis" {
    Push-Location $app
    try { flutter build apk --release --target-platform android-arm,android-arm64 --obfuscate --split-debug-info=build\symbols } finally { Pop-Location }
}

$source = Join-Path $app "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path -LiteralPath $source)) {
    Write-Error "APK rilis tidak ditemukan di $source"
    exit 1
}
$name = "kolektaku-mobile-$Version.apk"
$target = Join-Path $dist $name
Copy-Item -LiteralPath $source -Destination $target
$hash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLower()
$entry = [ordered]@{
    url    = "https://github.com/$repo/releases/download/v$Version/$name"
    size   = (Get-Item -LiteralPath $target).Length
    sha256 = $hash
}
$assets = [ordered]@{}
foreach ($abi in $abis) { $assets[$abi] = $entry }
Invoke-Step "periksa $name" {
    & "$PSScriptRoot\check-apk.ps1" -Apk $target
}

$manifest = [ordered]@{
    version      = $Version
    minSupported = $MinSupported
    notes        = $notes
    assets       = $assets
}
$manifestPath = Join-Path $dist "latest.json"
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Output "=== berkas rilis siap di $dist ==="
Get-ChildItem $dist | ForEach-Object { Write-Output "$($_.Name)  $($_.Length) byte" }

if (-not $Publish) {
    Write-Output "Mode uji: tidak ada tag, push, atau rilis GitHub dibuat. Tambahkan -Publish untuk menerbitkan."
    exit 0
}

Invoke-Step "tag v$Version" {
    git -C $root tag "v$Version"
}
Invoke-Step "push tag" {
    git -C $root push origin "v$Version"
}
Invoke-Step "rilis GitHub" {
    $files = @(Get-ChildItem $dist -Filter *.apk | ForEach-Object { $_.FullName }) + $manifestPath
    $arguments = @("release", "create", "v$Version", "--repo", $repo, "--title", "Kolektaku $Version")
    if ($notes -ne "") { $arguments += @("--notes", $notes) } else { $arguments += @("--generate-notes") }
    if ($Version -like "*-*") { $arguments += "--prerelease" }
    gh @arguments @files
}

Invoke-Step "cek unduhan tanpa login" {
    $check = Join-Path $dist "downloaded-latest.json"
    Invoke-WebRequest -Uri "https://github.com/$repo/releases/download/v$Version/latest.json" -OutFile $check
    $remote = Get-Content -LiteralPath $check -Raw | ConvertFrom-Json
    $global:LASTEXITCODE = 0
    if ($remote.version -ne $Version) {
        Write-Output "versi di latest.json terunduh ($($remote.version)) berbeda dari $Version"
        $global:LASTEXITCODE = 1
    }
}
Write-Output "=== rilis v$Version selesai ==="
