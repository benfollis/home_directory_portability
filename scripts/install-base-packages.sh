#!/bin/bash
# install-base-packages.sh - Install base applications and SDKs

set -e

echo "Starting base package and SDK installation..."

# 1. Ensure core tools for keyring setup are present
sudo apt update
sudo apt install -y curl gpg

# 2. Add Extra Repositories
echo "Configuring third-party repositories..."
sudo mkdir -p /etc/apt/keyrings

# Waterfox Repository
if [ ! -f /etc/apt/sources.list.d/waterfox.list ]; then
    echo "Adding Waterfox repository..."
    curl -fsSL https://download.opensuse.org/repositories/home:/hawkeyepierce:/waterfox/Debian_Testing/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/waterfox.gpg
    echo "deb [signed-by=/etc/apt/keyrings/waterfox.gpg] http://download.opensuse.org/repositories/home:/hawkeyepierce:/waterfox/Debian_Testing/ /" | sudo tee /etc/apt/sources.list.d/waterfox.list
fi

# 3. Update and Install Applications (Apt)
echo "Installing applications..."
sudo apt update
sudo apt install -y \
    emacs \
    thunderbird \
    openjdk-17-jdk \
    git \
    wget \
    waterfox

# 4. Antigravity CLI Installation
if ! command -v agy &> /dev/null; then
    echo "Installing Antigravity CLI..."
    curl -fsSL https://antigravity.google/cli/install.sh | bash
fi

# 5. Development SDKs (Flutter/Dart/Node)
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

echo "Base package installation complete!"
