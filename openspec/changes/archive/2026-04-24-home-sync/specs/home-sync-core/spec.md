## ADDED Requirements

### Requirement: Bidirectional Synchronization
The system SHALL maintain a bidirectional mirror of the user's home directory between the local machine and the Always-On Peer (AOP).

#### Scenario: Update propagation
- **WHEN** a file is modified locally and the AOP is reachable
- **THEN** the change is pushed to the AOP and eventually to other peers

### Requirement: Network Reachability Check
The system SHALL only attempt to synchronize when the Wireguard interface is active and the AOP's internal IP is pingable.

#### Scenario: Sync on home network
- **WHEN** the `wg0` interface is UP and the AOP (10.0.0.1) responds to pings
- **THEN** the synchronization daemon is started/resumed

#### Scenario: Pause on public network
- **WHEN** the `wg0` interface is DOWN
- **THEN** the synchronization daemon is paused immediately

### Requirement: Data Segmentation (Three-Zone Strategy)
The system SHALL strictly follow an ignore list to prevent syncing hardware-specific configurations.

#### Scenario: Hardware config ignore
- **WHEN** a change occurs in `.config/monitors.xml`
- **THEN** the file is NOT synchronized to the AOP
