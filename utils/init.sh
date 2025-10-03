#!/bin/bash

# Function to create required Docker networks
create_docker_networks() {
  local networks=("gencovery-network-manager" "gencovery-network-dev" "gencovery-network-prod")
  
  for network in "${networks[@]}"; do
    if [[ "$(docker network ls | grep "$network")" == "" ]]; then
      docker network create -d bridge "$network"
    fi
  done
}

# Function to set environment variable
set_environment_variable() {
  local var_name="$1"
  local var_value="$2"
  
  sudo sed -i "/$var_name/d" /etc/environment
  sudo sh -c "echo $var_name=$var_value >> /etc/environment"
  export "$var_name=$var_value"
}

# Function to parse command line arguments
parse_arguments() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --virtual-host=*)
        VIRTUAL_HOST="${1#*=}"
        shift
        ;;
      --environment-profile=*)
        ENVIRONMENT_PROFILE="${1#*=}"
        shift
        ;;
      --lab-manager-api-key=*)
        LAB_MANAGER_API_KEY="${1#*=}"
        shift
        ;;
      --lab-manager-version=*)
        LAB_MANAGER_VERSION="${1#*=}"
        shift
        ;;
      --dns-challenge-enabled=*)
        DNS_CHALLENGE_ENABLED="${1#*=}"
        shift
        ;;
      --dns-challenge-provider=*)
        DNS_CHALLENGE_PROVIDER="${1#*=}"
        shift
        ;;
      --dns-challenge-route=*)
        DNS_CHALLENGE_ROUTE="${1#*=}"
        shift
        ;;
      *)
        echo "Unknown parameter passed: $1"
        exit 1
        ;;
    esac
  done
}

# Function to validate required parameters
validate_parameters() {
  if [[ -z "$VIRTUAL_HOST" ]] || [[ -z "$ENVIRONMENT_PROFILE" ]] || [[ -z "$LAB_MANAGER_API_KEY" ]] || [[ -z "$LAB_MANAGER_VERSION" ]]; then
    echo "Missing parameters"
    echo "Usage: ./init.sh --virtual-host=<VIRTUAL_HOST> --environment-profile=<ENVIRONMENT_PROFILE> --lab-manager-api-key=<LAB_MANAGER_API_KEY> --lab-manager-version=<LAB_MANAGER_VERSION> [--dns-challenge-enabled=<true|false>] [--dns-challenge-provider=<PROVIDER>] [--dns-challenge-route=<ROUTE>]"
    echo "Example: ./init.sh --virtual-host=\"*.gencovery.io\" --environment-profile=\"prod\" --lab-manager-api-key=\"1234567890abcdefg\" --lab-manager-version=\"1.0.0\" --dns-challenge-enabled=\"true\" --dns-challenge-provider=\"cloudflare\" --dns-challenge-route=\"/dns/challenge\""
    exit 1
  fi
}

# Create Docker networks
create_docker_networks

# Initialize variables
VIRTUAL_HOST=""
ENVIRONMENT_PROFILE=""
LAB_MANAGER_API_KEY=""
LAB_MANAGER_VERSION=""
DNS_CHALLENGE_ENABLED=""
DNS_CHALLENGE_PROVIDER=""
DNS_CHALLENGE_ROUTE=""

# Parse arguments
parse_arguments "$@"

# Validate required parameters
validate_parameters

# Set environment variables
set_environment_variable "VIRTUAL_HOST" "$VIRTUAL_HOST"
set_environment_variable "ENVIRONMENT_PROFILE" "$ENVIRONMENT_PROFILE"
set_environment_variable "LAB_MANAGER_API_KEY" "$LAB_MANAGER_API_KEY"
set_environment_variable "LAB_MANAGER_VERSION" "$LAB_MANAGER_VERSION"

# Set DNS challenge variables if provided
if [[ -n "$DNS_CHALLENGE_ENABLED" ]]; then
  set_environment_variable "DNS_CHALLENGE_ENABLED" "$DNS_CHALLENGE_ENABLED"
fi

if [[ -n "$DNS_CHALLENGE_PROVIDER" ]]; then
  set_environment_variable "DNS_CHALLENGE_PROVIDER" "$DNS_CHALLENGE_PROVIDER"
fi

if [[ -n "$DNS_CHALLENGE_ROUTE" ]]; then
  set_environment_variable "DNS_CHALLENGE_ROUTE" "$DNS_CHALLENGE_ROUTE"
fi

# Enable firewall using ufw
# Check UFW status
ufw_status=$(sudo ufw status | grep -o "Status: active")

# If UFW is active
if [ "$ufw_status" == "Status: active" ]; then
    echo "UFW is enabled, skipping..."
else
    echo "UFW is disabled, enabling..."
    # allow OpenSSH, HTTP, and HTTPS incoming traffic only
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow OpenSSH
    sudo ufw allow 80
    sudo ufw allow 443
    sudo ufw --force enable
fi

# Set folders permissions
if [ "$(stat -c '%U' /app)" != "ubuntu" ]; then
    echo "[INFO] Changing ownership of /app to ubuntu:ubuntu..."
    sudo find /app -path /app/dev/etc-ssh -prune -o -path /app/gws_db/gws_core/prod/mariadb -prune -o -path /app/gws_db/gws_core/dev/mariadb -prune -o -path /app/gws_db/gws_biota/mariadb -prune -o -path /app/docker -prune -o -exec chown ubuntu:ubuntu {} +
    echo "[INFO] Ownership change completed"
else
    echo "[INFO] /app is already owned by ubuntu"
fi

# Change ownership of /app/dev/etc-ssh and /app/docker to root:root
if [ "$(stat -c '%U' /app/dev/etc-ssh)" != "root" ]; then
    echo "[INFO] Changing ownership of /app/dev/etc-ssh to root:root..."
    sudo chown -R root:root /app/dev/etc-ssh
    echo "[INFO] Ownership change completed"
else
    echo "[INFO] /app/dev/etc-ssh is already owned by root"
fi

if [ "$(stat -c '%U' /app/docker)" != "root" ]; then
    echo "[INFO] Changing ownership of /app/docker to root:root..."
    sudo chown -R root:root /app/docker
    echo "[INFO] Ownership change completed"
else
    echo "[INFO] /app/docker is already owned by root"
fi
