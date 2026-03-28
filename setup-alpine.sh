#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/config.sh"

if { [ "$INSTALL_BLUETOOTH" = true ] || [ "$INSTALL_IWD" = true ]; } \
    && [ "$INSTALL_DBUS" != true ]; then
    echo "ERROR: BLUETOOTH and IWD require INSTALL_DBUS=true" >&2
    exit 1
fi

git apply -p1 --directory=/usr/sbin --unsafe-paths "$SCRIPT_DIR/setup-disk.patch"

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
    *)      root_part="${disk}${partnum}"  ;;
esac

umount /mnt 2>/dev/null || true
mount "$root_part" /mnt

echo "$hostname" > /mnt/tmp/hostname

NITRO_SERVICES="SYS LOG mdev hostname agetty@"

[ "$INSTALL_DBUS"      = true ] && NITRO_SERVICES="$NITRO_SERVICES dbus"
[ "$INSTALL_BLUETOOTH" = true ] && NITRO_SERVICES="$NITRO_SERVICES bluetoothd"
[ "$INSTALL_IWD"       = true ] && NITRO_SERVICES="$NITRO_SERVICES iwd"
[ "$INSTALL_DROPBEAR"  = true ] && NITRO_SERVICES="$NITRO_SERVICES dropbear"
[ "$INSTALL_ACPID"     = true ] && NITRO_SERVICES="$NITRO_SERVICES acpid"

mkdir -p /mnt/tmp/nitro
for svc in $NITRO_SERVICES; do
    cp -r "$SCRIPT_DIR/nitro/$svc" /mnt/tmp/nitro/
done

PACKAGES="nitro-init agetty"
[ "$INSTALL_DBUS"      = true ] && PACKAGES="$PACKAGES dbus"
[ "$INSTALL_BLUETOOTH" = true ] && PACKAGES="$PACKAGES bluez"
[ "$INSTALL_IWD"       = true ] && PACKAGES="$PACKAGES iwd"
[ "$INSTALL_DROPBEAR"  = true ] && PACKAGES="$PACKAGES dropbear"

chroot /mnt /bin/sh << EOF
set -e

echo "$username:$user_password" | chpasswd
echo "root:$root_password"      | chpasswd

apk --no-cache --quiet add \
    --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
    $PACKAGES

mkdir -p /etc/nitro
cp -r /tmp/nitro/. /etc/nitro/
rm -rf /tmp/nitro

cp /tmp/hostname /etc/hostname
rm  /tmp/hostname

# dbus
if [ "$INSTALL_DBUS" = true ]; then
    addgroup -S messagebus 2>/dev/null || true
    adduser -S -D -H -h /dev/null -s /sbin/nologin \
        -G messagebus -g messagebus messagebus 2>/dev/null || true
fi

# iwd
if [ "$INSTALL_IWD" = true ]; then
    mkdir -p /etc/iwd
    cat > /etc/iwd/main.conf << IWD
[General]
EnableNetworkConfiguration=true
NameResolvingService=none

[DriverQuirks]
DefaultInterface=true
IWD
fi

# agetty
for i in \$(seq $AGETTY_TTYS); do
    ln -sf agetty@ /etc/nitro/agetty@tty\$i
done

ln -sf /usr/sbin/nitro /sbin/init
echo "" > /etc/motd
EOF

umount /mnt

clear
echo "installation is complete. please reboot."