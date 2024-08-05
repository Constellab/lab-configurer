#!/bin/bash

# This file is for mounting disk on Azure, it uses the LUN 
# number instead of the disk name because the disk name is different 
# between the VMs

# declare variable folder with value /app
MOUNT_POINT=/app
LUN_NUMBER=$1

DISK_NAME=/dev/disk/azure/scsi1/lun$LUN_NUMBER
DISK_PART_NAME=/dev/disk/azure/scsi1/lun$LUN_NUMBER-part1

# Check if /app is mounted
if cat /proc/mounts | grep -q $MOUNT_POINT; then
# if grep -qs "$folder" /proc/mounts; then
    echo "Disk $LUN_NUMBER already mounted"
    exit 0
fi


echo "Mount disk $DISK_NAME"

if [[ ! -d $MOUNT_POINT ]]; then
    echo "Create folder $MOUNT_POINT"
    sudo mkdir -p $MOUNT_POINT
fi

sudo parted $DISK_NAME mklabel gpt
sudo parted $DISK_NAME mkpart primary ext4 0% 100%
# wait 5 seconds for the partition to be created
sleep 5

# Check if there is a filesystem present on the disk
if ! sudo blkid $DISK_PART_NAME | grep -q 'TYPE'; then
    sudo mkfs.ext4 $DISK_PART_NAME
else
    echo "Disk $DISK_PART_NAME already formatted, skipping format."
fi

sudo mount $DISK_PART_NAME $MOUNT_POINT

# Add the mount to the fstab file so it gets mounted after reboot
echo "$DISK_PART_NAME $MOUNT_POINT ext4 defaults 0 2" | sudo tee -a /etc/fstab

# Check if the mount was successful
if mountpoint -q "$MOUNT_POINT"; then
    echo "Azure Data Disk mounted successfully to $MOUNT_POINT."
    exit 0
else
    echo "Failed to mount the Azure Data Disk."
    exit 1
fi
