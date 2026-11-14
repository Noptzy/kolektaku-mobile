$ErrorActionPreference = "Stop"

$cache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA "Pub\Cache" }
$plugins = Get-ChildItem (Join-Path $cache "hosted\pub.dev") -Directory -Filter "flutter_inappwebview_android-*" -ErrorAction SilentlyContinue

if (-not $plugins) {
    Write-Output "flutter_inappwebview_android belum diunduh; jalankan flutter pub get dulu"
    exit 0
}

$broken = "getDefaultProguardFile('proguard-android.txt')"
$fixed = "getDefaultProguardFile('proguard-android-optimize.txt')"

foreach ($plugin in $plugins) {
    $gradle = Join-Path $plugin.FullName "android\build.gradle"
    $text = Get-Content -Raw -Path $gradle
    if ($text.Contains($broken)) {
        Set-Content -Path $gradle -Value $text.Replace($broken, $fixed) -NoNewline
        Write-Output "ditambal: $($plugin.Name)"
    }
    else {
        Write-Output "sudah benar: $($plugin.Name)"
    }
}
