# HOWTO: Home-Sync Setup

This guide explains how to set up the `home-sync` system across your Always-On Peer (AOP) and client machines.

## 1. Prerequisites
- All machines must be running Debian.
- Wireguard must be installed and configured on all machines.
- The AOP must have a static internal IP (e.g., `10.0.0.1`) reachable via Wireguard.

## 2. Server Setup (Always-On Peer)
1. Copy `scripts/setup-aop.sh` to your server.
2. Run it as your local user: `bash setup-aop.sh`.
   - By default, it will store synced data in `/var/lib/home-sync`.
   - You can customize the storage directory by running: `SYNC_DIR=/path/to/dir bash setup-aop.sh`.
3. The script will:
   - Install Syncthing.
   - Create the storage directory (prompting for `sudo` to set up `/var/lib/home-sync` if needed).
   - Configure a systemd user service for Syncthing.
   - Update Syncthing's configuration to use the designated storage directory instead of the user's home directory.
   - Generate your Syncthing Device ID.
4. **Manual Step**: Note the Device ID printed at the end of the script. You will need this for the clients.

## 3. Client Setup (New Machine)
1. Copy `scripts/join-cluster.sh` and the `config/.stignore` file to the new machine.
2. Ensure your `wg0.conf` is in place at `/etc/wireguard/wg0.conf` and the tunnel is up.
3. Run the join script: `bash join-cluster.sh`.
4. The script will:
   - Install core apps (Emacs, Flutter, etc.).
   - Install Syncthing and the connectivity watcher.
   - Backup your existing `.bashrc` and `.profile`.
   - Start the sync services.
5. **Manual Step**: Open the Syncthing GUI (`http://localhost:8384`) on the client and add the AOP Device ID.
6. **Manual Step**: On the AOP GUI, accept the connection from the new client.

## 4. Maintenance
- **Ignore List**: Edit `~/.stignore` to add machine-specific files you want to exclude.
- **Troubleshooting**: Check service logs with `journalctl --user -u home-sync`.
