param(
    [Parameter(Mandatory = $true)][string]$Apk,
    [string]$AllowedHosts = (Join-Path $PSScriptRoot "allowed-hosts.txt"),
    [string]$AllowedPermissions = (Join-Path $PSScriptRoot "allowed-permissions.txt"),
    [string]$PermissionDump = "",
    [switch]$SkipPermissions,
    [string]$ResourceDump = "",
    [switch]$SkipResources,
    [string[]]$RequiredResources = @("raw/tuturu"),
    [long]$MinBytes = 15000000,
    [long]$MaxBytes = 49999999,
    [string[]]$RequiredAbis = @("arm64-v8a", "armeabi-v7a")
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$bannedNames = @("*.jks", "*.keystore", "key.properties", "*.pem", ".env")
$secretPatterns = @(
    "-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----",
    "AKIA[0-9A-Z]{16}",
    "gh[opsu]_[A-Za-z0-9]{20,}",
    "xox[baprs]-[A-Za-z0-9-]{10,}"
)
$hostPattern = [regex]"https?://([A-Za-z0-9][A-Za-z0-9.-]*\.[A-Za-z]{2,})"

function Test-AllowedHost($candidate, $allowed) {
    foreach ($entry in $allowed) {
        if ($candidate -eq $entry -or $candidate.EndsWith(".$entry")) { return $true }
    }
    return $false
}

function Find-Aapt {
    $roots = @($env:ANDROID_SDK_ROOT, $env:ANDROID_HOME) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    foreach ($root in $roots) {
        $tools = Join-Path $root "build-tools"
        if (-not (Test-Path -LiteralPath $tools)) { continue }
        foreach ($folder in (Get-ChildItem -LiteralPath $tools -Directory | Sort-Object Name -Descending)) {
            $candidate = Join-Path $folder.FullName "aapt2.exe"
            if (Test-Path -LiteralPath $candidate) { return $candidate }
        }
    }
    return $null
}

function Get-RequestedPermissions($apk, $dump) {
    if ($dump -ne "") { return Get-Content -LiteralPath $dump }
    $aapt = Find-Aapt
    if (-not $aapt) { throw "aapt2 tidak ditemukan; setel ANDROID_HOME ke folder Android SDK" }
    $lines = & $aapt dump permissions $apk 2>&1
    if ($LASTEXITCODE -ne 0) { throw "aapt2 gagal membaca izin: $($lines -join ' ')" }
    return $lines
}

function Get-ResourceDump($apk, $dump) {
    if ($dump -ne "") { return Get-Content -LiteralPath $dump }
    $aapt = Find-Aapt
    if (-not $aapt) { throw "aapt2 tidak ditemukan; setel ANDROID_HOME ke folder Android SDK" }
    $lines = & $aapt dump resources $apk 2>&1
    if ($LASTEXITCODE -ne 0) { throw "aapt2 gagal membaca resource: $($lines -join ' ')" }
    return $lines
}

function Get-ResourceFile($lines, $name) {
    $header = "resource 0x[0-9a-f]+ " + [regex]::Escape($name) + "\s*$"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ([string]$lines[$i] -notmatch $header) { continue }
        for ($j = $i + 1; $j -lt $lines.Count -and [string]$lines[$j] -notmatch "resource 0x"; $j++) {
            if ([string]$lines[$j] -match "\(file\)\s+(\S+)") { return @{ Found = $true; Path = $Matches[1] } }
        }
        return @{ Found = $true; Path = $null }
    }
    return @{ Found = $false; Path = $null }
}

$allowed = Get-Content -LiteralPath $AllowedHosts |
    ForEach-Object { $_.Trim().ToLower() } |
    Where-Object { $_ -ne "" -and -not $_.StartsWith("#") }

$problems = @()
$unknownHosts = @{}
$size = (Get-Item -LiteralPath $Apk).Length
if ($size -lt $MinBytes) { $problems += "ukuran $size byte di bawah batas bawah $MinBytes (isi tidak lengkap?)" }
if ($size -gt $MaxBytes) { $problems += "ukuran $size byte melewati batas atas $MaxBytes (harus kurang dari 50 MB)" }
$present = @{}
$latin1 = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
$archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Apk))
try {
    foreach ($entry in $archive.Entries) {
        $leaf = Split-Path $entry.FullName -Leaf
        $present[$entry.FullName] = $true
        foreach ($name in $bannedNames) {
            if ($leaf -like $name) { $problems += "berkas terlarang di APK: $($entry.FullName)" }
        }
        if ($entry.Length -eq 0 -or $entry.Length -gt 80MB) { continue }
        $stream = $entry.Open()
        try {
            $buffer = New-Object System.IO.MemoryStream
            $stream.CopyTo($buffer)
            $text = $latin1.GetString($buffer.ToArray())
        } finally {
            $stream.Dispose()
        }
        foreach ($pattern in $secretPatterns) {
            if ($text -match $pattern) { $problems += "pola rahasia di $($entry.FullName): $pattern" }
        }
        if ($entry.FullName -like "lib/*" -or $entry.FullName -like "classes*.dex") {
            foreach ($match in $hostPattern.Matches($text)) {
                $found = $match.Groups[1].Value.ToLower()
                if (-not (Test-AllowedHost $found $allowed)) { $unknownHosts[$found] = $entry.FullName }
            }
        }
    }
} finally {
    $archive.Dispose()
}

foreach ($abi in $RequiredAbis) {
    if (-not $present.ContainsKey("lib/$abi/libbridge.so")) { $problems += "lib/$abi/libbridge.so tidak ada di APK" }
}

if (-not $SkipResources) {
    $resourceLines = @(Get-ResourceDump (Resolve-Path -LiteralPath $Apk) $ResourceDump)
    foreach ($name in $RequiredResources) {
        $resource = Get-ResourceFile $resourceLines $name
        if (-not $resource.Found) {
            $problems += "resource wajib tidak ada di APK: $name (bunyi notifikasi hilang bila ini raw/tuturu)"
        } elseif ($resource.Path -and -not $present.ContainsKey($resource.Path)) {
            $problems += "resource $name menunjuk $($resource.Path) tetapi berkasnya tidak ada di APK"
        }
    }
}

if (-not $SkipPermissions) {
    $permitted = Get-Content -LiteralPath $AllowedPermissions |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" -and -not $_.StartsWith("#") }
    $pattern = [regex]"^uses-permission(-sdk-23)?: name='([^']+)'"
    foreach ($line in (Get-RequestedPermissions (Resolve-Path -LiteralPath $Apk) $PermissionDump)) {
        $match = $pattern.Match([string]$line)
        if (-not $match.Success) { continue }
        $name = $match.Groups[2].Value
        if ($permitted -notcontains $name) { $problems += "izin di luar daftar: $name" }
    }
}

foreach ($found in ($unknownHosts.Keys | Sort-Object)) {
    Write-Output "host di luar daftar: $found ($($unknownHosts[$found]))"
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object { Write-Output $_ }
    Write-Error "check-apk gagal untuk $Apk"
    exit 1
}
Write-Output "check-apk: $Apk ($size byte) lolos: ukuran, inti Rust, resource wajib, izin, rahasia, dan berkas terlarang"
