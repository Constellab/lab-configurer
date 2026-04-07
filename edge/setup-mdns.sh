#!/bin/bash

# ─────────────────────────────────────────────
# Network configuration: mDNS + Avahi (IPv4 only)
#
# This script configures the local network discovery
# on an Ubuntu machine using Avahi and mDNS so that
# the server becomes reachable via <hostname>.local
# on the local network without requiring a DNS server.
#
# Steps performed:
#   1. Set or update the system hostname
#   2. Install avahi-daemon and libnss-mdns if missing
#   3. Configure Avahi to use IPv4 only (disable IPv6)
#   4. Update /etc/nsswitch.conf to enable mDNS resolution
#   5. Enable and restart the Avahi daemon
#   6. Verify that mDNS resolution works
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
  error "Run this script with sudo: sudo bash setup-network.sh"
fi

# ─── Function: set key=value in a .conf file ──
# Handles cases: missing key, commented-out key, key already set to the correct value
set_conf_value() {
  local file="$1"
  local key="$2"
  local value="$3"
  local section="$4"

  local current
  current=$(grep -E "^${key}=" "$file" 2>/dev/null | head -1 | cut -d= -f2)

  if [ "$current" = "$value" ]; then
    info "$key already set to '$value', nothing to do."
    return
  fi

  if grep -qE "^${key}=" "$file"; then
    sed -i "s/^${key}=.*/${key}=${value}/" "$file"
    info "$key updated: '$current' → '$value'"
  elif grep -qE "^#\s*${key}=" "$file"; then
    sed -i "s/^#\s*${key}=.*/${key}=${value}/" "$file"
    info "$key uncommented and set to '$value'"
  elif [ -n "$section" ] && grep -q "^\[${section}\]" "$file"; then
    sed -i "/^\[${section}\]/a ${key}=${value}" "$file"
    info "$key added after [${section}]: '$value'"
  else
    echo "${key}=${value}" >> "$file"
    info "$key appended to end of file: '$value'"
  fi
}

# ─────────────────────────────────────────────
# 1. Hostname
# ─────────────────────────────────────────────

step "Hostname"

CURRENT_HOSTNAME=$(hostnamectl --static)
read -p "Server hostname (current: $CURRENT_HOSTNAME): " INPUT_HOSTNAME
HOSTNAME="${INPUT_HOSTNAME:-$CURRENT_HOSTNAME}"

if [ -z "$HOSTNAME" ]; then
  error "Hostname cannot be empty."
fi

if [ "$HOSTNAME" = "$CURRENT_HOSTNAME" ]; then
  info "Hostname unchanged: $HOSTNAME"
else
  hostnamectl set-hostname "$HOSTNAME"
  info "Hostname updated: $CURRENT_HOSTNAME → $HOSTNAME"
fi

# ─────────────────────────────────────────────
# 2. Package installation
# ─────────────────────────────────────────────

step "Package installation"

PACKAGES=()
dpkg -s avahi-daemon &>/dev/null || PACKAGES+=(avahi-daemon)
dpkg -s libnss-mdns  &>/dev/null || PACKAGES+=(libnss-mdns)

if [ ${#PACKAGES[@]} -eq 0 ]; then
  info "avahi-daemon and libnss-mdns already installed."
else
  info "Installing: ${PACKAGES[*]}"
  apt-get update -qq
  apt-get install -y "${PACKAGES[@]}" > /dev/null
fi

# ─────────────────────────────────────────────
# 3. Avahi configuration (IPv4 only)
# ─────────────────────────────────────────────

step "Avahi configuration"

AVAHI_CONF="/etc/avahi/avahi-daemon.conf"

set_conf_value "$AVAHI_CONF" "use-ipv4" "yes" "server"
set_conf_value "$AVAHI_CONF" "use-ipv6" "no"  "server"

# ─────────────────────────────────────────────
# 4. nsswitch.conf configuration
# ─────────────────────────────────────────────

step "nsswitch.conf configuration"

NSSWITCH="/etc/nsswitch.conf"
HOSTS_LINE=$(grep "^hosts:" "$NSSWITCH")

if echo "$HOSTS_LINE" | grep -q "mdns4_minimal"; then
  info "mdns4_minimal already present in nsswitch.conf"
else
  warning "mdns4_minimal missing, fixing..."
  sed -i 's/^hosts:.*/hosts:          files mdns4_minimal [NOTFOUND=return] dns/' "$NSSWITCH"
  info "nsswitch.conf updated."
fi

# ─────────────────────────────────────────────
# 5. Start Avahi
# ─────────────────────────────────────────────

step "Starting Avahi service"

systemctl enable avahi-daemon > /dev/null
systemctl restart avahi-daemon
info "Avahi restarted."

# ─────────────────────────────────────────────
# 6. Verification
# ─────────────────────────────────────────────

step "Verification"

sleep 2
RESOLVED=$(getent hosts "$HOSTNAME.local" 2>/dev/null | awk '{print $1}' | grep -v "^fe80" | head -1)

if [ -n "$RESOLVED" ]; then
  echo -e "${GREEN}✓ mDNS resolution OK${NC}: $HOSTNAME.local → $RESOLVED"
else
  warning "IPv4 resolution is not available yet."
  warning "Retry in a few seconds: getent hosts $HOSTNAME.local"
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────────"
echo -e "${GREEN}Configuration complete!${NC}"
echo ""
echo "  Hostname    : $HOSTNAME"
echo "  Accessible  : http://$HOSTNAME.local"
echo "─────────────────────────────────────────────"
echo ""
