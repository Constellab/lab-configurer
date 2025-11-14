#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


echo "[INFO] Starting access rights migration..."

echo "[INFO] Stopping docker containers..."
sudo systemctl stop docker
sudo systemctl stop docker.socket
echo "[INFO] Docker containers stopped"

# Change ownership of /app to $USER:$USER, excluding /app/dev/etc-ssh and mariadb directories
echo "[INFO] Changing ownership of /app to $USER:$USER..."
sudo find /app -path /app/dev/etc-ssh -prune -o -path /app/gws_db/gws_core/prod/mariadb -prune -o -path /app/gws_db/gws_core/dev/mariadb -prune -o -path /app/gws_db/gws_biota/mariadb -prune -o -path /app/docker -prune -o -exec chown -h $USER:$USER {} +
echo "[INFO] Ownership change completed"

# Change ownership of /app/dev/etc-ssh to root:root
echo "[INFO] Changing ownership of /app/dev/etc-ssh to root:root..."
sudo chown -R root:root /app/dev/etc-ssh
echo "[INFO] Ownership change completed"

# Set permissions for /app/prod/data/filestore and children
echo "[INFO] Setting permissions for filestore and its children..."

# Set permissions for filestore directory and children
if [ -d "/app/prod/data/filestore" ]; then
    sudo find /app/prod/data/filestore -type d -exec chmod 755 {} +
    sudo find /app/prod/data/filestore -type f -exec chmod 644 {} +
fi

if [ -d "/app/dev/data/filestore" ]; then
    sudo find /app/dev/data/filestore -type d -exec chmod 755 {} +
    sudo find /app/dev/data/filestore -type f -exec chmod 644 {} +
fi

# Move logs directories if they exist
if [ -d "/app/prod/logs" ]; then
    echo "[INFO] Moving /app/prod/logs to /app/prod/lab/.sys/logs..."
    mv /app/prod/logs /app/prod/lab/.sys/logs
    echo "[INFO] Move completed"
else
    echo "[INFO] /app/prod/logs does not exist, skipping..."
fi

if [ -d "/app/dev/logs" ]; then
    echo "[INFO] Moving /app/dev/logs to /app/dev/lab/.sys/logs..."
    mv /app/dev/logs /app/dev/lab/.sys/logs
    echo "[INFO] Move completed"
else
    echo "[INFO] /app/dev/logs does not exist, skipping..."
fi

# Migrate docker GID to 999
echo "[INFO] Migrating docker GID to 999..."
sudo bash "${SCRIPT_DIR}/utils/ensure_docker_gid.sh"
echo "[INFO] Docker GID migration completed"

# this seems useful to allow lab manager to access docker socket
echo "[INFO] Restart docker system services..."
sudo systemctl start docker

echo "[INFO] Access rights migration completed successfully"

