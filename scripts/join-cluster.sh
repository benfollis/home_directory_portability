#!/bin/bash
# join-cluster.sh - Client Machine Bootstrap Script

set -e

# Parse arguments or prompt if not set
while [[ $# -gt 0 ]]; do
    case $1 in
        --aop-id)
            AOP_ID="$2"
            shift 2
            ;;
        --aop-ip)
            AOP_IP="$2"
            shift 2
            ;;
        --aop-port)
            AOP_PORT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [ -z "$AOP_ID" ]; then
    read -p "Enter Always-On Peer (AOP) Device ID: " AOP_ID
fi

if [ -z "$AOP_IP" ]; then
    read -p "Enter AOP IP/Hostname [default: storage.lan]: " AOP_IP
    AOP_IP="${AOP_IP:-storage.lan}"
fi

# Calculate dynamic ports based on local UNIX UID offset
UID_OFFSET=$(($(id -u) - 1000))
if [ "$UID_OFFSET" -lt 0 ]; then
    UID_OFFSET=0
fi
LOCAL_GUI_PORT=$((8384 + UID_OFFSET))
LOCAL_SYNC_PORT=$((22000 + UID_OFFSET))
DEFAULT_AOP_PORT=$((22000 + UID_OFFSET))

if [ -z "$AOP_PORT" ]; then
    read -p "Enter AOP Sync Port [default: $DEFAULT_AOP_PORT]: " AOP_PORT
    AOP_PORT="${AOP_PORT:-$DEFAULT_AOP_PORT}"
fi

echo "Starting Home-Sync Client Bootstrap..."

# 1. System Updates and Sync Dependencies (Apt)
echo "Installing sync dependencies..."
sudo apt update
sudo apt install -y \
    wireguard-tools \
    syncthing \
    curl \
    git \
    wget

# 4. Home Cleaning (Conflict Prevention)
echo "Cleaning up default home directory files..."
for file in .bashrc .profile .bash_logout; do
    if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
        echo "Backing up $file to $file.bak"
        mv "$HOME/$file" "$HOME/$file.bak"
    fi
done

# 5. Initial Syncthing Configuration
echo "Initializing Syncthing config..."
syncthing generate

# Configure Syncthing's default folder to point to the user's home directory and add AOP device
echo "Reconfiguring Syncthing default folder path and adding AOP device..."
python3 -c "
import xml.etree.ElementTree as ET
import os
import sys

aop_id = sys.argv[1]
aop_ip = sys.argv[2]
aop_port = sys.argv[3]
local_gui_port = sys.argv[4]
local_sync_port = sys.argv[5]
target_path = os.path.expanduser('~')

possible_paths = [
    os.path.expanduser('~/.config/syncthing/config.xml'),
    os.path.expanduser('~/.local/state/syncthing/config.xml')
]

config_path = None
for path in possible_paths:
    if os.path.exists(path):
        config_path = path
        break

if not config_path:
    print(f'Config file not found in expected locations: {possible_paths}', file=sys.stderr)
    sys.exit(1)

tree = ET.parse(config_path)
root = tree.getroot()

# Update client's local options (listenAddress)
options = root.find('options')
if options is not None:
    for la in options.findall('listenAddress'):
        options.remove(la)
    la_tcp = ET.SubElement(options, 'listenAddress')
    la_tcp.text = f'tcp://0.0.0.0:{local_sync_port}'
    la_quic = ET.SubElement(options, 'listenAddress')
    la_quic.text = f'quic://0.0.0.0:{local_sync_port}'
else:
    options = ET.SubElement(root, 'options')
    la_tcp = ET.SubElement(options, 'listenAddress')
    la_tcp.text = f'tcp://0.0.0.0:{local_sync_port}'
    la_quic = ET.SubElement(options, 'listenAddress')
    la_quic.text = f'quic://0.0.0.0:{local_sync_port}'

# Update client's local GUI port
gui = root.find('gui')
if gui is not None:
    address = gui.find('address')
    if address is not None:
        address.text = f'127.0.0.1:{local_gui_port}'
    else:
        address = ET.SubElement(gui, 'address')
        address.text = f'127.0.0.1:{local_gui_port}'

# Update default folder path and add AOP device sharing
for folder in root.findall('folder'):
    if folder.get('id') == 'default':
        if 'path' in folder.attrib:
            folder.set('path', target_path)
        path_el = folder.find('path')
        if path_el is not None:
            path_el.text = target_path
        
        # Add device sharing with AOP
        device_exists = False
        for dev in folder.findall('device'):
            if dev.get('id') == aop_id:
                device_exists = True
                break
        if not device_exists:
            ET.SubElement(folder, 'device', {'id': aop_id})

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

# Add AOP device configuration under root if not exists
device_exists = False
for device in root.findall('device'):
    if device.get('id') == aop_id:
        device_exists = True
        addr_el = device.find('address')
        if addr_el is not None:
            addr_el.text = f'tcp://{aop_ip}:{aop_port}'
        else:
            addr_el = ET.SubElement(device, 'address')
            addr_el.text = f'tcp://{aop_ip}:{aop_port}'
        break

if not device_exists:
    dev_el = ET.SubElement(root, 'device', {
        'id': aop_id,
        'name': 'aop',
        'compression': 'metadata',
        'introducer': 'false',
        'skipIntroductionOnError': 'false'
    })
    addr_el = ET.SubElement(dev_el, 'address')
    addr_el.text = f'tcp://{aop_ip}:{aop_port}'

tree.write(config_path)
" "$AOP_ID" "$AOP_IP" "$AOP_PORT" "$LOCAL_GUI_PORT" "$LOCAL_SYNC_PORT"

# Copy the stignore template to user's home directory
cp ../config/.stignore ~/.stignore

# 6. Write Watcher Configuration
echo "Writing watcher configuration..."
mkdir -p ~/.config/home-sync
echo "AOP_IP=$AOP_IP" > ~/.config/home-sync/watcher.env

# 7. Setup and Start Systemd Services
echo "Installing systemd services..."
mkdir -p ~/.config/systemd/user/
cp ../systemd/home-sync-watcher.service ~/.config/systemd/user/
mkdir -p ~/scripts
cp ./home-sync-watcher.sh ~/scripts/
chmod +x ~/scripts/home-sync-watcher.sh

systemctl --user daemon-reload
systemctl --user enable syncthing.service
systemctl --user enable home-sync-watcher.service

systemctl --user start syncthing.service
systemctl --user start home-sync-watcher.service

# 8. Setup Account Synchronization Services (Import)
echo "Installing user account import services..."
sudo cp ./scripts/import-accounts.py /usr/local/sbin/home-sync-import-accounts.py
sudo chmod +x /usr/local/sbin/home-sync-import-accounts.py
sudo cp ./systemd/system-services/home-sync-import-accounts@.service /etc/systemd/system/
sudo cp ./systemd/system-services/home-sync-import-accounts@.path /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now "home-sync-import-accounts@$(whoami).path"

# Run a first import if accounts.json has already synced
if [ -f ~/.config/home-sync/accounts.json ]; then
    echo "Running first-time user account import..."
    sudo systemctl start "home-sync-import-accounts@$(whoami).service" || true
fi

CLIENT_ID=$(syncthing --device-id)

echo "----------------------------------------------------"
echo "Bootstrap Complete!"
echo "Next Steps:"
echo "1. Configure your Wireguard tunnel at /etc/wireguard/wg0.conf"
echo "2. Add this client's Device ID on your Always-On Peer (AOP):"
echo "   Device ID: $CLIENT_ID"
echo "----------------------------------------------------"
