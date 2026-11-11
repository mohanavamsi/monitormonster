# MonitorMonster Windows Build Script
# Generates a self-contained single-file executable (.exe)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Resolve-Path "$ScriptDir/../MonitorMonster"
$OutputDir = Resolve-Path "$ScriptDir/../../dist/windows" -ErrorAction SilentlyContinue

if (-not $OutputDir) {
    $OutputDir = New-Item -ItemType Directory -Path "$ScriptDir/../../dist/windows" -Force
}

Write-Host "==> Building MonitorMonster for Windows (x64 Self-Contained)..." -ForegroundColor Cyan

dotnet publish "$ProjectDir/MonitorMonster.csproj" `
    -c Release `
    -r win-x64 `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    -o "$OutputDir"

$ExePath = Join-Path $OutputDir "MonitorMonster.exe"
if (Test-Path $ExePath) {
    Write-Host "`n🎉 Successfully built MonitorMonster for Windows:" -ForegroundColor Green
    Write-Host "   📦 Executable: $ExePath" -ForegroundColor Yellow
    Write-Host "   📏 Size: $([math]::Round((Get-Item $ExePath).Length / 1MB, 2)) MB" -ForegroundColor Gray
} else {
    Write-Error "Build failed: MonitorMonster.exe not found in $OutputDir"
}
