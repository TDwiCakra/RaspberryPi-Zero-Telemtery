# Pi MAVLink Telemetry

Digital telemetry system for UAV using **Raspberry Pi Zero 2W**, **Pixhawk**, **MAVLink Router**, **Tailscale VPN**, and **tmux** for secure remote session management.

## Table of Contents

- [Hardware Requirements](#hardware-requirements)
- [System Architecture](#system-architecture)
- [Setup Guide](#setup-guide)
  - [1. Raspberry Pi OS Setup](#1-raspberry-pi-os-setup)
  - [2. Tailscale VPN Setup](#2-tailscale-vpn-setup)
  - [3. tmux Session Setup](#3-tmux-session-setup)
  - [4. MAVLink Router Setup](#4-mavlink-router-setup)
- [Usage](#usage)
- [Configuration](#configuration)
- [Wiring Diagram](#wiring-diagram)

## Hardware Requirements

| Component | Description |
|-----------|-------------|
| Raspberry Pi Zero 2W | Main onboard computer |
| SD Card (≥32GB) | OS storage |
| Micro USB Cable | Power supply |
| USB to TTL Module | UART serial bridge |
| Pixhawk 6 | Flight controller |


## System Architecture

```
[Pixhawk 6]
    │  UART (TELEM1/TELEM2)
    ▼
[USB-to-TTL Module]
    │  USB
    ▼
[Raspberry Pi Zero 2W]
    │  Tailscale VPN (over Wi-Fi/Hotspot)
    ▼
[Internet]
    │
    ▼
[Ground Control Station (Laptop)]
 QGroundControl / Mission Planner
 Tailscale IP  →  Port 14550 UDP
```

## 🚀 Setup Guide

### 1. Raspberry Pi OS Setup

1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Flash **Raspberry Pi OS 64-bit (Recommended)** to your SD card
3. During customization, configure your Wi-Fi/hotspot credentials
4. After boot, SSH into the Pi:

```bash
ssh pi@<raspberry-pi-ip>
```

5. Update the system:

```bash
sudo apt update && sudo apt upgrade -y
```

> 💡 **Tip:** Use `hostname -I` on the Pi to find its IP address, or check your router/hotspot admin panel.

### 2. Tailscale VPN Setup

Tailscale creates a secure peer-to-peer VPN between your Pi and GCS laptop, enabling telemetry over any network.

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Bring up the VPN (follow the auth link shown in terminal)
sudo tailscale up

# Enable autostart on boot
sudo systemctl enable tailscaled
sudo systemctl start tailscaled
```

After connecting, note your Pi's Tailscale IP from the [Tailscale Admin Console](https://login.tailscale.com/admin/machines). You'll need this for MAVLink config.

### 3. tmux Session Setup

tmux keeps the telemetry session alive even if your SSH connection drops. The included script adds a password layer and supports multiple concurrent viewers.

```bash
# Install tmux
sudo apt install tmux -y

# Copy the session script
cp scripts/connect_tmux.sh ~/connect_tmux.sh
chmod +x ~/connect_tmux.sh
```

To connect to the telemetry session:

```bash
bash ~/connect_tmux.sh
```

- **First user** → becomes **ADMIN** (read/write)
- **Subsequent users** → become **VIEWER** (read-only)

### 4. MAVLink Router Setup

#### 4.1 Enable UART on Raspberry Pi

```bash
sudo raspi-config
```

Navigate to: `Interface Options` → `Serial Port`
- **Disable** login shell over serial
- **Enable** serial port hardware

Reboot after saving:

```bash
sudo reboot
```

#### 4.2 Install MAVLink Router

```bash
sudo apt update && sudo apt install git meson ninja-build -y

git clone https://github.com/mavlink-router/mavlink-router.git
cd mavlink-router

meson setup build .
ninja -C build
sudo ninja -C build install
```

#### 4.3 Configure MAVLink Router

```bash
sudo mkdir -p /etc/mavlink-router
sudo cp config/main.conf /etc/mavlink-router/main.conf
sudo nano /etc/mavlink-router/main.conf  # Edit GCS IP address
```

See [Configuration](#configuration) section for details.

#### 4.4 Enable MAVLink Router Service

```bash
sudo systemctl enable mavlink-router
sudo systemctl start mavlink-router
```

Check status:

```bash
sudo systemctl status mavlink-router
```

## 📡 Usage

1. Power on the Raspberry Pi and Pixhawk
2. Ensure both Pi and GCS laptop are connected to Tailscale
3. On GCS laptop, open **QGroundControl** or **Mission Planner**
4. Connect via **UDP**, port `14550`, using the Pi's Tailscale IP
5. Optionally SSH into Pi and run `bash ~/connect_tmux.sh` to monitor the live MAVLink session


## ⚙️ Configuration

### `config/main.conf` — MAVLink Router

```main
[General]
TcpServerPort=5760

[UartEndpoint pixhawk]
Device = /dev/ttyAMA0
Baud = 57600

[UdpEndpoint gcs]
Address = 100.x.x.x   # Replace with your GCS Tailscale IP
Port = 14550
```

> Find your GCS Tailscale IP at [Tailscale Admin Console](https://login.tailscale.com/admin/machines) or by running `tailscale ip` on your laptop.

## 🔌 Wiring Diagram

```
Pixhawk TELEM Port         USB-to-TTL Module
┌─────────────────┐        ┌──────────────────┐
│  TX  ───────────┼───────►│  RX              │
│  RX  ◄──────────┼────────┼─ TX              │
│  GND ───────────┼────────┼─ GND             │
└─────────────────┘        │  USB ────────────┼──► Raspberry Pi USB
                           └──────────────────┘
```

> ⚠️ Always connect **TX → RX** and **RX → TX** (cross-connect). Shared GND is required.

---

## 📁 Repository Structure

```
pi-mavlink-telemetry/
├── README.md               # This file
├── config/
│   └── main.conf           # MAVLink Router configuration
├── scripts/
│   └── connect_tmux.sh     # tmux session manager script
└── docs/
    └── setup-notes.md      # Additional notes and troubleshooting
```

## 📝 License

MIT License — free to use, modify, and distribute.
