#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update package list and install QEMU
echo "Updating package list and installing QEMU..."
sudo apt-get update
sudo apt-get install -y qemu-system

# Create a working directory for QEMU and navigate into it
WORKDIR=QEMU
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Define file names
IMG_FILE=2024-10-22-raspios-bullseye-armhf.img
IMG_XZ_FILE=${IMG_FILE}.xz
KERNEL_FILE=kernel-qemu-4.4.34-jessie

# Download Raspberry Pi OS image if not already downloaded
echo "Downloading Raspberry Pi OS (Bullseye) image..."
wget -nc "https://downloads.raspberrypi.com/raspios_oldstable_armhf/images/raspios_oldstable_armhf-2024-10-28/${IMG_XZ_FILE}"

# Download QEMU-compatible Raspberry Pi kernel if not already downloaded
echo "Downloading QEMU-compatible Raspberry Pi kernel..."
wget -nc "https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/${KERNEL_FILE}"

# Extract the Raspberry Pi OS image
if [[ ! -f "$IMG_FILE" ]]; then
    echo "Extracting Raspberry Pi OS image..."
    unxz "$IMG_XZ_FILE"
fi

# Find partition offset
echo "Finding partition offset..."
SECTOR_OFFSET=$(fdisk -l "$IMG_FILE" | grep Linux | awk '{print $2}')
OFFSET=$((SECTOR_OFFSET * 512))

# Mount the image and modify /etc/ld.so.preload
MOUNT_DIR=tmp
mkdir -p "$MOUNT_DIR"
sudo mount -o loop,offset=$OFFSET -t ext4 "$IMG_FILE" "$MOUNT_DIR"

echo "Disabling /etc/ld.so.preload..."
if [[ -f "$MOUNT_DIR/etc/ld.so.preload" ]]; then
    sudo sed -i 's|^/#|#|' "$MOUNT_DIR/etc/ld.so.preload"
fi

# Unmount the modified image
echo "Unmounting modified image..."
sudo umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"

# Boot Raspberry Pi OS in QEMU
echo "Booting Raspberry Pi OS in QEMU..."
qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256 \
    -kernel "$KERNEL_FILE" \
    -serial stdio \
    -append "root=/dev/sda2 rootfstype=ext4 rw" \
    -drive file="$IMG_FILE",format=raw

echo "QEMU Raspberry Pi OS boot complete!"


