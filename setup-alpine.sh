#!/bin/sh

username="user"
user_password="userpass"
root_password="rootpass"

hostname="alpine"
keymap="us us"
timezone="UTC"
kernel="stable"
# lts, virt, stable, rpi, openpax, asahi,
# elm, gru, eswin, sophgo, p550, starfive,
# jh7100, spacemint

disk="/dev/sda"
root_filesystem="f2fs" # ext[2-4], btrfs, xfs, f2fs
swap="0"               # in MB, 0 to disable
bootloader="limine"    # grub, syslinux, limine

repository="1" # 1: cdn, f: fastest, r: random
version="edge" # latest-stable, edge, etc.

patch /usr/sbin/setup-disk setup-disk.patch

APKREPOSOPTS="-c -$repository" \
BOOTLOADER="$bootloader" \
DISKOPTS="-k $kernel -m sys -s $swap $disk" \
ERASE_DISKS="$disk" \
HOSTNAMEOPTS="$hostname" \
KEYMAPOPTS="$keymap" \
ROOTFS="$root_filesystem" \
TIMEZONEOPTS="$timezone" \
USEROPTS="-a -g audio,input,video,netdev $username" \
INTERFACESOPTS=none \
NTPOPTS=none \
PROXYOPTS=none \
SSHDOPTS=none \
setup-alpine -e

# chroot
partnum=$(( swap > 0 ? 3 : 2 ))
case $disk in
  *[0-9]) root_part="${disk}p${partnum}" ;;
  *)      root_part="${disk}${partnum}"   ;;
esac

mount "$root_part" /mnt

chroot /mnt /bin/sh << EOF
echo "$username:$user_password" | chpasswd
echo "root:$root_password" | chpasswd
EOF

umount /mnt

echo done
# tail -n 1 /etc/apk/repositories | sed 's/community/testing/' >> /etc/apk/repositories 
# apk add nitro-init
# ...