#!/bin/bash

# Script to migrate Docker group to GID 999
# This script safely handles GID conflicts and preserves file ownership

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Get current Docker GID or create the group if it doesn't exist
DOCKER_GID=$(getent group docker | cut -d: -f3)

if [ -z "$DOCKER_GID" ]; then
    print_warning "Docker group does not exist. Creating it with GID 999..."
    groupadd -g 999 docker
    DOCKER_GID=999
    print_info "Docker group created with GID 999"
fi

print_info "Current Docker GID: $DOCKER_GID"

# Check if Docker is already 999
if [ "$DOCKER_GID" -eq 999 ]; then
    print_info "Docker group is already GID 999. No changes needed."
    exit 0
fi

print_warning "Docker group needs to be migrated to GID 999"

# Check if GID 999 is occupied
CONFLICT_GROUP=$(getent group 999 | cut -d: -f1)

if [ -n "$CONFLICT_GROUP" ]; then
    print_warning "GID 999 is currently occupied by group: $CONFLICT_GROUP"

    # Step 1: Move docker to temporary GID (e.g., 9999)
    TEMP_GID=9999
    print_info "Step 1: Moving docker group to temporary GID $TEMP_GID"
    groupmod -g $TEMP_GID docker

    # Update file ownership for docker group (only Docker-related directories)
    print_info "Updating file ownership for docker group..."
    for dir in /app/docker /var/run/docker.sock /etc/docker; do
        if [ -e "$dir" ]; then
            find "$dir" -gid $DOCKER_GID -exec chgrp -h docker {} + 2>/dev/null || true
        fi
    done

    # Step 2: Move conflicting group from 999 to 998
    print_info "Step 2: Moving $CONFLICT_GROUP from GID 999 to GID 998"

    # Check if 998 is also occupied
    GID_998_GROUP=$(getent group 998 | cut -d: -f1)
    if [ -n "$GID_998_GROUP" ]; then
        print_error "GID 998 is also occupied by group: $GID_998_GROUP"
        print_error "Please manually resolve this conflict first."
        # Rollback docker group
        groupmod -g $DOCKER_GID docker
        exit 1
    fi

    groupmod -g 998 "$CONFLICT_GROUP"

    # Update file ownership for conflicting group (only Docker-related directories)
    print_info "Updating file ownership for $CONFLICT_GROUP..."
    for dir in /app/docker /var/run/docker.sock /etc/docker; do
        if [ -e "$dir" ]; then
            find "$dir" -gid 999 -exec chgrp -h "$CONFLICT_GROUP" {} + 2>/dev/null || true
        fi
    done

    # Step 3: Move docker from temporary GID to 999
    print_info "Step 3: Moving docker group from temporary GID $TEMP_GID to GID 999"
    groupmod -g 999 docker

    # Update file ownership for docker group (only Docker-related directories)
    print_info "Updating file ownership for docker group to GID 999..."
    for dir in /app/docker /var/run/docker.sock /etc/docker; do
        if [ -e "$dir" ]; then
            find "$dir" -gid $TEMP_GID -exec chgrp -h docker {} + 2>/dev/null || true
        fi
    done

    print_info "Migration completed successfully!"
    print_info "Summary:"
    print_info "  - Docker group: $DOCKER_GID -> 999"
    print_info "  - $CONFLICT_GROUP group: 999 -> 998"
else
    # No conflict, just move docker directly to 999
    print_info "GID 999 is available. Moving docker group directly."
    groupmod -g 999 docker

    # Update file ownership (only Docker-related directories)
    print_info "Updating file ownership for docker group..."
    for dir in /app/docker /var/run/docker.sock /etc/docker; do
        if [ -e "$dir" ]; then
            find "$dir" -gid $DOCKER_GID -exec chgrp -h docker {} + 2>/dev/null || true
        fi
    done

    print_info "Migration completed successfully!"
    print_info "Docker group: $DOCKER_GID -> 999"
fi

# Verify the change
NEW_DOCKER_GID=$(getent group docker | cut -d: -f3)
print_info "New Docker GID: $NEW_DOCKER_GID"

# Show Docker socket permissions
if [ -e /var/run/docker.sock ]; then
    print_info "Docker socket permissions:"
    ls -l /var/run/docker.sock
fi

print_warning "You may need to restart Docker service: sudo systemctl restart docker"
print_warning "Users in the docker group may need to log out and back in for changes to take effect."
