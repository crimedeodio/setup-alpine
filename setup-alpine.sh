#!/bin/sh

username="user"
user_password="userpass"
root_password="rootpass"

hostname="alpine"
keymap="us us"
timezone="UTC"
kernel="stable"

disk="/dev/sda"
root_filesystem="f2fs"
swap="0"
bootloader="limine"

repository="1"
version="edge"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

patch /usr/sbin/setup-disk "$SCRIPT_DIR/setup-disk.patch"

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

partnum=$(( swap > 0 ? 3 : 2 ))
case $disk in
  *[0-9]) root_part="${disk}p${partnum}" ;;
  *)      root_part="${disk}${partnum}"   ;;
esac

umount -R /mnt 2>/dev/null || true
mount "$root_part" /mnt

echo $hostname > /mnt/etc/hostname
cp -r "$SCRIPT_DIR/nitro" /mnt/tmp/nitro

chroot /mnt /bin/sh << EOF
echo "$username:$user_password" | chpasswd
echo "root:$root_password" | chpasswd

apk --no-cache --quiet add \
  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  nitro-init eiwd agetty

mkdir -p /etc/nitro
cp -r /tmp/nitro/. /etc/nitro/
rm -rf /tmp/nitro

for i in 1 2 3; do
  ln -sf agetty@ /etc/nitro/agetty@tty\$i
done

ln -sf /usr/sbin/nitro /sbin/init
EOF

umount /mnt