param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
$lib = Join-Path $RepoRoot "app\lib"
$files = Get-ChildItem -Path $lib -Recurse -Filter *.dart |
    Where-Object { $_.FullName -notmatch "\\src\\rust\\" }

$networkPatterns = @(
    "package:http/",
    "package:dio/",
    "package:html/",
    "package:xml/",
    "package:web_scraper",
    "HttpClient\(",
    "dart:io.*HttpClient"
)
$englishWords = @(
    "Loading", "Error", "Retry", "Cancel", "Search", "Settings", "Home", "Back",
    "Close", "Delete", "Save", "Share", "Download", "Library", "Favorites",
    "History", "Continue", "Watch", "Please", "Failed", "Success", "Unknown",
    "Select", "Choose", "Done", "Confirm", "Submit", "Open"
)
$wordPattern = "'[^'\r\n]*\b(" + ($englishWords -join "|") + ")\b[^'\r\n]*'"
$translationTechWords = @(
    "model", "mesin", "Google", "DeepL", "ML Kit", "LibreTranslate", "Bing",
    "Microsoft Translator"
)
$translationTechPattern = "'[^'\r\n]*\b(" + ($translationTechWords -join "|") + ")\b[^'\r\n]*'"
$aiPattern = "'[^'\r\n]*\bAI\b[^'\r\n]*'"

$problems = @()
foreach ($file in $files) {
    $relative = $file.FullName.Substring($RepoRoot.Length + 1)
    $lines = Get-Content -LiteralPath $file.FullName
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        if ($line -match "^\s*import ") {
            foreach ($pattern in $networkPatterns) {
                if ($line -match $pattern) { $problems += "jaringan di lib: ${relative}:$($index + 1): $line" }
            }
            continue
        }
        foreach ($pattern in $networkPatterns) {
            if ($pattern -notlike "package:*" -and $line -match $pattern) {
                $problems += "jaringan di lib: ${relative}:$($index + 1): $line"
            }
        }
        if ($line -notmatch "Text\(|title:|label:|message:|description:|hint:|placeholder:|actionLabel:") { continue }
        if ($line -match "Key\(|ValueKey\(|MethodChannel\(|Uri\.parse|RegExp\(|https?://") { continue }
        if ($line -match $wordPattern) {
            $problems += "kata Inggris di teks layar: ${relative}:$($index + 1): $($line.Trim())"
        }
        if (($line -match $translationTechPattern) -or ($line -cmatch $aiPattern)) {
            $problems += "teknologi terjemahan disebut di teks layar: ${relative}:$($index + 1): $($line.Trim())"
        }
    }
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object { Write-Output $_ }
    Write-Error "check-lib menemukan $($problems.Count) temuan"
    exit 1
}
Write-Output "check-lib: tidak ada jaringan atau kata Inggris di app/lib"
