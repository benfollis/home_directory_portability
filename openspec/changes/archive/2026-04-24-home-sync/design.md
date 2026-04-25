## Context

The user has multiple Debian machines and wants their home directory synced seamlessly over a VPN (Wireguard) to a central server (Always-On Peer).

## Goals / Non-Goals

**Goals:**
- Implement an automated, background synchronization system.
- Ensure security via Wireguard.
- Provide a robust onboarding script for new machines.
- Support a specific suite of development and productivity applications.

**Non-Goals:**
- Creating a centralized "Master" node with its own API.
- Synchronizing hardware-specific `.config` files.
- Managing system-wide `/etc` configurations outside of what's needed for the sync engine.

## Decisions

### 1. Sync Engine: Syncthing
- **Rationale**: Built-in bidirectional sync, robust handling of many files, and native support for "ignoring" patterns. It works well over unreliable networks and provides a simple web GUI for monitoring.
- **Alternatives**: Unison (harder to automate background daemon), rsync (one-way, needs custom wrappers for bidirectional sync).

### 2. Connectivity Trigger: systemd User Services
- **Rationale**: Allows for clean integration with the user's login session. A watcher service will monitor network state and start/stop the Syncthing daemon.
- **Alternatives**: NetworkManager dispatcher scripts (can be harder to debug as they run as root and need to signal user sessions).

### 3. Star Topology (Always-On Peer)
- **Rationale**: Simplifies the sync graph. Every laptop connects to the server. The server acts as the "Hub."
- **Alternatives**: Full mesh P2P (can be noisy and harder to ensure all machines have the "latest" version if they are never online at the same time).

## Risks / Trade-offs

- **[Risk] Syncing Hot Files**: Syncing files like browser caches or active databases can cause corruption or massive churn.
  - **Mitigation**: Robust `.stignore` list to exclude high-churn directories.
- **[Risk] Conflict Resolution (LWW)**: "Last Write Wins" can lead to data loss if two machines edit the same file offline.
  - **Mitigation**: Enable Syncthing's "Simple File Versioning" on the AOP to keep a history of changed/deleted files.
- **[Risk] VPN Dependency**: If Wireguard fails, syncing stops.
  - **Mitigation**: The system is designed to be offline-first; work continues locally, and sync resumes automatically once the tunnel is restored.
