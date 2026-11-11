# MonitorMonster for Windows 👾

A living, expressive System, Wi-Fi & Battery tray companion for Windows 10 & 11, crafted with 💜 by [itvizag](https://itvizag.com).

Sitting quietly in your **Taskbar Notification Area (System Tray)**, MonitorMonster features dynamic mood states, blinking eye expressions, and instant diagnostics for Wi-Fi signal quality, gateway/DNS latency, battery health, and Mach/Windows kernel CPU & RAM loads.

---

## ⚡ Quick Install (PowerShell)

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/mohanavamsi/monitormonster/main/install.ps1 | iex
```

This will automatically download the standalone executable, configure shortcuts, and launch the app in your system tray.

---

## 🛠️ Building from Source

### Prerequisites
- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) or later
- Windows 10 / Windows 11 (x64 or ARM64)

### Compile Standalone Executable
From the repository root:

```powershell
dotnet publish ./windows/MonitorMonster/MonitorMonster.csproj `
    -c Release `
    -r win-x64 `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -o ./dist/windows
```

The resulting `MonitorMonster.exe` is completely self-contained and requires no pre-installed .NET runtimes.

---

## 🎮 Features & Controls

- **Left-Click Tray Icon**: Toggles the glowing dark-mode Dashboard popover directly above the taskbar.
- **Right-Click Tray Icon**: Opens context menu with:
  - Open Dashboard
  - Launch on Windows Startup (`HKCU\Software\Microsoft\Windows\CurrentVersion\Run`)
  - GitHub Repository
  - About & Version info
  - Exit
- **Living Monster Expressions**:
  - `( ^ ◡ ^ )` **Happy & Snappy** (Green) — Low latency (<35ms), healthy battery & strong signal.
  - `( ˘ ᵕ ˘ )` **Cruising** (Blue) — Normal workload & stable connection.
  - `( ⊙ _ ⊙ )` **Laggy** (Orange) — High latency (>140ms) or weak Wi-Fi signal (<25%).
  - `( > ﹏ < )` **Stressed** (Red/Orange) — High CPU (>85%) or RAM load (>90%).
  - `( × _ × )` **Low Battery** (Red) — Battery under 15% on battery power.
