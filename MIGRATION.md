# Migration Guide: Upgrading to Multi-User & Staggered Sync

This guide provides step-by-step instructions for upgrading a running instance of the `home-sync` system (prior to July 6th updates) to the new architecture supporting:
* **Multi-User isolation** via UNIX UIDs and offset ports.
* **Staggered File Versioning** with 7-day retention.
* **Automated local user accounts & credential synchronization**.

---

## Step 1: Update the Codebase

Pull the latest repository changes on both the **AOP server** and the **client machines**:
```bash
git pull
```

---

## Step 2: Migrate the Always-On Peer (AOP) Server

Because sync directories are now isolated per user under `/var/lib/home-sync/<username>/` and use dynamic port allocations, run these migration commands on the AOP server:

1. **Relocate existing synced data**:
   Move your existing data to the new user-isolated directory so Syncthing doesn't have to resync everything:
   ```bash
   # Create the new user-isolated directory
   sudo mkdir -p /var/lib/home-sync/$(whoami)
   
   # Move the existing 'Sync' directory into the user folder
   sudo mv /var/lib/home-sync/Sync /var/lib/home-sync/$(whoami)/ 2>/dev/null || true
   
   # Ensure correct ownership
   sudo chown -R $(whoami):$(whoami) /var/lib/home-sync/$(whoami)
   ```

2. **Re-run the setup script**:
   ```bash
   bash scripts/setup-aop.sh
   ```
   *Take note of the **Device ID** and the **Sync Port** printed at the end of the script (e.g. `22000` or a higher port if your UID is not `1000`).*

---

## Step 3: Migrate the Client Machine(s)

Re-running the bootstrap script on the client will update its XML configurations to use the new staggered versioning logic, local port offsets, and enable the path monitoring unit for credentials.

1. **Re-run the client join script**:
   ```bash
   # Provide your AOP Device ID, AOP IP, and AOP port (calculated from the AOP UID offset)
   AOP_ID="<AOP-DEVICE-ID>" AOP_IP="<AOP-IP>" AOP_PORT="<AOP-SYNC-PORT>" bash scripts/join-cluster.sh
   ```
   *(Alternatively, run `bash scripts/join-cluster.sh` and fill in the prompts interactively).*

2. **Verify services are running**:
   ```bash
   systemctl --user status syncthing.service
   systemctl --user status home-sync-watcher.service
   ```

3. **Verify the account-import path daemon**:
   Check that the systemd path unit is active and monitoring changes in `accounts.json` for your user:
   ```bash
   systemctl status "home-sync-import-accounts@$(whoami).path"
   ```

4. **Optional: Install User Apps/SDKs**:
   Because we stripped the standard app installations from the sync bootstrap, if you need to install or update base applications (Emacs, Java, Node.js, Flutter, Waterfox, Antigravity CLI), run:
   ```bash
   bash scripts/install-base-packages.sh
   ```
