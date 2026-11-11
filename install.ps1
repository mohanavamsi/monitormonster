# MonitorMonster One-Line Windows Installer
# Run in PowerShell: irm https://raw.githubusercontent.com/mohanavamsi/monitormonster/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$AppName = "MonitorMonster"
$Repo = "mohanavamsi/monitormonster"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$TargetExe = Join-Path $InstallDir "$AppName.exe"
$ReleaseUrl = "https://github.com/$Repo/releases/latest/download/MonitorMonster.exe"

Write-Host "👾 Installing $AppName (by itvizag) on your Windows PC..." -ForegroundColor Cyan

# Ensure target directory exists
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# Stop existing instance if running
Get-Process -Name $AppName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$Downloaded = $false

# 1. Attempt to download pre-built standalone binary
try {
    Write-Host "==> Downloading latest release binary from GitHub..." -ForegroundColor Yellow
    
    # Prefer curl.exe (built into Windows 10/11) as it handles 302 redirects cleanly
    if (Get-Command "curl.exe" -ErrorAction SilentlyContinue) {
        & curl.exe -sLf "$ReleaseUrl" -o "$TargetExe"
        if ((Test-Path $TargetExe) -and ((Get-Item $TargetExe).Length -gt 500000)) {
            $Downloaded = $true
        }
    }

    # Fallback to .NET WebClient / Invoke-WebRequest
    if (-not $Downloaded) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.Add("User-Agent", "MonitorMonster-Installer")
        $WebClient.DownloadFile($ReleaseUrl, $TargetExe)
        if ((Test-Path $TargetExe) -and ((Get-Item $TargetExe).Length -gt 500000)) {
            $Downloaded = $true
        }
    }
} catch {
    Write-Host "==> Pre-built binary download failed: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# 2. Build from source fallback if dotnet is available
if (-not $Downloaded) {
    if (Get-Command "dotnet" -ErrorAction SilentlyContinue) {
        $TempSrc = Join-Path $env:TEMP "$AppName-src"
        if (Test-Path $TempSrc) { Remove-Item -Recurse -Force $TempSrc }
        
        Write-Host "==> Cloning source repository..." -ForegroundColor Yellow
        git clone --depth 1 "https://github.com/$Repo.git" $TempSrc
        
        Write-Host "==> Compiling native single-file executable..." -ForegroundColor Yellow
        dotnet publish "$TempSrc/windows/MonitorMonster/MonitorMonster.csproj" `
            -c Release `
            -r win-x64 `
            --self-contained true `
            -p:PublishSingleFile=true `
            -p:IncludeNativeLibrariesForSelfExtract=true `
            -o $InstallDir
            
        Remove-Item -Recurse -Force $TempSrc -ErrorAction SilentlyContinue
    } else {
        Write-Error "Could not download pre-built binary and .NET SDK is not installed. Please install .NET 8 SDK or download from releases."
        exit 1
    }
}

# 3. Create Start Menu & Desktop Shortcuts
try {
    $WshShell = New-Object -ComObject WScript.Shell

    # Start Menu Shortcut
    $StartMenuPath = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs", "$AppName.lnk")
    $Shortcut = $WshShell.CreateShortcut($StartMenuPath)
    $Shortcut.TargetPath = $TargetExe
    $Shortcut.WorkingDirectory = $InstallDir
    $Shortcut.Description = "Living System, Wi-Fi & Battery Tray Companion"
    $Shortcut.Save()

    # Desktop Shortcut
    $DesktopPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "$AppName.lnk")
    $ShortcutDesktop = $WshShell.CreateShortcut($DesktopPath)
    $ShortcutDesktop.TargetPath = $TargetExe
    $ShortcutDesktop.WorkingDirectory = $InstallDir
    $ShortcutDesktop.Description = "Living System, Wi-Fi & Battery Tray Companion"
    $ShortcutDesktop.Save()
} catch {
    Write-Host "Warning: Could not create desktop shortcuts." -ForegroundColor DarkGray
}

# 4. Launch Application
Write-Host "==> Launching $AppName..." -ForegroundColor Green
Start-Process -FilePath $TargetExe

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "🎉 $AppName installed successfully to $InstallDir!" -ForegroundColor Green
Write-Host "   Look for the glowing monster ball in your System Tray (Taskbar Notification Area)!" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Green

