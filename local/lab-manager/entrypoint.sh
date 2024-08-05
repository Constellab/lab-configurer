#!/bin/sh

# start docker
service docker start

echo "Dev environment for lab-manager ready!"

# prevent the image to stop
tail -f /dev/null