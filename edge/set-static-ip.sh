#!/bin/bash

# ─────────────────────────────────────────────
# Set a static IP address on the server
#
# This script detects the current IP and network
# configuration, then configures NetworkManager
# to keep that IP permanently (static).
#
# Works with both ethernet and WiFi interfaces.
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
  error "Run this script with sudo: sudo bash set-static-ip.sh"
fi

# ─── Check nmcli is available ────────────────

if ! command -v nmcli &> /dev/null; then
  error "nmcli not found. This script requires NetworkManager."
fi

# ─────────────────────────────────────────────
# 1. Detect active network interface
# ─────────────────────────────────────────────

step "Detecting network configuration"

# Find the default route interface
INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -1)

if [ -z "$INTERFACE" ]; then
  error "Could not detect the active network interface."
fi

# Find the NetworkManager connection name for this interface
CONNECTION=$(nmcli -t -f NAME,DEVICE con show --active | grep ":${INTERFACE}$" | head -1 | cut -d: -f1)

if [ -z "$CONNECTION" ]; then
  error "No active NetworkManager connection found for $INTERFACE."
fi

info "Active interface: $INTERFACE"
info "NM connection: $CONNECTION"

# ─────────────────────────────────────────────
# 2. Detect current IP, gateway, and DNS
# ─────────────────────────────────────────────

CURRENT_IP=$(ip -4 addr show "$INTERFACE" | grep -oP 'inet \K[\d.]+' | head -1)
GATEWAY=$(ip route | grep '^default' | awk '{print $3}' | head -1)
DNS=$(resolvectl dns "$INTERFACE" 2>/dev/null | grep -oP '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)

# Fallback DNS detection
if [ -z "$DNS" ]; then
  DNS=$(grep '^nameserver' /etc/resolv.conf | head -1 | awk '{print $2}')
fi

# Default to gateway as DNS if nothing found
if [ -z "$DNS" ]; then
  DNS="$GATEWAY"
fi

if [ -z "$CURRENT_IP" ] || [ -z "$GATEWAY" ]; then
  error "Could not detect current IP ($CURRENT_IP) or gateway ($GATEWAY)."
fi

# Get CIDR prefix from the interface
CIDR=$(ip -4 addr show "$INTERFACE" | grep -oP 'inet [\d.]+/\K\d+' | head -1)
CIDR="${CIDR:-24}"

echo ""
echo "  Interface  : $INTERFACE"
echo "  Connection : $CONNECTION"
echo "  IP         : $CURRENT_IP/$CIDR"
echo "  Gateway    : $GATEWAY"
echo "  DNS        : $DNS"
echo ""

# ─────────────────────────────────────────────
# 3. Check if already static
# ─────────────────────────────────────────────

CURRENT_METHOD=$(nmcli -t -f ipv4.method con show "$CONNECTION" | cut -d: -f2)

if [ "$CURRENT_METHOD" = "manual" ]; then
  CURRENT_STATIC_IP=$(nmcli -t -f ipv4.addresses con show "$CONNECTION" | cut -d: -f2)
  if [ "$CURRENT_STATIC_IP" = "$CURRENT_IP/$CIDR" ]; then
    info "Already configured with static IP $CURRENT_IP/$CIDR. Nothing to do."
    exit 0
  fi
fi

# ─────────────────────────────────────────────
# 4. Confirm with user
# ─────────────────────────────────────────────

step "Confirmation"

read -p "Set $CURRENT_IP as the permanent static IP? [Y/n] " CONFIRM
CONFIRM="${CONFIRM:-Y}"

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  info "Aborted."
  exit 0
fi

# ─────────────────────────────────────────────
# 5. Configure static IP via NetworkManager
# ─────────────────────────────────────────────

step "Configuring static IP"

nmcli con mod "$CONNECTION" \
  ipv4.method manual \
  ipv4.addresses "$CURRENT_IP/$CIDR" \
  ipv4.gateway "$GATEWAY" \
  ipv4.dns "$DNS"

info "NetworkManager connection updated."

# ─────────────────────────────────────────────
# 6. Apply changes
# ─────────────────────────────────────────────

step "Applying network configuration"

nmcli con up "$CONNECTION"
info "Connection reactivated."

# ─────────────────────────────────────────────
# 7. Verification
# ─────────────────────────────────────────────

step "Verification"

sleep 2
NEW_IP=$(ip -4 addr show "$INTERFACE" | grep -oP 'inet \K[\d.]+' | head -1)

if [ "$NEW_IP" = "$CURRENT_IP" ]; then
  echo -e "${GREEN}✓ Static IP set successfully${NC}: $NEW_IP"
else
  warning "IP changed unexpectedly: expected $CURRENT_IP, got $NEW_IP"
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────"
echo -e "${GREEN}Static IP configuration complete!${NC}"
echo ""
echo "  Interface  : $INTERFACE"
echo "  Connection : $CONNECTION"
echo "  Static IP  : $CURRENT_IP/$CIDR"
echo "  Gateway    : $GATEWAY"
echo "  DNS        : $DNS"
echo ""
echo "  To revert to DHCP:"
echo "    sudo bash unset-static-ip.sh"
echo ""
echo "─────────────────────────────────────────────"
echo ""
