# 👾 MonitorMonster

> **Ultra-lightweight native companion for real-time Wi-Fi diagnostics, dual-hop latency, battery telemetry, and CPU/RAM monitoring.**  
> *Crafted with 💜 by **[itvizag](https://itvizag.com)** for macOS (Menu Bar) and Windows (System Tray).*

Available natively for **macOS** (Apple Silicon & Intel) and **Windows 10 / 11** (x64 & ARM64).

---

## ✨ Features

### 📶 1. Wi-Fi & Network Diagnostics
- **Live Signal Gauge (RSSI)**: Circular gauge showing real-time dBm (`-50 dBm` Excellent, `-70 dBm` Fair) with visual color grading.
- **Noise Floor & SNR**: Measures background RF noise and calculates real-time **Signal-to-Noise Ratio (SNR)**.
- **Transmit Speed (Tx Rate)**: Current link speed in Mbps (e.g. `350 Mbps` or `866 Mbps`).
- **Generation & Specs**: Identifies Wi-Fi standard (Wi-Fi 6 `802.11ax`, Wi-Fi 5 `802.11ac`), Band (`2.4 GHz`, `5 GHz`, `6 GHz`), and Channel width (`20/40/80/160 MHz`).
- **Dual-Hop Latency Diagnostics**:
  - **Router Latency (Hop 1)**: Instant round-trip ping to your local gateway.
  - **Internet Latency (Hop 2)**: Round-trip ping to primary DNS (`8.8.8.8` / `1.1.1.1`).
  - **Diagnostic Verdict**: Pinpoints whether slowness is local Wi-Fi interference or your ISP.
- **Real-Time Bandwidth Meter**: Live download & upload throughput with active sparkline graphs.
- **Network Configuration**: Local IPv4, Default Gateway, Subnet Mask, DNS, and BSSID.

### 🔋 2. Battery & Power Telemetry
- **Battery Ring Gauge**: Live battery % with dynamic charging animation.
- **Smart Time Remaining**: Displays estimated battery life or time to full charge.
- **Health & Longevity**: True battery health %, cycle counts, and condition indicators.
- **🌡️ Battery Temperature**: Real-time internal pack temperature in Celsius (`°C`).
- **Electrical Sensors**: Power draw in watts, live discharge/charge rates, voltage, and current.

### ⚡ 3. CPU & Memory Diagnostics
- **Live CPU Gauge**: Instant processor load % with color-coded states (Cool 🧊 / Normal ⚡ / Heavy 🔥).
- **Core Diagnostics**: User vs. System kernel load breakdown.
- **Memory (RAM) Gauge**: Live used GB / total physical memory.
- **Reactive Monster Personality**: Monster expressions react dynamically with blinking eyes and changing mood states when latency spikes, battery drops, or CPU exceeds heavy thresholds!

---

## 🚀 Installation

### 🍎 macOS Installation

#### Option 1: One-Line Terminal Install (Recommended)
Open Terminal and run:
```bash
curl -fsSL https://raw.githubusercontent.com/mohanavamsi/monitormonster/main/install.sh | bash
```
Installs `MonitorMonster.app` directly into `/Applications` and launches it into your menu bar!

#### Option 2: Direct Download (.dmg)
1. Download **[MonitorMonster-1.0.3.dmg](https://github.com/mohanavamsi/monitormonster/releases/latest)**.
2. Open the `.dmg` and drag **MonitorMonster** into your **Applications** folder.

#### Option 3: Homebrew Cask
```bash
brew install --cask mohanavamsi/monitormonster/monitormonster
```

---

### 🪟 Windows Installation

#### Option 1: One-Line PowerShell Install (Recommended)
Open **PowerShell** and run:
```powershell
irm https://raw.githubusercontent.com/mohanavamsi/monitormonster/main/install.ps1 | iex
```
This automatically sets up `MonitorMonster.exe` in your local app data, creates Desktop/Start Menu shortcuts, and launches the app directly into your **System Tray (Taskbar Notification Area)**!

#### Option 2: Direct Download (.exe)
1. Download the standalone executable from **[GitHub Releases](https://github.com/mohanavamsi/monitormonster/releases/latest)**.
2. Run `MonitorMonster.exe` directly (no installer or runtime setup needed).

#### Option 3: Build from Source (.NET 8)
```powershell
git clone https://github.com/mohanavamsi/monitormonster.git
cd monitormonster
dotnet publish ./windows/MonitorMonster/MonitorMonster.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o ./dist/windows
```
*For complete Windows architecture and documentation, see [windows/README.md](windows/README.md).*

---

## 🏢 About & Branding
MonitorMonster is proudly designed, crafted, and maintained by **[itvizag](https://itvizag.com)**.  
For feedback, collaborations, or enterprise tooling inquiries, visit [itvizag.com](https://itvizag.com).

