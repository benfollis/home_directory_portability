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

echo "Starting Home-Sync Client Bootstrap..."

# 1. System Updates and Core Apps (Apt)
echo "Installing core applications..."
sudo apt update
sudo apt install -y \
    wireguard-tools \
    syncthing \
    emacs \
    thunderbird \
    openjdk-17-jdk \
    curl \
    git \
    wget

# 2. Specialty Software (.deb)
echo "Installing Specialty Software..."

# Antigravity (Google Editor)
# Note: User provides the URL or we assume a standard location
ANTIGRAVITY_URL="https://example.com/antigravity.deb" # Placeholder
if ! command -v antigravity &> /dev/null; then
    wget -O /tmp/antigravity.deb "$ANTIGRAVITY_URL"
    sudo apt install -y /tmp/antigravity.deb
fi

# Waterfox
# Note: Using flatpak or direct download if not in apt
# For this script, we'll assume the user might need to add a repo or we use a placeholder download
echo "Note: Waterfox installation method varies. Ensure repo is added or install manually."

# 3. Development SDKs (Flutter/Dart/Node)
echo "Setting up development SDKs..."

# Node (via NVM)
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# Flutter/Dart (Downloaded to ~/opt)
mkdir -p ~/opt
if [ ! -d "$HOME/opt/flutter" ]; then
    wget -O /tmp/flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.0-stable.tar.xz
    tar xf /tmp/flutter.tar.xz -C ~/opt/
fi

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

# Add AOP device configuration under root if not exists
device_exists = False
for device in root.findall('device'):
    if device.get('id') == aop_id:
        device_exists = True
        addr_el = device.find('address')
        if addr_el is not None:
            addr_el.text = f'tcp://{aop_ip}:22000'
        else:
            addr_el = ET.SubElement(device, 'address')
            addr_el.text = f'tcp://{aop_ip}:22000'
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
    addr_el.text = f'tcp://{aop_ip}:22000'

tree.write(config_path)
" "$AOP_ID" "$AOP_IP"

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

CLIENT_ID=$(syncthing --device-id)

echo "----------------------------------------------------"
echo "Bootstrap Complete!"
echo "Next Steps:"
echo "1. Configure your Wireguard tunnel at /etc/wireguard/wg0.conf"
echo "2. Add this client's Device ID on your Always-On Peer (AOP):"
echo "   Device ID: $CLIENT_ID"
echo "----------------------------------------------------"
