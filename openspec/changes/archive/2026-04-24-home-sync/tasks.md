## 1. Core Sync Setup

- [x] 1.1 Install and configure Syncthing on the Always-On Peer (AOP)
- [x] 1.2 Define the global `.stignore` file with the Three-Zone data strategy
- [x] 1.3 Configure Syncthing "Simple File Versioning" on the AOP

## 2. Connectivity & Automation

- [x] 2.1 Create the `home-sync-watcher.sh` script to check Wireguard and ping AOP
- [x] 2.2 Create the `home-sync.service` and `home-sync.timer` systemd user units
- [x] 2.3 Test the auto-resume/pause logic by toggling Wireguard

## 3. Onboarding & Provisioning

- [x] 3.1 Create the `join-cluster.sh` bootstrap script
- [x] 3.2 Implement core application installation logic in the script (Apt, .deb, SDKs)
- [x] 3.3 Implement the "Home Cleaning" logic (backing up .bashrc, etc.)
- [x] 3.4 Implement the initial Syncthing identity provisioning and pull logic

## 4. Verification & Testing

- [x] 4.1 Verify end-to-end sync between two test nodes
- [x] 4.2 Verify "Strict Ignore" patterns prevent hardware config leakage
- [x] 4.3 Verify application installation on a fresh Debian test environment
