$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ngrokExe = Join-Path $root "ngrok.exe"
$projectConfig = Join-Path $root "ngrok.yml"
$userConfig = Join-Path $env:LOCALAPPDATA "ngrok\ngrok.yml"

if (-not (Test-Path $ngrokExe)) {
    Write-Host "ngrok.exe belum ada di $root" -ForegroundColor Yellow
    Write-Host "Download manual ngrok untuk Windows, lalu taruh ngrok.exe di folder ini." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $projectConfig)) {
    Write-Host "File config project tidak ditemukan: $projectConfig" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $userConfig)) {
    Write-Host "Config user ngrok belum ada: $userConfig" -ForegroundColor Yellow
    Write-Host "Jalankan: .\tools\ngrok\ngrok.exe config add-authtoken <TOKEN>" -ForegroundColor Yellow
    exit 1
}

Write-Host "Menjalankan ngrok tunnel frontend (5500) dan backend (8000)..." -ForegroundColor Cyan
& $ngrokExe start --all --config $userConfig --config $projectConfig
