## Why

Storing the synchronized home directory data directly in the home directory on the Always-On Peer (AOP) creates conflicts with the AOP server's own user configuration and settings. Moving this to a dedicated directory outside the home directory prevents these conflicts and allows cleaner isolation of the synchronized data.

## What Changes

- Modify `scripts/setup-aop.sh` to configure the synced folder path to a dedicated directory (defaulting to `/var/lib/home-sync`) rather than the user's home directory.
- Add configuration steps to `scripts/setup-aop.sh` to initialize the directory with correct permissions and configure Syncthing to use it.
- Update documentation in `docs/HOWTO.md` to reflect the server-side data directory change.

## Capabilities

### New Capabilities

<!-- None -->

### Modified Capabilities

- `home-sync-core`: The requirement to maintain a bidirectional mirror must specify that on the Always-On Peer, the data is stored in a dedicated, configurable directory separate from the peer's home directory.

## Impact

- `scripts/setup-aop.sh` will create a new directory (e.g. `/var/lib/home-sync`) and assign ownership to the running user.
- Syncthing configuration on the Always-On Peer will map the synchronized home directory folder to this dedicated path.
- Documentation `docs/HOWTO.md` will reference this directory path.
