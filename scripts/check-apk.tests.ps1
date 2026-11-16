$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$temp = Join-Path ([System.IO.Path]::GetTempPath()) "check-apk-tests-$PID"
New-Item -ItemType Directory -Path $temp | Out-Null
$hosts = Join-Path $temp "hosts.txt"
Set-Content -LiteralPath $hosts -Value "example.com"
$script = Join-Path $PSScriptRoot "check-apk.ps1"

function New-Apk($name, $entries) {
    $path = Join-Path $temp $name
    $zip = [System.IO.Compression.ZipFile]::Open($path, "Create")
    foreach ($entry in $entries) {
        $item = $zip.CreateEntry($entry)
        $writer = New-Object System.IO.StreamWriter($item.Open())
        $writer.Write("x" * 2000)
        $writer.Dispose()
    }
    $zip.Dispose()
    return $path
}

function Test-Case($label, $apk, $expectOk, $extra) {
    $global:LASTEXITCODE = 0
    $output = & pwsh -NoProfile -File $script -Apk $apk -AllowedHosts $hosts @extra 2>&1
    $ok = ($LASTEXITCODE -eq 0)
    if ($ok -ne $expectOk) {
        Write-Output "GAGAL: $label"
        $output | ForEach-Object { Write-Output "  $_" }
        $script:failed = $true
    } else {
        Write-Output "lulus: $label"
    }
}

$failed = $false
$good = New-Apk "good.apk" @("lib/arm64-v8a/libbridge.so", "lib/armeabi-v7a/libbridge.so", "classes.dex")
$noCore = New-Apk "nocore.apk" @("lib/arm64-v8a/libbridge.so", "classes.dex")
$limits = @("-MinBytes", "100", "-MaxBytes", "1000000", "-SkipPermissions")
Test-Case "APK baik" $good $true $limits
Test-Case "tanpa inti Rust untuk satu ABI" $noCore $false $limits
Test-Case "terlalu besar" $good $false @("-MinBytes", "100", "-MaxBytes", "300", "-SkipPermissions")
Test-Case "terlalu kecil" $good $false @("-MinBytes", "10000000", "-MaxBytes", "20000000", "-SkipPermissions")
$permissions = Join-Path $temp "permissions.txt"
Set-Content -LiteralPath $permissions -Value @("android.permission.INTERNET", "# komentar")
$onlyAllowed = Join-Path $temp "dump-ok.txt"
Set-Content -LiteralPath $onlyAllowed -Value @("package: x", "uses-permission: name='android.permission.INTERNET'")
$extra = Join-Path $temp "dump-extra.txt"
Set-Content -LiteralPath $extra -Value @("package: x", "uses-permission: name='android.permission.INTERNET'", "uses-permission: name='android.permission.CAMERA'")
$base = @("-MinBytes", "100", "-MaxBytes", "1000000", "-AllowedPermissions", $permissions)
Test-Case "izin sesuai daftar" $good $true ($base + @("-PermissionDump", $onlyAllowed))
Test-Case "izin kamera di luar daftar" $good $false ($base + @("-PermissionDump", $extra))
Remove-Item -Recurse -Force $temp
if ($failed) { exit 1 }
Write-Output "check-apk.tests: semua lulus"
