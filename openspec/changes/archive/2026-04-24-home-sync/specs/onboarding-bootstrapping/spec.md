## ADDED Requirements

### Requirement: Semi-Automated Join Script
The system SHALL provide a `join-cluster.sh` script to automate the initial configuration of a new node.

#### Scenario: Script execution
- **WHEN** `join-cluster.sh` is run on a fresh Debian install
- **THEN** it installs Wireguard and the sync engine, and configures them with pre-shared identities

### Requirement: Conflict-Free Initial Sync
The system SHALL move existing default Debian home directory files to a backup location before the first sync.

#### Scenario: First run backup
- **WHEN** the sync is initialized for the first time
- **THEN** `.bashrc` and `.profile` are renamed to `.bashrc.bak` and `.profile.bak` if they exist
