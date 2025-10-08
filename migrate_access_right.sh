#!/bin/bash

echo "[INFO] Starting access rights migration..."

# Change ownership of /app to ubuntu:ubuntu, excluding /app/dev/etc-ssh and mariadb directories
echo "[INFO] Changing ownership of /app to ubuntu:ubuntu..."
sudo find /app -path /app/dev/etc-ssh -prune -o -path /app/gws_db/gws_core/prod/mariadb -prune -o -path /app/gws_db/gws_core/dev/mariadb -prune -o -path /app/gws_db/gws_biota/mariadb -prune -o -path /app/docker -prune -o -exec chown ubuntu:ubuntu {} +
echo "[INFO] Ownership change completed"

# Change ownership of /app/dev/etc-ssh to root:root
echo "[INFO] Changing ownership of /app/dev/etc-ssh to root:root..."
sudo chown -R root:root /app/dev/etc-ssh
echo "[INFO] Ownership change completed"

# Set permissions for /app/prod/data/filestore and children
echo "[INFO] Setting permissions for filestore and its children..."

# Set permissions for filestore directory and children
if [ -d "/app/prod/data/filestore" ]; then
    sudo chmod -R 644 /app/prod/data/filestore
fi

if [ -d "/app/dev/data/filestore" ]; then
    sudo chmod -R 644 /app/dev/data/filestore
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

echo "[INFO] Access rights migration completed successfully"
