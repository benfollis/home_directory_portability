#!/bin/bash
# setup-aop.sh - Always-On Peer (Server) Setup

set -e

echo "Starting AOP Setup..."

# 1. Install Syncthing
sudo apt update
sudo apt install -y syncthing

# 2. Enable Syncthing Systemd User Service
# Syncthing provides a default user service in Debian
systemctl --user enable syncthing.service
systemctl --user start syncthing.service

echo "Waiting for Syncthing to generate configuration..."
sleep 5

# 3. Get Device ID
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
