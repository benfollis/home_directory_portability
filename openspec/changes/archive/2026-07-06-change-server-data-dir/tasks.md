## 1. Implement Server Directory Setup

- [x] 1.1 Add `SYNC_DIR` configuration option to `scripts/setup-aop.sh`.
- [x] 1.2 Add steps to create the `SYNC_DIR` directory and set appropriate ownership.
- [x] 1.3 Add an inline Python script to `scripts/setup-aop.sh` to update Syncthing's `config.xml` default paths.
- [x] 1.4 Add service control steps to stop/restart the Syncthing user service during configuration.

## 2. Update Documentation

- [x] 2.1 Update `docs/HOWTO.md` to document the new default data directory on the Always-On Peer and how to customize it.
