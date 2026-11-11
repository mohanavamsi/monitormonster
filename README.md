# 👾 MonitorMonster

> **Ultra-lightweight native macOS app for real-time Wi-Fi diagnostics, dual-hop latency, and MacBook battery telemetry.**  
> *Crafted with ❤️ by **[itvizag](https://itvizag.com)**.*

Built specifically for MacBooks (Apple Silicon M1/M2/M3/M4 & Intel) using native **Swift & SwiftUI**.

---

## ✨ Features

### 📶 1. Wi-Fi & Network Diagnostics
- **Live Signal Gauge (RSSI)**: Circular gauge showing real-time dBm (`-50 dBm` Excellent, `-70 dBm` Fair) with visual color grading.
- **Noise Floor & SNR**: Measures background RF noise and calculates real-time **Signal-to-Noise Ratio (SNR)**.
- **Transmit Speed (Tx Rate)**: Current link speed in Mbps (e.g. `350 Mbps` or `866 Mbps`).
- **Generation & Specs**: Identifies Wi-Fi standard (Wi-Fi 6 `802.11ax`, Wi-Fi 5 `802.11ac`), Band (`2.4 GHz`, `5 GHz`, `6 GHz`), and Channel width (`20/40/80/160 MHz`).
- **Dual-Hop Latency Diagnostics**:
  - **Router Latency (Hop 1)**: Instant round-trip ping to your home gateway.
  - **Internet Latency (Hop 2)**: Round-trip ping to Cloudflare (`1.1.1.1`).
  - **Diagnostic Verdict**: Pinpoints whether slowness is local Wi-Fi interference or your ISP.
- **Real-Time Bandwidth Meter**: Live download & upload throughput with 20-second sparkline graphs.
- **Network Configuration**: Local IPv4, Default Gateway, Subnet Mask, DNS, and BSSID (with 1-click copy).

### 🔋 2. Battery & Power Telemetry
- **Battery Ring Gauge**: Live battery % with dynamic charging animation.
- **Smart Time Remaining**: Displays estimated battery life or time to full charge.
- **Health & Longevity**:
  - **Maximum Capacity %**: True battery health (e.g., `97%`).
  - **Cycle Count**: Hardware charge cycles out of 1,000 design rating.
  - **Condition**: macOS battery condition (`Normal`).
- **🌡️ Battery Temperature**: Real-time internal pack temperature in Celsius (`°C`) with color-coded safety indicators.
- **Electrical Sensors**:
  - **Power Draw in Watts**: Live electrical discharge/charge rate.
  - **Voltage (V)** & **Current (mA)**.
  - **Power Source & Low Power Mode** indicators.

### ⚡ 3. CPU & Memory Diagnostics (Mach Kernel Powered)
- **Live CPU Ring Gauge**: Instant processor load % with color-coded states (Cool 🧊 / Normal ⚡ / Heavy 🔥).
- **Core Diagnostics**: User vs. System kernel load breakdown with active Apple Silicon / Intel core count.
- **Memory (RAM) Ring Gauge**: Live used GB / total physical memory (e.g. `5.8 / 8.0 GB`).
- **macOS Memory Pressure**: Tracks Apple's true memory pressure status (*Normal / Moderate / Critical*).
- **RAM Composition**: Transparent breakdown into App Memory, Wired kernel pages, and Compressed cache.
- **Reactive Monster Personality**: Monster expressions react dynamically when CPU exceeds 80% or memory pressure spikes!

---

## 🚀 Installation

### Option 1: One-Line Terminal Install (Recommended)
Anyone on a Mac can open Terminal and run this single command:
```bash
curl -fsSL https://raw.githubusercontent.com/mohanavamsi/monitormonster/main/install.sh | bash
```
This automatically installs `MonitorMonster.app` to `/Applications` and launches it right into your menu bar!

---

### Option 2: Homebrew Cask
If you use Homebrew:
```bash
brew install --cask mohanavamsi/monitormonster/monitormonster
```

---

### Option 3: Direct Download (.dmg)
1. Download **[MonitorMonster-1.0.0.dmg](https://github.com/mohanavamsi/monitormonster/releases/latest)**.
2. Open the `.dmg` and drag **MonitorMonster** into your **Applications** folder.

---

### Option 4: Build from Source
```bash
git clone https://github.com/mohanavamsi/monitormonster.git
cd monitormonster
./scripts/run.sh
```

---

## 🏢 About & Branding
MonitorMonster is proudly designed, crafted, and maintained by **[itvizag](https://itvizag.com)**.  
For feedback, collaborations, or enterprise tooling inquiries, visit [itvizag.com](https://itvizag.com).

