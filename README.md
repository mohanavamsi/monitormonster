# 👾 MonitorMonster

> **Ultra-lightweight native macOS app for real-time Wi-Fi diagnostics, dual-hop latency, and MacBook battery telemetry.**

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

---

## 🚀 Quick Start

### Build & Run
```bash
./scripts/run.sh
```

MonitorMonster runs with:
1. **A Floating Desktop Window** centered on your screen with a macOS Dock icon.
2. **A Menu Bar Extra** at the top right of your screen.
