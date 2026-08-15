# Moleify 🐾

> **Moleify** is a native macOS GUI application built upon and inspired by **[Mole](https://github.com/tw93/mole)** by [@tw93](https://github.com/tw93).

![Moleify App Icon](AppIcon.icns)

---

## 📜 Open Source & Attribution Notice

- **Mole Origin & License**: Mole is open source under **GPL-3.0**, see [Mole LICENSE](https://github.com/tw93/Mole/blob/main/LICENSE).
- **Compliance**: Moleify is a separate open-source macOS GUI application derived from and inspired by Mole, released under the **GNU General Public License v3.0 (GPL-3.0)**.
- **Product Distinction**: **Mole for Mac** ([mole.fit](https://mole.fit/)) is a separate, proprietary app created by tw93. **Moleify** is an independent, community-driven open-source GUI client for macOS.

---

## ✨ Key Features

- **📊 System Health Dashboard (`mo status`)**: Live Darwin Kernel telemetry (CPU core load, RAM memory breakdown, Disk I/O speeds, Network download/upload throughput, Battery status, Process list).
- **🐾 Animated Mole Cat Companion**: 60 FPS reactive animated cat mascot that changes state from resting purr to active walking and high-CPU zoomies!
- **🧹 Smart System Cleaner (`mo clean`)**: Multi-category cache scanner (System, App Caches, Logs, Xcode DerivedData/Archives, CocoaPods, SPM, Chrome/Safari/Arc caches, Trash) with **Dry Run Mode** and **Verbose Debug Logging**.
- **📦 App Uninstaller (`mo uninstall`)**: Installed application bundle inspector + deep leftover finder across `Application Support`, `Containers`, `Preferences (.plist)`, `LaunchAgents`, and `Saved Application State`.
- **🏗️ Project Purge (`mo purge`)**: One-click purge for heavy developer build artifacts (`node_modules`, `.build`, `target/` Rust, `venv` Python, `DerivedData`, `.gradle`, `.next`).
- **💾 Installer Finder (`mo installer`)**: Scans Downloads & Desktop for leftover `.dmg`, `.pkg`, `.iso` installer images.
- **📈 Disk Storage Analyzer (`mo analyze`)**: Interactive storage category distribution donut chart + top 30 largest files finder with custom path targeting (`/`, `/Volumes`, `/private/tmp`).
- **⚡ System Optimizer (`mo optimize`)**: Execute maintenance scripts (Flush DNS, Purge RAM, Rebuild LaunchServices, Re-index Spotlight, Refresh Font Caches).
- **🔑 Touch ID & CLI Utilities (`mo touchid`, `mo completion`)**: Configure Touch ID authentication for `sudo` terminal commands & install `mo` shell aliases.
- **🕒 Action History (`mo history`, `mo history --json`)**: Audit past cleaning events and export formatted JSON reports.
- **🔄 Auto Updater (`mo update`)**: Checks for official releases directly from [tw93/mole GitHub Releases](https://github.com/tw93/mole/releases).
- **🖥️ Menu Bar Live Widget**: Compact floating macOS Menu Bar Extra widget for live status monitoring.

---

## 🚀 Building & Running

### Requirements
- macOS 14.0 (Sonoma / Sequoia) or later
- Swift 6.0 toolchain & Apple Silicon (arm64)

### Build & Package Native `.app` Bundle
```bash
./scripts/build_app.sh
```

### Launch
```bash
open Moleify.app
```

---

## 📄 License

Moleify is licensed under the [GNU General Public License v3.0 (GPL-3.0)](LICENSE).
Copyright (C) 2026 Ashish Chawla & Moleify Contributors.
Derived from [Mole](https://github.com/tw93/mole) by [tw93](https://github.com/tw93).
