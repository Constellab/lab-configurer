#!/bin/bash

# sdb for OVH,  with default value sdb
disk=${1:-sdb}
part="${disk}1"

# Check if sdb partition is found
if ! lsblk | grep -q $disk; then
    echo "Disk $disk not found"
    exit 1
fi

# Check if sdb is mounted
if cat /proc/mounts | grep -q $disk; then
    echo "Disk $disk already mounted"
    exit 0
fi

# Check if partition exists
if ! lsblk | grep -q $part; then
    # create the partition
    echo "Create partition $part"
    
    (
    echo o # Create a new empty DOS partition table
    echo n # Add a new partition
    echo p # Primary partition
    echo 1 # Partition number
    echo   # First sector (Accept default: 1)
    echo   # Last sector (Accept default: varies)
    echo w # Write changes
    ) | sudo fdisk /dev/${disk}

    # Check if there is a filesystem present on the disk
    if ! sudo blkid /dev/${part} | grep -q 'TYPE'; then
        # format partition
        sudo mkfs.ext4 -F /dev/${part}
    else
        echo "Disk $DISK_PART_NAME already formatted, skipping format."
    fi
fi

# mount partition
echo "Mount disk $disk"
if ! test -d "/app"; then
    sudo mkdir -p /app
fi

sudo mount /dev/${part} /app

# Check if disk is in fstab
if ! cat /etc/fstab | grep -q $disk; then
    echo "/dev/${part}	/app	ext4	defaults	0	1" | sudo tee -a /etc/fstab
fi