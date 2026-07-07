#!/bin/bash
# setup-aop.sh - Always-On Peer (Server) Setup

set -e

# Configuration
SYNC_DIR="${SYNC_DIR:-/var/lib/home-sync}"
GUI_ADDRESS="${GUI_ADDRESS:-0.0.0.0:8384}"

echo "Starting AOP Setup..."

# 1. Install Syncthing
sudo apt update
sudo apt install -y syncthing

# 2. Create data directory
echo "Creating data directory at $SYNC_DIR..."
sudo mkdir -p "$SYNC_DIR"
sudo chown -R "$(whoami):$(whoami)" "$SYNC_DIR"

# 3. Generate Syncthing Configuration
echo "Generating Syncthing configuration..."
syncthing generate

# Configure Syncthing to use the custom sync directory and GUI address
echo "Configuring Syncthing data directory and GUI..."
python3 -c "
import xml.etree.ElementTree as ET
import os
import sys

sync_dir = sys.argv[1]
gui_address = sys.argv[2]

possible_paths = [
    os.path.expanduser('~/.config/syncthing/config.xml'),
    os.path.expanduser('~/.local/state/syncthing/config.xml')
]

# Fallback recursive search if not found in standard locations
if not any(os.path.exists(p) for p in possible_paths):
    for root_dir in ['~/.config', '~/.local', '~/']:
        expanded = os.path.expanduser(root_dir)
        if os.path.exists(expanded):
            for root, dirs, files in os.walk(expanded):
                if 'config.xml' in files and 'syncthing' in root.lower():
                    possible_paths.append(os.path.join(root, 'config.xml'))

config_path = None
for path in possible_paths:
    if os.path.exists(path):
        config_path = path
        break

if not config_path:
    print(f'Config file not found in expected locations: {possible_paths}', file=sys.stderr)
    print('Please check if the syncthing generate command ran successfully.', file=sys.stderr)
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
        target_folder_path = os.path.join(sync_dir, 'Sync')
        if 'path' in folder.attrib:
            folder.set('path', target_folder_path)
        path_el = folder.find('path')
        if path_el is not None:
            path_el.text = target_folder_path

gui = root.find('gui')
if gui is not None:
    address = gui.find('address')
    if address is not None:
        address.text = gui_address
    else:
        address = ET.SubElement(gui, 'address')
        address.text = gui_address

tree.write(config_path)
" "$SYNC_DIR" "$GUI_ADDRESS"

# 4. Enable and Start Syncthing Systemd User Service
# Ensure user manager is running by enabling linger
if command -v loginctl >/dev/null 2>&1; then
    echo "Enabling user linger to ensure services persist..."
    sudo loginctl enable-linger "$(whoami)" || true
fi

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
systemctl --user daemon-reload || true
systemctl --user enable syncthing.service
systemctl --user restart syncthing.service

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
