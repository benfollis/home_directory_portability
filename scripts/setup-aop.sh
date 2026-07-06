#!/bin/bash
# setup-aop.sh - Always-On Peer (Server) Setup

set -e

# Configuration
SYNC_DIR="${SYNC_DIR:-/var/lib/home-sync}"

echo "Starting AOP Setup..."

# 1. Install Syncthing
sudo apt update
sudo apt install -y syncthing

# 2. Create data directory
echo "Creating data directory at $SYNC_DIR..."
sudo mkdir -p "$SYNC_DIR"
sudo chown -R "$(whoami):$(whoami)" "$SYNC_DIR"

# 3. Enable Syncthing Systemd User Service
# Syncthing provides a default user service in Debian
systemctl --user enable syncthing.service
systemctl --user start syncthing.service

echo "Waiting for Syncthing to generate configuration..."
sleep 5

# Stop Syncthing temporarily to edit configuration safely
echo "Stopping Syncthing to configure data directory..."
systemctl --user stop syncthing.service

# Configure Syncthing to use the custom sync directory
echo "Configuring Syncthing data directory..."
python3 -c "
import xml.etree.ElementTree as ET
import os
import sys

config_path = os.path.expanduser('~/.config/syncthing/config.xml')
sync_dir = sys.argv[1]

if not os.path.exists(config_path):
    print(f'Config not found at {config_path}', file=sys.stderr)
    sys.exit(1)

tree = ET.parse(config_path)
root = tree.getroot()

options = root.find('options')
if options is not None:
    dfp = options.find('defaultFolderPath')
    if dfp is not None:
        dfp.text = sync_dir
    else:
        dfp = ET.SubElement(options, 'defaultFolderPath')
        dfp.text = sync_dir
else:
    options = ET.SubElement(root, 'options')
    dfp = ET.SubElement(options, 'defaultFolderPath')
    dfp.text = sync_dir

for folder in root.findall('folder'):
    if folder.get('id') == 'default':
        path = folder.find('path')
        if path is not None:
            path.text = os.path.join(sync_dir, 'Sync')

tree.write(config_path)
" "$SYNC_DIR"

# Restart Syncthing with the updated configuration
systemctl --user start syncthing.service

# 4. Get Device ID
DEVICE_ID=$(syncthing --device-id)

echo "----------------------------------------------------"
echo "AOP Setup Complete!"
echo "Your Syncthing Device ID is: $DEVICE_ID"
echo "Please save this ID to use on your client machines."
echo "----------------------------------------------------"
echo "Next steps:"
echo "1. Access the GUI at http://localhost:8384 (if local) or via SSH tunnel."
echo "2. Set a GUI password for security."
echo "3. Enable 'Simple File Versioning' in the Default Folder settings."
echo "----------------------------------------------------"
