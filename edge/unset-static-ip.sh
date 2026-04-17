#!/bin/bash

# ─────────────────────────────────────────────
# Remove static IP and restore DHCP
#
# This script reverts the active NetworkManager
# connection back to DHCP (automatic IP).
#
# Idempotent: safe to run multiple times
# ─────────────────────────────────────────────

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
step()    { echo -e "\n${BLUE}▸ $1${NC}"; }

# ─── Check root permissions ────────────────

if [ "$EUID" -ne 0 ]; then
  error "Run this script with sudo: sudo bash unset-static-ip.sh"
fi

# ─── Check nmcli is available ────────────────

if ! command -v nmcli &> /dev/null; then
  error "nmcli not found. This script requires NetworkManager."
fi

# ─────────────────────────────────────────────
# 1. Detect active connection
# ─────────────────────────────────────────────

step "Detecting network configuration"

INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -1)

if [ -z "$INTERFACE" ]; then
  error "Could not detect the active network interface."
fi

CONNECTION=$(nmcli -t -f NAME,DEVICE con show --active | grep ":${INTERFACE}$" | head -1 | cut -d: -f1)

if [ -z "$CONNECTION" ]; then
  error "No active NetworkManager connection found for $INTERFACE."
fi

info "Active interface: $INTERFACE"
info "NM connection: $CONNECTION"

# ─────────────────────────────────────────────
# 2. Check current method
# ─────────────────────────────────────────────

CURRENT_METHOD=$(nmcli -t -f ipv4.method con show "$CONNECTION" | cut -d: -f2)

if [ "$CURRENT_METHOD" = "auto" ]; then
  info "Already using DHCP. Nothing to do."
  exit 0
fi

info "Current method: $CURRENT_METHOD → switching to DHCP"

# ─────────────────────────────────────────────
# 3. Restore DHCP
# ─────────────────────────────────────────────

step "Restoring DHCP"

nmcli con mod "$CONNECTION" \
  ipv4.method auto \
  ipv4.addresses "" \
  ipv4.gateway "" \
  ipv4.dns ""

info "NetworkManager connection updated."

# ─────────────────────────────────────────────
# 4. Apply changes
# ─────────────────────────────────────────────

step "Applying network configuration"

nmcli con up "$CONNECTION"
info "Connection reactivated."

# ─────────────────────────────────────────────
# 5. Verification
# ─────────────────────────────────────────────

step "Verification"

sleep 2
NEW_IP=$(ip -4 addr show "$INTERFACE" | grep -oP 'inet \K[\d.]+' | head -1)

if [ -n "$NEW_IP" ]; then
  echo -e "${GREEN}✓ Network OK${NC}: $INTERFACE → $NEW_IP (via DHCP)"
else
  warning "No IP detected yet. It may take a few seconds for DHCP to assign one."
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────"
echo -e "${GREEN}DHCP restored!${NC}"
echo ""
echo "  The server will now obtain its IP automatically."
echo "  Note: the IP may change after a reboot."
echo ""
echo "─────────────────────────────────────────────"
echo ""
