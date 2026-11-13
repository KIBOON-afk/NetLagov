# NetLagov - Make_EXE_PS5.ps1
# Run: powershell -ExecutionPolicy Bypass -File Make_EXE_PS5.ps1

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$InputFile  = Join-Path $ScriptDir "NetLagov_v2_3_3_PS5_compile.ps1"
$OutputFile = Join-Path $ScriptDir "NetLagov_PS5_v2_3_3_final.exe"
$IconFile   = Join-Path $ScriptDir "NetLagov.ico"

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "Installing ps2exe..." -ForegroundColor Cyan
    Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
}
Import-Module ps2exe -Force

if (-not (Test-Path $InputFile)) {
    Write-Error "File not found: $InputFile"
    exit 1
}

Write-Host "Building PS5 EXE -> $OutputFile" -ForegroundColor Green

$params = @{
    InputFile    = $InputFile
    OutputFile   = $OutputFile
    NoConsole    = $true
    RequireAdmin = $true
    Title        = "NetLagov"
    Description  = "NetLagov v2.3.3 PS5 - Network and Game Optimizer"
    Company      = "NetLagov"
    Version      = "2.3.3.0"
    DPIAware     = $true
}

if (Test-Path $IconFile) {
    $params["IconFile"] = $IconFile
    Write-Host "Icon: $IconFile" -ForegroundColor Cyan
} else {
    Write-Host "Icon not found - EXE will use default icon" -ForegroundColor Yellow
}

Invoke-ps2exe @params

if (Test-Path $OutputFile) {
    $size = [math]::Round((Get-Item $OutputFile).Length / 1KB, 1)
    Write-Host ""
    Write-Host "Done! File: $OutputFile" -ForegroundColor Green
    Write-Host "Size: $size KB" -ForegroundColor Cyan
} else {
    Write-Error "EXE was not created."
}

Write-Host ""
Write-Host "Press Enter to exit..."
Read-Host

