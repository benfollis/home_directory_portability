## Purpose
Define the core requirements for the bidirectional synchronization of the user home directory between local machines and the Always-On Peer (AOP).
## Requirements
### Requirement: Bidirectional Synchronization
The system SHALL maintain a bidirectional mirror of the user's home directory between the local machine and the Always-On Peer (AOP). On the AOP, this data SHALL be stored in a dedicated directory separate from the user's home directory.

#### Scenario: Update propagation
- **WHEN** a file is modified locally and the AOP is reachable
- **THEN** the change is pushed to the AOP and eventually to other peers

### Requirement: Network Reachability Check
The system SHALL only attempt to synchronize when the AOP is reachable.

#### Scenario: Sync when AOP reachable
- **WHEN** the AOP (storage.lan) responds to pings
- **THEN** the synchronization daemon is started/resumed

#### Scenario: Pause when AOP unreachable
- **WHEN** the AOP (storage.lan) does not respond to pings
- **THEN** the synchronization daemon is paused immediately

### Requirement: Data Segmentation (Three-Zone Strategy)
The system SHALL strictly follow an ignore list to prevent syncing hardware-specific configurations.

#### Scenario: Hardware config ignore
- **WHEN** a change occurs in `.config/monitors.xml`
- **THEN** the file is NOT synchronized to the AOP

