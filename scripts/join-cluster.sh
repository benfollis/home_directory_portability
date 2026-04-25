#!/bin/bash
# join-cluster.sh - Client Machine Bootstrap Script

set -e

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

# 5. Setup Systemd Services
echo "Installing systemd services..."
mkdir -p ~/.config/systemd/user/
cp ../systemd/home-sync-watcher.service ~/.config/systemd/user/
mkdir -p ~/scripts
cp ./home-sync-watcher.sh ~/scripts/
chmod +x ~/scripts/home-sync-watcher.sh

systemctl --user daemon-reload
systemctl --user enable home-sync-watcher.service
systemctl --user start home-sync-watcher.service

# 6. Initial Syncthing Configuration
echo "Initializing Syncthing..."
systemctl --user enable syncthing.service
systemctl --user start syncthing.service

echo "----------------------------------------------------"
echo "Bootstrap Complete!"
echo "Next Steps:"
echo "1. Configure your Wireguard tunnel at /etc/wireguard/wg0.conf"
echo "2. Open http://localhost:8384 and add the AOP Device ID."
echo "3. Copy config/.stignore to ~/.stignore"
echo "----------------------------------------------------"
