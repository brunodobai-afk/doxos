#!/usr/bin/env bash
# ==============================================================================
#  DOXos - "Those Who Dare"
#  Automated Debian Live ISO Generator
# ==============================================================================
set -euo pipefail

# Configuration
DISTRO_NAME="DOXos"
DISTRO_VERSION="1.0"
CODENAME="bookworm"
DEBIAN_MIRROR="http://deb.debian.org/debian"
SECURITY_MIRROR="http://security.debian.org/debian-security"

WORK_DIR="$(pwd)/build_work"
CHROOT_DIR="${WORK_DIR}/chroot"
LIVE_IMAGE_DIR="${WORK_DIR}/iso_root"
OUTPUT_ISO="$(pwd)/DOXos-${DISTRO_VERSION}-amd64.iso"

# Require root
if [ "${EUID}" -ne 0 ]; then
    echo "[!] Error: build.sh must be executed with root privileges (sudo)." >&2
    exit 1
fi

echo "=========================================================="
echo " Starting DOXos ${DISTRO_VERSION} Build Pipeline"
echo " Motto: Those Who Dare"
echo "=========================================================="

# 1. Install build host dependencies
echo "[*] Step 1/7: Installing build dependencies on host..."
apt-get update -qq
apt-get install -y -qq \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    dosfstools \
    curl \
    gnupg \
    python3

# 2. Cleanup previous build artifacts
echo "[*] Step 2/7: Cleaning previous build trees..."
umount -lf "${CHROOT_DIR}/sys" 2>/dev/null || true
umount -lf "${CHROOT_DIR}/proc" 2>/dev/null || true
umount -lf "${CHROOT_DIR}/dev/pts" 2>/dev/null || true
umount -lf "${CHROOT_DIR}/dev" 2>/dev/null || true
rm -rf "${WORK_DIR}"
mkdir -p "${CHROOT_DIR}" "${LIVE_IMAGE_DIR}/live" "${LIVE_IMAGE_DIR}/boot/grub"

# 3. Debootstrap Debian base system
echo "[*] Step 3/7: Bootstrapping Debian ${CODENAME} base system..."
debootstrap --arch=amd64 --variant=minbase "${CODENAME}" "${CHROOT_DIR}" "${DEBIAN_MIRROR}"

# 4. Prepare chroot virtual filesystems
echo "[*] Step 4/7: Mounting filesystems and configuring repositories..."
mount --bind /dev "${CHROOT_DIR}/dev"
mount --bind /dev/pts "${CHROOT_DIR}/dev/pts"
mount --bind /proc "${CHROOT_DIR}/proc"
mount --bind /sys "${CHROOT_DIR}/sys"

# Set up hostname and hosts
echo "doxos" > "${CHROOT_DIR}/etc/hostname"
cat << 'EOF' > "${CHROOT_DIR}/etc/hosts"
127.0.0.1   localhost
127.0.1.1   doxos

::1         localhost ip6-localhost ip6-loopback
EOF

# Set up APT Sources (with 32-bit i386, non-free, and contrib for Steam)
cat << EOF > "${CHROOT_DIR}/etc/apt/sources.list"
deb ${DEBIAN_MIRROR} ${CODENAME} main contrib non-free non-free-firmware
deb-src ${DEBIAN_MIRROR} ${CODENAME} main contrib non-free non-free-firmware

deb ${DEBIAN_MIRROR} ${CODENAME}-updates main contrib non-free non-free-firmware
deb-src ${DEBIAN_MIRROR} ${CODENAME}-updates main contrib non-free non-free-firmware

deb ${SECURITY_MIRROR} ${CODENAME}-security main contrib non-free non-free-firmware
deb-src ${SECURITY_MIRROR} ${CODENAME}-security main contrib non-free non-free-firmware
EOF

# Brave Browser official repository signing key
mkdir -p "${CHROOT_DIR}/etc/apt/keyrings"
curl -fsSLo "${CHROOT_DIR}/etc/apt/keyrings/brave-browser-archive-keyring.gpg" \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
    > "${CHROOT_DIR}/etc/apt/sources.list.d/brave-browser-release.list"

# Copy project branding and configs into chroot
mkdir -p "${CHROOT_DIR}/etc/doxos"
mkdir -p "${CHROOT_DIR}/etc/sysctl.d"
mkdir -p "${CHROOT_DIR}/etc/systemd/system"
mkdir -p "${CHROOT_DIR}/etc/skel/.config/fastfetch"
mkdir -p "${CHROOT_DIR}/etc/skel/.config/autostart"
mkdir -p "${CHROOT_DIR}/usr/local/bin"
mkdir -p "${CHROOT_DIR}/usr/share/sounds/doxos"

cp config/branding/logo.txt "${CHROOT_DIR}/etc/doxos/logo.txt"
cp config/branding/logo.txt "${CHROOT_DIR}/etc/issue"
cp config/branding/logo.txt "${CHROOT_DIR}/etc/issue.net"
cp config/skel/.config/fastfetch/config.jsonc "${CHROOT_DIR}/etc/doxos/fastfetch.jsonc"
cp config/skel/.config/fastfetch/config.jsonc "${CHROOT_DIR}/etc/skel/.config/fastfetch/config.jsonc"
cp config/skel/.config/autostart/doxos-beep.desktop "${CHROOT_DIR}/etc/skel/.config/autostart/doxos-beep.desktop"
cp config/skel/.bashrc "${CHROOT_DIR}/etc/skel/.bashrc"
cp config/os-release "${CHROOT_DIR}/etc/os-release"
cp config/sysctl.d/99-doxos-gaming.conf "${CHROOT_DIR}/etc/sysctl.d/99-doxos-gaming.conf"
cp scripts/doxos-beep.sh "${CHROOT_DIR}/usr/local/bin/doxos-beep"
chmod +x "${CHROOT_DIR}/usr/local/bin/doxos-beep"
cp config/systemd/doxos-beep.service "${CHROOT_DIR}/etc/systemd/system/doxos-beep.service"

# Generate 3-beep sound file inside chroot
python3 scripts/generate-beep.py
cp /usr/share/sounds/doxos/doxos-beep.wav "${CHROOT_DIR}/usr/share/sounds/doxos/doxos-beep.wav" 2>/dev/null || true

# 5. Execute internal configuration inside chroot
echo "[*] Step 5/7: Installing packages and configuring live desktop inside chroot..."
cp config/packages.list "${CHROOT_DIR}/tmp/packages.list"

chroot "${CHROOT_DIR}" /bin/bash << 'CHROOT_EOF'
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

# Add 32-bit architecture for Steam & Proton gaming
dpkg --add-architecture i386
apt-get update

# Install all packages
grep -v '^#' /tmp/packages.list | grep -v '^$' | xargs apt-get install -y --no-install-recommends

# Create default live user "dox" with sudo access (password: dox)
useradd -m -s /bin/bash -g users -G sudo,audio,video,plugdev,netdev dox
echo "dox:dox" | chpasswd
echo "root:root" | chpasswd
echo "dox ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/dox
chmod 0440 /etc/sudoers.d/dox

# Enable essential systemd services
systemctl enable NetworkManager.service
systemctl enable lightdm.service
systemctl enable doxos-beep.service

# Clean up apt caches to minimize ISO size
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
CHROOT_EOF

# 6. Extract kernel and create SquashFS root
echo "[*] Step 6/7: Compressing root filesystem into SquashFS..."
# Copy kernel and initrd for live bootloader
VMLINUZ="$(ls -1 ${CHROOT_DIR}/boot/vmlinuz-* | tail -n1)"
INITRD="$(ls -1 ${CHROOT_DIR}/boot/initrd.img-* | tail -n1)"
cp "${VMLINUZ}" "${LIVE_IMAGE_DIR}/live/vmlinuz"
cp "${INITRD}" "${LIVE_IMAGE_DIR}/live/initrd"

# Unmount chroot
umount -lf "${CHROOT_DIR}/sys"
umount -lf "${CHROOT_DIR}/proc"
umount -lf "${CHROOT_DIR}/dev/pts"
umount -lf "${CHROOT_DIR}/dev"

# Compress rootfs
mksquashfs "${CHROOT_DIR}" "${LIVE_IMAGE_DIR}/live/filesystem.squashfs" \
    -comp xz -Xbcj x86 -b 1048576 -noappend

# 7. Configure GRUB bootloader and build final Hybrid ISO
echo "[*] Step 7/7: Assembling bootloader and burning ISO image..."

# Create GRUB configuration (Black & White aesthetic)
cat << 'EOF' > "${LIVE_IMAGE_DIR}/boot/grub/grub.cfg"
set default=0
set timeout=5

insmod font
if loadfont /boot/grub/fonts/unicode.pf2 ; then
    insmod gfxterm
    set gfxmode=auto
    terminal_output gfxterm
fi

# Monochrome high-contrast colors
set menu_color_normal=white/black
set menu_color_highlight=black/white

menuentry "DOXos 1.0 (Live Session) - Those Who Dare" {
    linux /live/vmlinuz boot=live quiet splash components
    initrd /live/initrd
}

menuentry "DOXos 1.0 (Safe Graphics / Failsafe)" {
    linux /live/vmlinuz boot=live nomodeset components
    initrd /live/initrd
}

menuentry "System Restart" {
    reboot
}

menuentry "System Poweroff" {
    halt
}
EOF

# Build EFI image for UEFI systems
mkdir -p "${LIVE_IMAGE_DIR}/EFI/BOOT"
grub-mkstandalone \
    --format=x86_64-efi \
    --output="${LIVE_IMAGE_DIR}/EFI/BOOT/BOOTX64.EFI" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=${LIVE_IMAGE_DIR}/boot/grub/grub.cfg"

# Package into bootable Hybrid ISO (BIOS + UEFI)
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "DOXOS_LIVE" \
    -eltorito-boot boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --eltorito-catalog boot/grub/boot.cat \
    --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-alt-boot \
    -e EFI/BOOT/BOOTX64.EFI \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -output "${OUTPUT_ISO}" \
    "${LIVE_IMAGE_DIR}"

echo "=========================================================="
echo " [SUCCESS] DOXos ISO Generated Successfully!"
echo " Output: ${OUTPUT_ISO}"
echo " Default Live User: dox | Password: dox (sudo enabled)"
echo " 'Those Who Dare'"
echo "=========================================================="
