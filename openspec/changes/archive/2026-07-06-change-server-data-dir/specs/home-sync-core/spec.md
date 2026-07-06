## MODIFIED Requirements

### Requirement: Bidirectional Synchronization
The system SHALL maintain a bidirectional mirror of the user's home directory between the local machine and the Always-On Peer (AOP). On the AOP, this data SHALL be stored in a dedicated directory separate from the user's home directory.

#### Scenario: Update propagation
- **WHEN** a file is modified locally and the AOP is reachable
- **THEN** the change is pushed to the AOP and eventually to other peers
