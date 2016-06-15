#
# Build and Setup RPi3 Kernel using rpidate
#

# Load utility functions
. ./functions.sh

# rpidate
mkdir -p "${R}/lib/modules"
curl -L --output /usr/bin/rpi-update https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update
chmod +x /usr/bin/rpi-update
SKIP_BACKUP=1 UPDATE_SELF=0 BOOT_PATH="${BOOTDIR}" ROOT_PATH="${R}" rpi-update

# Setup firmware boot cmdline
if [ "$ENABLE_SPLITFS" = true ] ; then
  CMDLINE="dwc_otg.lpm_enable=0 root=/dev/sda1 rootfstype=ext4 rootflags=commit=100,data=writeback elevator=deadline rootwait net.ifnames=1 console=tty1 ${CMDLINE}"
else
  CMDLINE="dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2 rootfstype=ext4 rootflags=commit=100,data=writeback elevator=deadline rootwait net.ifnames=1 console=tty1 ${CMDLINE}"
fi

# Add encrypted root partition to cmdline.txt
if [ "$ENABLE_CRYPTFS" = true ] ; then
  if [ "$ENABLE_SPLITFS" = true ] ; then
    CMDLINE=$(echo ${CMDLINE} | sed "s/sda1/mapper\/${CRYPTFS_MAPPING} cryptdevice=\/dev\/sda1:${CRYPTFS_MAPPING}/")
  else
    CMDLINE=$(echo ${CMDLINE} | sed "s/mmcblk0p2/mapper\/${CRYPTFS_MAPPING} cryptdevice=\/dev\/mmcblk0p2:${CRYPTFS_MAPPING}/")
  fi
fi

# Add serial console support
if [ "$ENABLE_CONSOLE" = true ] ; then
  CMDLINE="${CMDLINE} console=ttyAMA0,115200 kgdboc=ttyAMA0,115200"
fi

# Remove IPv6 networking support
if [ "$ENABLE_IPV6" = false ] ; then
  CMDLINE="${CMDLINE} ipv6.disable=1"
fi

# Install firmware boot cmdline
echo "${CMDLINE}" > "${BOOTDIR}/cmdline.txt"

# Install firmware config
install_readonly files/boot/config.txt "${BOOTDIR}/config.txt"

# Setup minimal GPU memory allocation size: 16MB (no X)
if [ "$ENABLE_MINGPU" = true ] ; then
  echo "gpu_mem=16" >> "${BOOTDIR}/config.txt"
fi

# Setup boot with initramfs
if [ "$ENABLE_INITRAMFS" = true ] ; then
  echo "initramfs initramfs-${KERNEL_VERSION} followkernel" >> "${BOOTDIR}/config.txt"
fi

# Create firmware configuration and cmdline symlinks
ln -sf firmware/config.txt "${R}/boot/config.txt"
ln -sf firmware/cmdline.txt "${R}/boot/cmdline.txt"

# Install and setup kernel modules to load at boot
mkdir -p "${R}/lib/modules-load.d/"
install_readonly files/modules/rpi2.conf "${R}/lib/modules-load.d/rpi2.conf"

# Load hardware random module at boot
if [ "$ENABLE_HWRANDOM" = true ] && [ "$BUILD_KERNEL" = false ] ; then
  sed -i "s/^# bcm2708_rng/bcm2708_rng/" "${R}/lib/modules-load.d/rpi2.conf"
fi

# Load sound module at boot
if [ "$ENABLE_SOUND" = true ] ; then
  sed -i "s/^# snd_bcm2835/snd_bcm2835/" "${R}/lib/modules-load.d/rpi2.conf"
fi

# Install kernel modules blacklist
mkdir -p "${ETCDIR}/modprobe.d/"
install_readonly files/modules/raspi-blacklist.conf "${ETCDIR}/modprobe.d/raspi-blacklist.conf"

# Install and setup fstab
install_readonly files/mount/fstab "${ETCDIR}/fstab"

# Add usb/sda disk root partition to fstab
if [ "$ENABLE_SPLITFS" = true ] && [ "$ENABLE_CRYPTFS" = false ] ; then
  sed -i "s/mmcblk0p2/sda1/" "${ETCDIR}/fstab"
fi

# Add encrypted root partition to fstab and crypttab
if [ "$ENABLE_CRYPTFS" = true ] ; then
  # Replace fstab root partition with encrypted partition mapping
  sed -i "s/mmcblk0p2/mapper\/${CRYPTFS_MAPPING}/" "${ETCDIR}/fstab"

  # Add encrypted partition to crypttab and fstab
  install_readonly files/mount/crypttab "${ETCDIR}/crypttab"
  echo "${CRYPTFS_MAPPING} /dev/mmcblk0p2 none luks" >> "${ETCDIR}/crypttab"

  if [ "$ENABLE_SPLITFS" = true ] ; then
    # Add usb/sda disk to crypttab
    sed -i "s/mmcblk0p2/sda1/" "${ETCDIR}/crypttab"
  fi
fi

# Generate initramfs file
if [ "$ENABLE_INITRAMFS" = true ] ; then
  if [ "$ENABLE_CRYPTFS" = true ] ; then
    # Include initramfs scripts to auto expand encrypted root partition
    if [ "$EXPANDROOT" = true ] ; then
      install_exec files/initramfs/expand_encrypted_rootfs "${ETCDIR}/initramfs-tools/scripts/init-premount/expand_encrypted_rootfs"
      install_exec files/initramfs/expand-premount "${ETCDIR}/initramfs-tools/scripts/local-premount/expand-premount"
      install_exec files/initramfs/expand-tools "${ETCDIR}/initramfs-tools/hooks/expand-tools"
    fi

    # Disable SSHD inside initramfs
    printf "#\n# DROPBEAR: [ y | n ]\n#\n\nDROPBEAR=n\n" >> "${ETCDIR}/initramfs-tools/initramfs.conf"

    # Dummy mapping required by mkinitramfs
    echo "0 1 crypt $(echo ${CRYPTFS_CIPHER} | cut -d ':' -f 1) ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff 0 7:0 4096" | chroot_exec dmsetup create "${CRYPTFS_MAPPING}"

    # Generate initramfs with encrypted root partition support
    chroot_exec mkinitramfs -o "/boot/firmware/initramfs-${KERNEL_VERSION}" "${KERNEL_VERSION}"

    # Remove dummy mapping
    chroot_exec cryptsetup close "${CRYPTFS_MAPPING}"
  else
    # Generate initramfs without encrypted root partition support
    chroot_exec mkinitramfs -o "/boot/firmware/initramfs-${KERNEL_VERSION}" "${KERNEL_VERSION}"
  fi
fi

# Install sysctl.d configuration files
install_readonly files/sysctl.d/81-rpi-vm.conf "${ETCDIR}/sysctl.d/81-rpi-vm.conf"
