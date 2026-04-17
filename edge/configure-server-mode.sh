#!/bin/bash

# Configure the mini-PC as a server:
# - Disable sleep/suspend/hibernate so it stays on
# - Install and enable SSH for remote access

echo "=== Configuring server mode ==="

# --- Disable sleep, suspend, and hibernate ---
echo "Disabling sleep, suspend, and hibernate..."
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Prevent lid close from suspending (useful if mini-pc has a lid or connected to a laptop dock)
LOGIND_CONF="/etc/systemd/logind.conf.d/no-suspend.conf"
LOGIND_CONTENT="[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore"

sudo mkdir -p /etc/systemd/logind.conf.d

if [ ! -f "$LOGIND_CONF" ] || [ "$(cat "$LOGIND_CONF")" != "$LOGIND_CONTENT" ]; then
    echo "$LOGIND_CONTENT" | sudo tee "$LOGIND_CONF" > /dev/null
    sudo systemctl restart systemd-logind
else
    echo "logind config already up to date, skipping restart."
fi

# Disable screen blanking via GNOME settings (if GNOME is available)
if command -v gsettings &> /dev/null; then
    echo "Disabling screen blanking (GNOME)..."
    gsettings set org.gnome.desktop.session idle-delay 0
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
fi

echo "Sleep/suspend disabled."

# --- Install and enable SSH ---
echo "Installing and enabling SSH server..."
sudo apt-get -y install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh

echo "SSH server is active. You can connect with: ssh $(whoami)@$(hostname).local"

echo "=== Server mode configuration complete ==="
