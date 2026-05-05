#!/bin/bash

# Setup unattended-upgrades for automatic security updates
# Run this script on each server to enable automatic patching

set -e

echo "=== Installing unattended-upgrades ==="
sudo apt-get -y update
sudo apt-get -y install unattended-upgrades apt-listchanges

echo "=== Configuring unattended-upgrades ==="

# Determine Ubuntu codename
CODENAME=$(lsb_release -cs)

sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:${CODENAME}-security";
    "\${distro_id}ESMApps:${CODENAME}-apps-security";
    "\${distro_id}ESM:${CODENAME}-infra-security";
};

// Remove unused automatically installed kernel-related packages
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";

// Remove unused dependencies after upgrade
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Do NOT automatically reboot (analyses may be running)
Unattended-Upgrade::Automatic-Reboot "false";

// Send email notification (optional, set your email below or leave empty)
// Unattended-Upgrade::Mail "admin@example.com";
// Unattended-Upgrade::MailReport "on-change";
EOF

# Enable the automatic update timer
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Configure needrestart for non-interactive automatic service restarts
if dpkg -l | grep -q needrestart; then
    sudo sed -i "s/^\$nrconf{restart}.*$/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf 2>/dev/null || true
fi

echo "=== Enabling unattended-upgrades timer ==="
sudo systemctl enable --now apt-daily.timer
sudo systemctl enable --now apt-daily-upgrade.timer

echo "=== Verifying configuration ==="
sudo unattended-upgrades --dry-run --debug 2>&1 | tail -5

echo ""
echo "Done! Unattended security upgrades are now enabled."
echo "  - Security patches will be installed daily"
echo "  - Automatic reboot is DISABLED (to protect running analyses)"
echo "  - Unused kernels/dependencies will be cleaned up"
echo ""
echo "To check if a reboot is needed: [ -f /var/run/reboot-required ] && cat /var/run/reboot-required"
echo "To check status: sudo systemctl status apt-daily-upgrade.timer"
echo "To view logs: sudo cat /var/log/unattended-upgrades/unattended-upgrades.log"
