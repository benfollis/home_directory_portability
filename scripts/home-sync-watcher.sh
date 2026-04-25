#!/bin/bash
# home-sync-watcher.sh - Connectivity monitor for Syncthing

AOP_IP="10.0.0.1"
INTERFACE="wg0"

check_connectivity() {
    # 1. Check if interface exists and is up
    if ! ip addr show "$INTERFACE" > /dev/null 2>&1; then
        return 1
    fi

    # 2. Check if AOP is reachable
    if ! ping -c 1 -W 2 "$AOP_IP" > /dev/null 2>&1; then
        return 1
    fi

    return 0
}

while true; do
    if check_connectivity; then
        if ! systemctl --user is-active syncthing.service > /dev/null 2>&1; then
            echo "AOP reachable. Starting Syncthing..."
            systemctl --user start syncthing.service
        fi
    else
        if systemctl --user is-active syncthing.service > /dev/null 2>&1; then
            echo "AOP unreachable. Stopping Syncthing..."
            systemctl --user stop syncthing.service
        fi
    fi
    sleep 30
done
