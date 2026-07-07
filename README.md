# Home Directory Portability (home-sync)

A robust, secure, and fully offline-capable system for synchronizing your Linux user home directory (`$HOME`) across multiple Debian-based client machines and a central Always-On Peer (AOP) using **Syncthing** and **Wireguard**.

## 🌟 Key Features

- **Bidirectional Mirroring**: Keeps your home directory in sync across all devices, maintaining full offline functionality and sub-second local access.
- **Connectivity-Based Sync**: Synchronization only runs when the central AOP server is reachable (e.g. over a Wireguard VPN or local network).
- **Smart Connectivity Watcher**: A systemd user service monitors AOP reachability and automatically starts/stops Syncthing to save resources and secure data.
- **Dedicated Server Storage**: The AOP stores synchronized data in an isolated, customizable directory (`/var/lib/home-sync` by default) to prevent configuration conflicts with the server's own home directory.
- **Clean Bootstrapping**: Automated client onboarding backs up existing default configuration files (e.g., `.bashrc`, `.profile`) before the initial sync to prevent conflicts.
- **Hardware Config Isolation**: Pre-configured ignore rules exclude hardware-specific files (e.g., monitor layouts) using a three-zone synchronization strategy.

---

## 📂 Project Structure

```text
├── config/
│   └── .stignore               # Syncthing pattern ignore list template
├── docs/
│   └── HOWTO.md                # Detailed step-by-step setup guide
├── openspec/
│   ├── changes/                # Historic change proposals and specs
│   └── specs/                  # Main project requirements and specifications
├── scripts/
│   ├── home-sync-watcher.sh    # Watcher script monitoring AOP connectivity
│   ├── join-cluster.sh         # Client bootstrap script for system configuration
│   └── setup-aop.sh            # Always-On Peer (AOP) installation & setup script
└── systemd/
    └── home-sync-watcher.service # Systemd unit file for the connectivity watcher
```

---

## 🚀 Getting Started

For a comprehensive guide, please refer to the [Setup Guide](docs/HOWTO.md). Here is the quick-start summary:

### 1. Always-On Peer (Server) Setup
Run the setup script on your central server/peer:
```bash
# Optional: customize data directory by setting SYNC_DIR environment variable
# Default is /var/lib/home-sync
bash scripts/setup-aop.sh
```
*Take note of the Syncthing Device ID printed at the end of the execution.*

### 2. Client Setup
Configure your Wireguard interface or network connection, then run the bootstrap script on the client machine:
```bash
AOP_ID="your-aop-device-id" AOP_IP="your-aop-ip" bash scripts/join-cluster.sh
```
*(Alternatively, run `bash scripts/join-cluster.sh` to be prompted interactively.)*

### 3. Connect Devices
Add the client's printed Device ID to the Always-On Peer's Syncthing GUI to authorize the client. That's it!

---

## 🛠️ Management & Diagnostics

### View Service Logs
Verify that the connectivity watcher and Syncthing are running correctly:
```bash
# Check the connectivity monitor service
journalctl --user -u home-sync-watcher.service -f

# Check Syncthing service
journalctl --user -u syncthing.service -f
```

### Toggle Sync Manually
If you need to manually manage the services:
```bash
systemctl --user start syncthing.service
systemctl --user stop syncthing.service
```

### Custom AOP IP Configuration
If your Always-On Peer is at a different IP address or hostname than the default (`storage.lan`), or if you are syncing directly over your LAN:
1. Create a config file at `~/.config/home-sync/watcher.env` on your client:
   ```env
   AOP_IP=your-server-ip-or-hostname
   ```
2. Reload and restart the watcher service:
   ```bash
   systemctl --user daemon-reload
   systemctl --user restart home-sync-watcher.service
   ```
