# qemu-arm-rpi

# QEMU Embedded Linux (Raspberry Pi OS) - ARM32 Emulation Setup

## Overview
This script automates the following process:

- Installs QEMU if not already installed.
- Creates a working directory.
- Downloads the Raspberry Pi OS image (Legacy) and a compatible QEMU kernel. 
- Extracts the OS image.
- Identifies the correct partition offset to modify system files.
- Mounts the image to disable `/etc/ld.so.preload`.
- Boots the Raspberry Pi OS in QEMU.

---

## Download Sources

### **Raspberry Pi OS Image (Legacy) (Bullseye, 2024-10-22)**
- **URL:** [Raspberry Pi OS Download Webpage](https://www.raspberrypi.com/software/operating-systems/)
- ***URL:*** [Raspberry Pi OS (Legacy) - Direct Download](https://downloads.raspberrypi.com/raspios_oldstable_armhf/images/raspios_oldstable_armhf-2024-10-28/2024-10-22-raspios-bullseye-armhf.img.xz)

### **QEMU-Compatible Raspberry Pi Kernel**
- **URL:** [GitHub qemu-rpi-kernel Repo](https://github.com/dhruvvyas90/qemu-rpi-kernel)
- ***URL:*** [GitHub qemu-rpi-kernel - Direct Download](https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.4.34-jessie)

---

## Manual Installation Steps

### **Step 1: Install QEMU**
```bash
sudo apt-get update
sudo apt-get install -y qemu-system
```

### **Step 2: Create a Working Directory**
```bash
mkdir -p QEMU && cd QEMU
```

### **Step 3: Download Required Files**
```bash
wget -nc https://downloads.raspberrypi.com/raspios_oldstable_armhf/images/raspios_oldstable_armhf-2024-10-28/2024-10-22-raspios-bullseye-armhf.img.xz
wget -nc https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.4.34-jessie
```

### **Step 4: Extract the Raspberry Pi OS Image**
```bash
unxz -k 2024-10-22-raspios-bullseye-armhf.img.xz
```

### **Step 5: Identify the Root Filesystem Partition Offset**
```bash
fdisk -l 2024-10-22-raspios-bullseye-armhf.img | grep Linux | awk '{print $2}'
```
- Multiply the output value by `512` to get the byte offset.
- Example: If output is `532480`, then:
```bash
echo $((532480 * 512))
```
- This should return `272629760` (byte offset for mounting).

### **Step 6: Mount the Image and Modify System Files**
```bash
mkdir -p tmp
sudo mount -o loop,offset=272629760 -t ext4 2024-10-22-raspios-bullseye-armhf.img tmp
```

### **Step 7: Disable `/etc/ld.so.preload`**
```bash
if [[ -f tmp/etc/ld.so.preload ]]; then
    sudo sed -i 's|^/#|#|' tmp/etc/ld.so.preload
fi
```
* The libraries in /etc/ld.so.preload are for real Raspberry Pi hardware, but QEMU emulates a different system, so we must disable them to avoid any compatibility issues.

### **Step 8: Unmount the Image and Clean Up**
```bash
sudo umount tmp
rmdir tmp
```

### **Step 9: Run Raspberry Pi OS in QEMU**
```bash
qemu-system-arm \
    -M versatilepb \
    -cpu arm1176 \
    -m 256 \
    -kernel kernel-qemu-4.4.34-jessie \
    -serial stdio \
    -append "root=/dev/sda2 rootfstype=ext4 rw" \
    -drive file=2024-10-22-raspios-bullseye-armhf.img,format=raw
```

### **Step 10: Access the Raspberry Pi OS in QEMU**
Once the QEMU instance boots successfully, you should see the Raspberry Pi OS boot process and be able to interact with the emulated environment.

---

## Notes
- The script automates all of the above steps.
- If the `ld.so.preload` file is not modified, QEMU may fail to boot properly.
- The kernel used (`kernel-qemu-4.4.34-jessie`) is a known working version for Raspberry Pi OS in QEMU.
- To re-run QEMU later, navigate to the working directory (`QEMU/`) and execute **Step 9** again.

---


