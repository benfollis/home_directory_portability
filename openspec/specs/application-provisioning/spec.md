## ADDED Requirements

### Requirement: Core App Installation
The system SHALL ensure a specific set of core applications is installed on the machine.

#### Scenario: App installation
- **WHEN** the bootstrap script runs
- **THEN** it installs `emacs`, `thunderbird`, `openjdk-17-jdk`, `node`, `dart`, `flutter`, `android-sdk`, `waterfox`, and `antigravity`

### Requirement: Extra Repository Configuration
The system SHALL configure external repositories for packages not present in default Debian repositories (e.g., Waterfox).

#### Scenario: Registering package repositories
- **WHEN** the installer script runs
- **THEN** it registers the repositories and installs the software using `apt`

### Requirement: Curl-Based CLI Installation
The system SHALL support installing command line tools via official installation scripts (e.g., Antigravity CLI).

#### Scenario: Installing Antigravity CLI
- **WHEN** the installer script runs
- **THEN** it downloads and executes the installer script using `curl`
