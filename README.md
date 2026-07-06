# Home Directory Portability (home-sync)

A robust, secure, and fully offline-capable system for synchronizing your Linux user home directory (`$HOME`) across multiple Debian-based client machines and a central Always-On Peer (AOP) using **Syncthing** and **Wireguard**.

## 🌟 Key Features

- **Bidirectional Mirroring**: Keeps your home directory in sync across all devices, maintaining full offline functionality and sub-second local access.
- **VPN-Enforced Security**: Synchronization only runs when connected to the secure Wireguard VPN (`wg0`) and the central AOP server is reachable.
- **Smart Connectivity Watcher**: A systemd user service monitors network connectivity and automatically starts/stops Syncthing to save resources and secure data.
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
│   ├── home-sync-watcher.sh    # Watcher script monitoring VPN & AOP connectivity
│   ├── join-cluster.sh         # Client bootstrap script for system configuration
│   └── setup-aop.sh            # Always-On Peer (AOP) installation & setup script
└── systemd/
    └── home-sync-watcher.service # Systemd unit file for the connectivity watcher
```

---

## 🚀 Getting Started

For a comprehensive guide, please refer to the [Setup Guide](file:///home/kage/Documents/repos/home_directory_portability/docs/HOWTO.md). Here is the quick-start summary:

### 1. Always-On Peer (Server) Setup
Run the setup script on your central server/peer:
```bash
# Optional: customize data directory by setting SYNC_DIR environment variable
# Default is /var/lib/home-sync
bash scripts/setup-aop.sh
```
*Take note of the Syncthing Device ID printed at the end of the execution.*

### 2. Client Setup
Configure your Wireguard interface (`/etc/wireguard/wg0.conf`), ensure the tunnel is active, and run the bootstrap script on the client machine:
```bash
bash scripts/join-cluster.sh
```

### 3. Connect Devices
1. Access the Syncthing Web UI at `http://localhost:8384` on your client.
2. Add the Always-On Peer's Device ID.
3. Accept the connection and folder sharing request on the AOP's Web UI.

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
