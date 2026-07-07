#!/usr/bin/env python3
# export-accounts.py - Export user accounts and groups to JSON

import json
import pwd
import grp
import os
import sys

def main():
    # Only root can read password hashes from /etc/shadow
    shadow_db = {}
    try:
        with open('/etc/shadow', 'r') as f:
            for line in f:
                parts = line.strip().split(':')
                if len(parts) >= 2:
                    shadow_db[parts[0]] = parts[1]
    except PermissionError:
        print("Warning: Cannot read /etc/shadow. Run as root to export password hashes.", file=sys.stderr)

    # Extract users (UID >= 1000, excluding nobody)
    users = []
    for p in pwd.getpwall():
        if 1000 <= p.pw_uid < 60000:
            pw_hash = shadow_db.get(p.pw_name, '*')
            users.append({
                'username': p.pw_name,
                'uid': p.pw_uid,
                'gid': p.pw_gid,
                'gecos': p.pw_gecos,
                'home': p.pw_dir,
                'shell': p.pw_shell,
                'password_hash': pw_hash
            })

    # Extract groups (GID >= 1000)
    groups = []
    for g in grp.getgrall():
        if 1000 <= g.gr_gid < 60000:
            groups.append({
                'groupname': g.gr_name,
                'gid': g.gr_gid,
                'members': g.gr_mem
            })

    data = {
        'users': users,
        'groups': groups
    }

    # Write output to files in each user's sync config folder
    # On the AOP, the sync dirs are located under /var/lib/home-sync/<username>
    base_sync_dir = '/var/lib/home-sync'
    if os.path.exists(base_sync_dir):
        for user_dir in os.listdir(base_sync_dir):
            user_path = os.path.join(base_sync_dir, user_dir)
            if os.path.isdir(user_path):
                # Write to the user's config folder
                config_dir = os.path.join(user_path, '.config', 'home-sync')
                os.makedirs(config_dir, exist_ok=True)
                
                output_file = os.path.join(config_dir, 'accounts.json')
                with open(output_file, 'w') as f:
                    json.dump(data, f, indent=2)
                
                # Set ownership of the config directory and file to the user
                try:
                    uid = pwd.getpwnam(user_dir).pw_uid
                    gid = grp.getgrnam(user_dir).gr_gid
                    os.chown(output_file, uid, gid)
                    os.chmod(output_file, 0o600)  # Contains sensitive hashes
                except KeyError:
                    pass

    print("Account export completed successfully.")

if __name__ == '__main__':
    main()
