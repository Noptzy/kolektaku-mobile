$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

function Invoke-Step($name, $scriptBlock) {
    Write-Output "=== $name ==="
    & $scriptBlock
    if ($LASTEXITCODE -ne 0) {
        Write-Error "$name gagal (exit code $LASTEXITCODE)"
        exit 1
    }
}

Invoke-Step "cargo fmt" {
    cargo fmt --manifest-path "$root\core\Cargo.toml" --all -- --check
}

Invoke-Step "cargo clippy" {
    cargo clippy --manifest-path "$root\core\Cargo.toml" --workspace --all-targets --features application/testing -- -D warnings
}

Invoke-Step "cargo test" {
    cargo test --manifest-path "$root\core\Cargo.toml" --workspace --features application/testing
}

Invoke-Step "bridge untuk uji Flutter" {
    cargo build --manifest-path "$root\core\Cargo.toml" -p bridge
}

Invoke-Step "tambalan plugin WebView" {
    & "$PSScriptRoot\patch-webview-plugin.ps1"
    $global:LASTEXITCODE = 0
}

Invoke-Step "dart format" {
    Push-Location (Join-Path $root "app")
    try { dart format --output=none --set-exit-if-changed lib test } finally { Pop-Location }
}

Invoke-Step "kotlin format" {
    $format = Get-ChildItem "C:\Program Files\JetBrains" -Filter "format.bat" -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -eq $format) {
        Write-Warning "IntelliJ IDEA tidak ditemukan; pemformat Kotlin dilewati"
        $global:LASTEXITCODE = 0
        return
    }
    $kotlin = Join-Path $root "app\android\app\src\main\kotlin"
    $report = & $format.FullName -allowDefaults -r -d -m "*.kt" $kotlin
    $report | Write-Output
    $global:LASTEXITCODE = 0
    if ($report -match "Needs reformatting") {
        $global:LASTEXITCODE = 1
    }
}

Invoke-Step "izin manifest rilis" {
    $manifest = Join-Path $root "app\android\app\src\main\AndroidManifest.xml"
    $declared = Select-String -Path $manifest -Pattern "android.permission.INTERNET" -Quiet
    $global:LASTEXITCODE = 0
    if (-not $declared) {
        Write-Output "AndroidManifest.xml utama belum meminta izin INTERNET; build rilis tidak akan bisa memakai jaringan"
        $global:LASTEXITCODE = 1
    }
}

Invoke-Step "flutter analyze" {
    Push-Location (Join-Path $root "app")
    try { flutter analyze } finally { Pop-Location }
}

Invoke-Step "flutter test" {
    Push-Location (Join-Path $root "app")
    try { flutter test } finally { Pop-Location }
}

Invoke-Step "pemeriksa rahasia" {
    & "$PSScriptRoot\check-secrets.ps1" -RepoRoot $root
}

Write-Output "=== verify.ps1: semua langkah hijau ==="
