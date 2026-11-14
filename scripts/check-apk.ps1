param(
    [Parameter(Mandatory = $true)][string]$Apk,
    [string]$AllowedHosts = (Join-Path $PSScriptRoot "allowed-hosts.txt")
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

$allowed = Get-Content -LiteralPath $AllowedHosts |
    ForEach-Object { $_.Trim().ToLower() } |
    Where-Object { $_ -ne "" -and -not $_.StartsWith("#") }

$problems = @()
$unknownHosts = @{}
$latin1 = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
$archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Apk))
try {
    foreach ($entry in $archive.Entries) {
        $leaf = Split-Path $entry.FullName -Leaf
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

foreach ($found in ($unknownHosts.Keys | Sort-Object)) {
    Write-Output "host di luar daftar: $found ($($unknownHosts[$found]))"
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object { Write-Output $_ }
    Write-Error "check-apk gagal untuk $Apk"
    exit 1
}
Write-Output "check-apk: tidak ada rahasia atau berkas terlarang di $Apk"
