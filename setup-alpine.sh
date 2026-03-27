#!/bin/sh

username="user"
user_password="userpass"
root_password="rootpass"

hostname="alpine"
keymap="us us"
timezone="UTC"
kernel="stable"

disk="/dev/vda"
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
KEYMAPOPTS="$keymap" \
ROOTFS="$root_filesystem" \
TIMEZONEOPTS="$timezone" \
USEROPTS="-a -g audio,input,video,netdev $username" \
HOSTNAMEOPTS=none \
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

echo "$hostname" > /mnt/tmp/hostname
cp -r "$SCRIPT_DIR/nitro" /mnt/tmp/nitro

chroot /mnt /bin/sh << EOF
echo "$username:$user_password" | chpasswd
echo "root:$root_password" | chpasswd

apk --no-cache --quiet add \
  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  nitro-init agetty bluez dbus dropbear iwd

mkdir -p /etc/nitro
cp -r /tmp/nitro/. /etc/nitro/
rm -rf /tmp/nitro

cp /tmp/hostname /etc/hostname
rm /tmp/hostname

addgroup -S messagebus 2>/dev/null
adduser -S -D -H -h /dev/null -s /sbin/nologin -G messagebus -g messagebus messagebus 2>/dev/null

cat > /etc/iwd/main.conf <<IWD
[General]
EnableNetworkConfiguration=true
NameResolvingService=none

[DriverQuirks]
DefaultInterface=true
IWD

for i in \$(seq 3); do
  ln -sf agetty@ /etc/nitro/agetty@tty\$i
done

ln -sf /usr/sbin/nitro /sbin/init

echo "" > /etc/motd
EOF

umount /mnt