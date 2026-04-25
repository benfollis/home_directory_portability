## ADDED Requirements

### Requirement: Core App Installation
The system SHALL ensure a specific set of core applications is installed on the machine.

#### Scenario: App installation
- **WHEN** the bootstrap script runs
- **THEN** it installs `emacs`, `thunderbird`, `openjdk-17-jdk`, `node`, `dart`, `flutter`, `android-sdk`, `waterfox`, and `antigravity`

### Requirement: Multi-Source Installation Support
The system SHALL handle different installation methods (apt, .deb, direct download).

#### Scenario: Installing a deb package
- **WHEN** the bootstrap script installs Antigravity
- **THEN** it downloads the `.deb` package and uses `apt install ./package.deb` to install it
