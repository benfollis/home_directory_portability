## Purpose
Define the core requirements for the bidirectional synchronization of the user home directory between local machines and the Always-On Peer (AOP).
## Requirements
### Requirement: Bidirectional Synchronization
The system SHALL maintain a bidirectional mirror of the user's home directory between the local machine and the Always-On Peer (AOP). 

On the AOP, the synced data SHALL be isolated per-user in a dedicated subdirectory (`/var/lib/home-sync/<username>`).

To support concurrent multi-user execution on the same machine without port conflicts, Syncthing's GUI and Sync ports SHALL be calculated dynamically based on the user's UNIX User ID (`UID`) offset.

#### Scenario: Update propagation
- **WHEN** a file is modified locally and the AOP is reachable
- **THEN** the change is pushed to the user's isolated AOP storage directory and eventually to other peers

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

### Requirement: Deleted & Modified File Protection (Staggered Versioning)
The system SHALL keep historical versions of files deleted or replaced on any node using Staggered File Versioning, keeping snapshots for a maximum age of 7 days before purging them.

#### Scenario: File deletion or modification on a peer
- **WHEN** a file is deleted or modified on a peer machine
- **THEN** it is moved to the `.stversions` folder on the other nodes, kept as part of a staggered history for up to 7 days, and then permanently deleted

### Requirement: Account and Credential Synchronization
The system SHALL synchronize user accounts, group memberships, and password credentials across all nodes in the cluster.

#### Scenario: Synced account database update
- **WHEN** user account settings are updated on the AOP
- **THEN** the changes are exported to a secure JSON file, synced to clients via Syncthing, and automatically applied to the local UNIX account database on client machines

