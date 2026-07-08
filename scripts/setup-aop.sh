#!/bin/bash
# setup-aop.sh - Always-On Peer (Server) Setup

set -e

# Get the directory of the script and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"


# Configuration
UID_OFFSET=$(($(id -u) - 1000))
if [ "$UID_OFFSET" -lt 0 ]; then
    UID_OFFSET=0
fi
GUI_PORT=$((8384 + UID_OFFSET))
SYNC_PORT=$((22000 + UID_OFFSET))

SYNC_DIR="${SYNC_DIR:-/var/lib/home-sync/$(whoami)}"
GUI_ADDRESS="${GUI_ADDRESS:-0.0.0.0:${GUI_PORT}}"

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
sync_port = sys.argv[3]

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

# Set custom sync protocol port listen addresses
for la in options.findall('listenAddress'):
    options.remove(la)
la_tcp = ET.SubElement(options, 'listenAddress')
la_tcp.text = f'tcp://0.0.0.0:{sync_port}'
la_quic = ET.SubElement(options, 'listenAddress')
la_quic.text = f'quic://0.0.0.0:{sync_port}'

for folder in root.findall('folder'):
    if folder.get('id') == 'default':
        target_folder_path = os.path.join(sync_dir, 'Sync')
        if 'path' in folder.attrib:
            folder.set('path', target_folder_path)
        path_el = folder.find('path')
        if path_el is not None:
            path_el.text = target_folder_path

        # Configure file versioning (staggered with maxAge=604800 seconds / 7 days)
        fv = folder.find('versioning')
        if fv is None:
            old_fv = folder.find('fileVersioning')
            if old_fv is not None:
                folder.remove(old_fv)
            fv = ET.SubElement(folder, 'versioning')

        fv.set('type', 'staggered')
        cleanup_interval = fv.find('cleanupIntervalS')
        if cleanup_interval is None:
            cleanup_interval = ET.SubElement(fv, 'cleanupIntervalS')
        cleanup_interval.text = '3600'

        # Remove cleanoutDays if present from previous runs
        for p in fv.findall('param'):
            if p.get('key') == 'cleanoutDays':
                fv.remove(p)

        max_age_param = None
        for p in fv.findall('param'):
            if p.get('key') == 'maxAge':
                max_age_param = p
                break
        if max_age_param is not None:
            max_age_param.set('val', '604800')
        else:
            ET.SubElement(fv, 'param', {'key': 'maxAge', 'val': '604800'})

gui = root.find('gui')
if gui is not None:
    address = gui.find('address')
    if address is not None:
        address.text = gui_address
    else:
        address = ET.SubElement(gui, 'address')
        address.text = gui_address

tree.write(config_path)
" "$SYNC_DIR" "$GUI_ADDRESS" "$SYNC_PORT"

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

# 5. Setup Account Synchronization Services (Export)
echo "Installing user account export services..."
sudo cp "$SCRIPT_DIR/export-accounts.py" /usr/local/sbin/home-sync-export-accounts.py
sudo chmod +x /usr/local/sbin/home-sync-export-accounts.py
sudo cp "$REPO_DIR/systemd/system-services/home-sync-export-accounts.service" /etc/systemd/system/
sudo cp "$REPO_DIR/systemd/system-services/home-sync-export-accounts.timer" /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now home-sync-export-accounts.timer
sudo systemctl start home-sync-export-accounts.service || true

# 6. Get Device ID
DEVICE_ID=$(syncthing --device-id)

echo "----------------------------------------------------"
echo "AOP Setup Complete!"
echo "Your Syncthing Device ID is: $DEVICE_ID"
echo "Your Syncthing Sync Port is: $SYNC_PORT"
echo "Please save this ID and Sync Port to use on your client machines."
echo "----------------------------------------------------"
echo "Next steps:"
echo "1. Access the GUI at http://localhost:8384 (if local) or via SSH tunnel."
echo "2. Set a GUI password for security."
echo "----------------------------------------------------"
