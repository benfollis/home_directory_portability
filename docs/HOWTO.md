# HOWTO: Home-Sync Setup

This guide explains how to set up the `home-sync` system across your Always-On Peer (AOP) and client machines.

## 1. Prerequisites
- All machines must be running Debian.
- Wireguard must be installed and configured on all machines.
- The AOP must have a hostname (e.g., `storage.lan`) resolvable on the network/Wireguard.

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
2. Ensure your Wireguard tunnel is up or AOP is reachable.
3. Run the join script by providing the AOP Device ID and IP address:
   ```bash
   AOP_ID="<AOP-DEVICE-ID>" AOP_IP="<AOP-IP>" bash join-cluster.sh
   ```
   *(Alternatively, you can run `bash join-cluster.sh` and you will be interactively prompted for these values.)*
4. The script will:
   - Install core apps (Emacs, Flutter, etc.).
   - Install and configure Syncthing.
   - Automatically configure and associate the default folder with the AOP.
   - Set up and start the connectivity watcher (`home-sync-watcher.service`).
   - Backup your existing `.bashrc` and `.profile`.
   - Print the new client's Device ID.
5. **Manual Step**: Add the printed client Device ID to your Always-On Peer (AOP) GUI to establish the trust relationship and begin syncing.

## 4. Maintenance
- **Ignore List**: Edit `~/.stignore` to add machine-specific files you want to exclude.
- **Troubleshooting**: Check service logs with `journalctl --user -u home-sync-watcher.service`.

### Custom AOP IP Configuration
If your Always-On Peer is at a different IP address or hostname than the default (`storage.lan`), or if you are syncing directly over your LAN:
1. Create a config directory and file at `~/.config/home-sync/watcher.env` on the client:
   ```env
   AOP_IP=your-server-ip-or-hostname
   ```
2. Reload and restart the watcher service:
   ```bash
   systemctl --user daemon-reload
   systemctl --user restart home-sync-watcher.service
   ```
