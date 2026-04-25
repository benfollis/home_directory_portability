## Why

I need a way to synchronize my large home directory across multiple Debian-based computers while maintaining full offline functionality. Existing solutions like standard NFS or cloud-only sync are insufficient due to high latency or lack of robust offline support.

## What Changes

- Implementation of a background synchronization daemon (Syncthing) that mirrors the home directory to an "Always-On Peer" (AOP).
- Integration with Wireguard to ensure synchronization only occurs over a secure, home-network-connected tunnel.
- Creation of a semi-automated onboarding script (`join-cluster.sh`) to provision new machines with core applications and sync settings.
- Configuration of a "three-zone" data strategy (Sync, Ignore, Strict Ignore) to handle hardware-specific configuration differences.

## Capabilities

### New Capabilities
- `home-sync-core`: The bidirectional synchronization engine and connectivity logic.
- `onboarding-bootstrapping`: Automated provisioning of new machines into the cluster.
- `application-provisioning`: Management of the core application suite (Emacs, Flutter, Android, etc.).

### Modified Capabilities
- None

## Impact

- **Affected Systems**: User's home directory (`$HOME`), network management (Wireguard), and system initialization (systemd).
- **Dependencies**: `syncthing`, `wireguard-tools`, `systemd`.
- **Operating System**: Debian-based Linux distributions.
