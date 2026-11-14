param(
    [Parameter(Mandatory = $true)][string]$RepoRoot
)

$bannedNames = @("*.jks", "*.keystore", "key.properties")
$secretPatterns = @(
    "-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----",
    "AKIA[0-9A-Z]{16}",
    "gh[opsu]_[A-Za-z0-9]{20,}"
)
$textExtensions = @(".rs", ".dart", ".kt", ".java", ".yaml", ".yml", ".json", ".toml", ".ps1", ".md", ".kts", ".gradle")
$vendoredPrefix = "core/rust_builder/cargokit/"

Push-Location $RepoRoot
try {
    $candidates = git ls-files --cached --others --exclude-standard
} finally {
    Pop-Location
}

$found = @()

foreach ($relative in $candidates) {
    if ($relative.StartsWith($vendoredPrefix)) { continue }
    $path = Join-Path $RepoRoot $relative
    if (-not (Test-Path -LiteralPath $path)) { continue }

    foreach ($pattern in $bannedNames) {
        if ((Split-Path $relative -Leaf) -like $pattern) {
            $found += "berkas terlarang: $relative"
        }
    }

    if ($textExtensions -notcontains [System.IO.Path]::GetExtension($relative)) { continue }
    $content = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { continue }
    foreach ($pattern in $secretPatterns) {
        if ($content -match $pattern) {
            $found += "pola rahasia di: $relative"
        }
    }
}

if ($found.Count -gt 0) {
    Write-Output "Ditemukan kemungkinan rahasia:"
    $found | ForEach-Object { Write-Output "  - $_" }
    exit 1
}

Write-Output "Tidak ada rahasia yang terdeteksi ($($candidates.Count) berkas diperiksa)."
exit 0
