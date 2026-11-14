param(
    [Parameter(Mandatory = $true)][string]$Name,
    [switch]$Register
)

$ErrorActionPreference = "Stop"

if ($Name -notmatch '^[a-z][a-z0-9_]*$') {
    Write-Error "Nama harus huruf kecil/angka/underscore dan diawali huruf, contoh: nama_situs"
    exit 1
}

$root = Split-Path -Parent $PSScriptRoot
$infrastructure = Join-Path $root "core\crates\infrastructure"
$sources = Join-Path $infrastructure "src\sources"
$fixtures = Join-Path $infrastructure "fixtures"
$template = Join-Path $sources "example"
$target = Join-Path $sources $Name

if (Test-Path $target) {
    Write-Error "Folder $target sudah ada"
    exit 1
}

$pascal = ($Name -split '_' | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1) }) -join ''
$upper = $Name.ToUpper()

function Convert-Template([string]$text) {
    $text.Replace("Example", $pascal).Replace("EXAMPLE", $upper).Replace("example", $Name)
}

New-Item -ItemType Directory -Path $target | Out-Null
foreach ($file in Get-ChildItem -Path $template -File) {
    $content = Convert-Template (Get-Content -Raw -Path $file.FullName)
    Set-Content -Path (Join-Path $target $file.Name) -Value $content -NoNewline
}

$fixtureTarget = Join-Path $fixtures $Name
New-Item -ItemType Directory -Path $fixtureTarget | Out-Null
foreach ($file in Get-ChildItem -Path (Join-Path $fixtures "example") -File) {
    Copy-Item -Path $file.FullName -Destination (Join-Path $fixtureTarget $file.Name)
}

$line = "    $Name => `"$Name/mod.rs`","
if ($Register) {
    $registry = Join-Path $sources "registry.rs"
    $text = Get-Content -Raw -Path $registry
    $marker = "    #[cfg(test)] example =>"
    if (-not $text.Contains($marker)) {
        Write-Error "Tidak menemukan penanda di registry.rs"
        exit 1
    }
    Set-Content -Path $registry -Value $text.Replace($marker, "$line`r`n$marker") -NoNewline
    Write-Output "Baris ditambahkan ke registry.rs"
}
else {
    Write-Output "Tambahkan satu baris ini di dalam sources! { ... } pada core/crates/infrastructure/src/sources/registry.rs:"
    Write-Output $line
}

Write-Output "Kerangka dibuat di $target dan $fixtureTarget"
Write-Output "Langkah berikut: ganti parser di $Name/parse.rs, simpan HTML asli di fixtures/$Name, sesuaikan $Name/contract.rs, lalu jalankan cargo test -p infrastructure contract"
