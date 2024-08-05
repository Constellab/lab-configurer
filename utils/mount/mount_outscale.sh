#!/bin/bash

# This file is for mounting disk on Outscale.
# Code from https://docs.outscale.com/en/userguide/Initializing-a-Volume-from-a-VM.html

# declare variable folder with value /app
MOUNT_POINT=/app

DISK_NAME=$1

# Check if /app is mounted
if mount | grep -q $DISK_NAME; then
    echo "Disk $DISK_NAME already mounted"
    exit 0a
fi


if [[ ! -d $MOUNT_POINT ]]; then
    echo "Create folder $MOUNT_POINT"
    sudo mkdir -p $MOUNT_POINT
fi


echo "Mount disk $DISK_NAME"

# Check if there is a filesystem present on the disk
if ! sudo blkid $DISK_PART_NAME | grep -q 'TYPE'; then
    sudo mkfs.ext4 $DISK_PART_NAME
else
    echo "Disk $DISK_PART_NAME already formatted, skipping format."
fi

sudo mount $DISK_NAME $MOUNT_POINT

# Add the mount to the fstab file so it gets mounted after reboot
echo "$DISK_NAME $MOUNT_POINT    xfs defaults,nofail 0   2" | sudo tee -a /etc/fstab

# Check if the mount was successful
if mountpoint -q "$MOUNT_POINT"; then
    echo "Azure Data Disk mounted successfully to $MOUNT_POINT."
    exit 0
else
    echo "Failed to mount the Azure Data Disk."
    exit 1
fi
