## Context

Currently, `scripts/setup-aop.sh` installs and starts Syncthing on the Always-On Peer (AOP). By default, Syncthing stores its synchronized data under the user's home directory (e.g., in `~/Sync` or using `~` as the default folder path). When the AOP mirrors a client user's home directory, storing this data directly in the AOP user's home directory would lead to configuration conflicts and lack of isolation.

## Goals / Non-Goals

**Goals:**
- Store the synchronized data on the AOP in a dedicated directory outside of the user's home directory.
- By default, use `/var/lib/home-sync` as the storage directory, but allow it to be configured via the `SYNC_DIR` environment variable during setup.
- Automatically update Syncthing's XML configuration to use the dedicated directory for the default folder path and the default folder.
- Ensure the destination directory exists and has the correct permissions.
- Document this path in `docs/HOWTO.md`.

**Non-Goals:**
- Changing the Syncthing configuration directory location (`~/.config/syncthing`) or the systemd service scope (it remains a user service).
- Automatically moving existing data if the setup has already been run.
- Configuring the client machines to use a different folder structure (clients will continue to mirror the home directory directly).

## Decisions

1. **Target Directory**: Use `/var/lib/home-sync` as the default storage directory on the AOP.
   - *Rationale*: `/var/lib` is the standard Linux directory for state/data of programs. Using this directory provides proper isolation from user home directories and supports mounting a separate dedicated storage volume.
   - *Alternative*: `~/home-sync-data`. Rejected because it is still within the user's home directory, which does not achieve the goal of separating the data storage from the home directory structure.

2. **Config Modification Method**: Use an inline Python XML parser (`xml.etree.ElementTree`) script inside `scripts/setup-aop.sh` to update Syncthing's `config.xml`.
   - *Rationale*: Python and its standard `xml` module are guaranteed to be available on Debian systems. This approach is highly robust and avoids the fragility of regex-based modifications with `sed`.
   - *Alternative*: Using `sed` to edit the XML file. Rejected because XML format/whitespace can change depending on the Syncthing version, making it prone to errors.
   - *Alternative*: Using the Syncthing REST API. Rejected because it requires extracting API keys and executing curl commands, adding unnecessary complexity.

3. **Service Management During Setup**: Stop the Syncthing service, apply changes to the XML configuration file, and restart it.
   - *Rationale*: Editing the `config.xml` file while Syncthing is running can result in changes being overwritten by the daemon when it exits or writes configuration updates. Stopping the service ensures the changes are successfully applied.

## Risks / Trade-offs

- **[Risk]** The user running `setup-aop.sh` might not have `sudo` permissions to create/modify `/var/lib/home-sync`.
  - *Mitigation* → The script will use `sudo` to create the directory and chown it to the running user, and allow overriding the directory via the `SYNC_DIR` environment variable (e.g., to a path the user has write access to).
- **[Risk]** Syncthing configuration is not generated when we try to edit it.
  - *Mitigation* → Start the user service first, wait for a short duration (5 seconds) to ensure files are generated, stop the service, apply changes, and start it again.
