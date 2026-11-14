param([string]$Device = "")

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root "app"
$log = Join-Path ([IO.Path]::GetTempPath()) "kolektaku-pip.log"
$package = "app.kolektaku.mobile"

if (-not $Device) {
    $Device = (adb devices | Select-String "\tdevice$" | Select-Object -First 1).ToString().Split("`t")[0]
}
if (-not $Device) {
    Write-Error "tidak ada perangkat Android yang terhubung"
    exit 1
}

function Wait-Marker([string]$name, [int]$seconds) {
    $limit = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $limit) {
        if ((Test-Path $log) -and (Select-String -Path $log -Pattern "MARK $name" -Quiet)) { return }
        if ((Test-Path $log) -and (Select-String -Path $log -Pattern "Some tests failed" -Quiet)) {
            Write-Error "uji gagal sebelum penanda $name"
            exit 1
        }
        Start-Sleep -Milliseconds 400
    }
    Write-Error "penanda $name tidak muncul dalam $seconds detik"
    exit 1
}

function Get-PipBounds {
    $dump = adb -s $Device shell dumpsys activity activities | Out-String
    $pinned = [regex]::Match($dump, "mBounds=Rect\((\d+), (\d+) - (\d+), (\d+)\)[^`n]*mWindowingMode=pinned")
    if (-not $pinned.Success) { return $null }
    return @{
        Left = [int]$pinned.Groups[1].Value; Top = [int]$pinned.Groups[2].Value
        Right = [int]$pinned.Groups[3].Value; Bottom = [int]$pinned.Groups[4].Value
    }
}

function Press-PipButton {
    $b = Get-PipBounds
    if ($null -eq $b) { Write-Error "jendela kecil tidak ditemukan"; exit 1 }
    $x = [int](($b.Left + $b.Right) / 2)
    $height = $b.Bottom - $b.Top
    $revealY = [int]($b.Top + 0.58 * $height)
    $buttonY = [int]($b.Top + 0.78 * $height)
    adb -s $Device shell "input tap $x $revealY; sleep 0.7; input tap $x $buttonY" | Out-Null
}

function Start-DeviceTest([string]$file) {
    Remove-Item $log -ErrorAction SilentlyContinue
    adb -s $Device shell am force-stop $package | Out-Null
    adb -s $Device shell input keyevent KEYCODE_WAKEUP | Out-Null
    return Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c", "flutter test integration_test/$file -d $Device" `
        -WorkingDirectory $app -RedirectStandardOutput $log -RedirectStandardError "$log.err" `
        -PassThru -WindowStyle Hidden
}

function Finish-DeviceTest($process, [string]$label) {
    $process.WaitForExit(120000) | Out-Null
    if (-not (Select-String -Path $log -Pattern "All tests passed" -Quiet)) {
        Write-Error "$label gagal, lihat $log"
        exit 1
    }
    Write-Output "$label lulus"
}

$process = Start-DeviceTest "pip_test.dart"

Wait-Marker "READY_FOR_HOME" 900
adb -s $Device shell input keyevent KEYCODE_HOME | Out-Null
Wait-Marker "IN_PIP" 30
Write-Output "jendela kecil terbuka: $((Get-PipBounds) | ConvertTo-Json -Compress)"

Press-PipButton
Wait-Marker "PAUSED" 30
Write-Output "tombol jendela kecil menjeda video"

Press-PipButton
Wait-Marker "RESUMED" 30
Write-Output "tombol jendela kecil melanjutkan video"

adb -s $Device shell am start -n "$package/.MainActivity" | Out-Null
Wait-Marker "BACK_FULL" 30
Write-Output "layar penuh kembali"

Finish-DeviceTest $process "Home membuka jendela kecil"

$process = Start-DeviceTest "pip_back_test.dart"
Wait-Marker "READY_FOR_BACK" 900
adb -s $Device shell input keyevent KEYCODE_BACK | Out-Null
Wait-Marker "BACK_DONE" 30
Start-Sleep -Seconds 3
if ($null -ne (Get-PipBounds)) {
    Write-Error "Back membuka jendela kecil, padahal tidak boleh"
    exit 1
}
Write-Output "Back tidak membuka jendela kecil"
Wait-Marker "SETTLED" 30
Finish-DeviceTest $process "Back menutup pemutar"

Write-Output "verify-pip: lulus"
exit 0
