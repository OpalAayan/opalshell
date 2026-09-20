# opalshell

> A sleek, modular, lightweight Wayland status bar built with [QuickShell](https://quickshell.outfoxxed.me/) for Hyprland and MangoWM.

---

## ✨ Features

- **Blazing Fast**: Backed by optimized C binaries (`sysbridge`, `bt_status`, `wifi_status`, `eth_status`) communicating via JSON over stdout.
- **Dynamic Hyprland Workspaces**: Auto-detects multi-monitor setups and routes workspaces dynamically with urgency and active state indicators.
- **Unified Network & Bluetooth Panel**: Interactive Catppuccin Mocha popover combining Ethernet, Wi-Fi networks, and Bluetooth device pairing/connecting.
- **Hardware & System Metrics**: Real-time CPU, Memory, Disk, Temperature, and Battery monitoring with dynamic color thresholds and alerts.
- **Interactive Controls**:
  - **Brightness & Volume**: Scroll-wheel adjustment with notifications and throttled responsiveness.
  - **Night Light**: Quick toggle & color temperature cycling via `wl-gammarelay-rs`.
  - **Date & Calendar**: Beautiful dropdown calendar grid.
- **Self-Contained & Modular**: Zero hardcoded dotfile paths. Assets and scripts resolve dynamically relative to install prefix or repo directory.
- **UNIX Philosophy**: Runs in the foreground by default with live logs (`Ctrl+C` to quit), or in the background with `-d / --daemon`.

---

## 📦 Dependencies

### Core Runtime
- **[quickshell](https://quickshell.outfoxxed.me/)** (>= 0.3.1)
- **qt6-declarative**, **qt6-wayland**
- **networkmanager** (`nmcli`) & **bluez** / **bluez-utils** (`bluetoothctl`)
- **wireplumber** (`wpctl`)
- **brightnessctl**
- **kitty** & **btop**
- **dunst** / **libnotify** (`dunstify` or `notify-send`)

### Build Dependencies
- **gcc** or **clang**
- **make**
- **pkg-config**
- **libnm** (NetworkManager client library & headers)
- **dbus** (`dbus-1` headers)

### Typography
- `ttf-jetbrains-mono-nerd`
- `ttf-rubik`

### Arch Linux One-Liner
```bash
sudo pacman -S --needed quickshell gcc make pkgconf libnm dbus brightnessctl wireplumber networkmanager bluez bluez-utils kitty btop libnotify ttf-jetbrains-mono-nerd ttf-rubik
```

---

## 🚀 Quick Start

### 1. Clone & Build
```bash
git clone https://github.com/OpalAayan/opalshell.git
cd opalshell
make
```

Verify your environment anytime:
```bash
./bin/opalshell --check-deps
```

### 2. Install

**System-wide (default, requires sudo):**
```bash
sudo make install
```

**User-local (no root required):**
```bash
make install PREFIX=$HOME/.local
```

### 3. Run

```bash
# Run in foreground (the Linux way — logs stream to terminal, Ctrl+C exits)
opalshell

# Run in background (daemonized)
opalshell -d

# Restart the bar
opalshell -r

# Check running status
opalshell -s

# Stop the bar
opalshell -k

# View live logs
opalshell -l
```

---

## 🖥️ Hyprland Integration

Add this line to your `~/.config/hypr/hyprland.conf`:

```ini
exec-once = opalshell -d
```

---

## ⚙️ Configuration (Coming Soon)

`opalshell` comes with a template configuration:
```bash
mkdir -p ~/.config/opalshell
cp config/config.ini.example ~/.config/opalshell/config.ini
```

Customization for bar dimensions, module orders, fonts, and Catppuccin color variants will be supported in upcoming releases.

---

## 🗑️ Uninstallation

```bash
sudo make uninstall
# or if installed locally:
make uninstall PREFIX=$HOME/.local
```

*(Your personal settings in `~/.config/opalshell/` will never be touched during uninstall.)*

---

## 📄 License

GPL-3.0 © 2025-2026 OpalAayan
