#!/usr/bin/env python3
# import-accounts.py - Import user accounts and groups from JSON file

import json
import pwd
import grp
import subprocess
import sys
import os

def main():
    if len(sys.argv) < 2:
        print("Usage: import-accounts.py <path-to-accounts.json>", file=sys.stderr)
        sys.exit(1)

    input_file = sys.argv[1]
    if not os.path.exists(input_file):
        print(f"Error: File {input_file} does not exist.", file=sys.stderr)
        sys.exit(1)

    # Read database
    with open(input_file, 'r') as f:
        data = json.load(f)

    # 1. Sync Groups
    for g_info in data.get('groups', []):
        groupname = g_info['groupname']
        gid = g_info['gid']
        
        try:
            g = grp.getgrnam(groupname)
            # Group exists, check GID
            if g.gr_gid != gid:
                print(f"Updating GID for group {groupname} to {gid}...")
                subprocess.run(['groupmod', '-g', str(gid), groupname], check=True)
        except KeyError:
            # Group does not exist, create it
            print(f"Creating group {groupname} with GID {gid}...")
            subprocess.run(['groupadd', '-g', str(gid), groupname], check=True)

    # 2. Sync Users
    for u_info in data.get('users', []):
        username = u_info['username']
        uid = u_info['uid']
        gid = u_info['gid']
        gecos = u_info['gecos']
        home = u_info['home']
        shell = u_info['shell']
        pw_hash = u_info['password_hash']

        try:
            u = pwd.getpwnam(username)
            # User exists, check and update details
            if u.pw_uid != uid or u.pw_gid != gid or u.pw_shell != shell or u.pw_gecos != gecos:
                print(f"Updating user details for {username}...")
                # We do not modify the home directory path directly to avoid breaking things, but shell and gecos are fine
                subprocess.run(['usermod', '-u', str(uid), '-g', str(gid), '-s', shell, '-c', gecos, username], check=True)
        except KeyError:
            # User does not exist, create it
            print(f"Creating user {username} (UID: {uid}, GID: {gid})...")
            # We do NOT create the home directory (-M) since Syncthing handles creating and syncing the home directory files
            subprocess.run(['useradd', '-u', str(uid), '-g', str(gid), '-c', gecos, '-d', home, '-s', shell, '-M', username], check=True)

        # Sync password hash using chpasswd -e
        if pw_hash and pw_hash not in ('*', '!'):
            try:
                # Fetch current shadow hash to check if different
                import spwd
                try:
                    s = spwd.getspnam(username)
                    current_hash = s.sp_pwd
                except KeyError:
                    current_hash = None
            except (ImportError, AttributeError):
                # Fallback if spwd is deprecated/missing: read /etc/shadow directly
                current_hash = None
                if os.path.exists('/etc/shadow'):
                    with open('/etc/shadow', 'r') as sf:
                        for sline in sf:
                            sparts = sline.strip().split(':')
                            if sparts[0] == username and len(sparts) >= 2:
                                current_hash = sparts[1]
                                break

            if pw_hash != current_hash:
                print(f"Updating password hash for {username}...")
                proc = subprocess.Popen(['chpasswd', '-e'], stdin=subprocess.PIPE, text=True)
                proc.communicate(input=f"{username}:{pw_hash}\n")

    # 3. Sync supplementary groups
    for g_info in data.get('groups', []):
        groupname = g_info['groupname']
        members = g_info['members']
        
        # Verify members exist on the system before trying to add them
        valid_members = []
        for m in members:
            try:
                pwd.getpwnam(m)
                valid_members.append(m)
            except KeyError:
                pass
        
        try:
            print(f"Setting members of group {groupname} to: {', '.join(valid_members)}")
            subprocess.run(['gpasswd', '-M', ','.join(valid_members), groupname], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error setting group members for {groupname}: {e}", file=sys.stderr)

    print("Account import completed successfully.")

if __name__ == '__main__':
    main()
