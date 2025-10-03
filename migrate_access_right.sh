#!/bin/bash

echo "[INFO] Starting access rights migration..."

# Change ownership of /app to ubuntu:ubuntu, excluding /app/dev/etc-ssh
echo "[INFO] Changing ownership of /app to ubuntu:ubuntu..."
sudo chown -R ubuntu:ubuntu /app
echo "[INFO] Ownership change completed"

# Change ownership of /app/dev/etc-ssh to root:root
echo "[INFO] Changing ownership of /app/dev/etc-ssh to root:root..."
sudo chown -R root:root /app/dev/etc-ssh
echo "[INFO] Ownership change completed"

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
