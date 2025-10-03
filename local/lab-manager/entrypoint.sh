#!/bin/sh

# Change ownership of /app/conf to labuser if it exists
if [ -d "/app/conf" ]; then
    sudo chown -R labuser:labuser /app
    sudo chown -R labuser:labuser /home
fi

# start docker
sudo service docker start

# Fix docker socket permissions for labuser
sudo chmod 666 /var/run/docker.sock

echo "Dev environment for lab-manager ready!"

# prevent the image to stop
tail -f /dev/null