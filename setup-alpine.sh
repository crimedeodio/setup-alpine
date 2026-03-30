#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/config.sh"

if { [ "$install_bluetooth" = true ] || [ "$install_iwd" = true ]; } \
    && [ "$install_dbus" != true ]; then
    echo "ERROR: BLUETOOTH and IWD require install_dbus=true" >&2
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
HOSTNAMEOPTS="$hostname" \
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


NITRO_SERVICES="SYS LOG mdev hostname agetty@ loadkmap"

[ "$install_dbus"      = true ] && NITRO_SERVICES="$NITRO_SERVICES dbus"
[ "$install_bluetooth" = true ] && NITRO_SERVICES="$NITRO_SERVICES bluetoothd"
[ "$install_iwd"       = true ] && NITRO_SERVICES="$NITRO_SERVICES iwd"
[ "$install_dropbear"  = true ] && NITRO_SERVICES="$NITRO_SERVICES dropbear"
[ "$install_acpid"     = true ] && NITRO_SERVICES="$NITRO_SERVICES acpid"

echo "$hostname" > /mnt/tmp/hostname

mkdir -p /mnt/tmp/nitro
for svc in $NITRO_SERVICES; do
    cp -r "$SCRIPT_DIR/nitro/$svc" /mnt/tmp/nitro/
done

PACKAGES="nitro-init agetty doas"
[ "$install_dbus"      = true ] && PACKAGES="$PACKAGES dbus"
[ "$install_bluetooth" = true ] && PACKAGES="$PACKAGES bluez"
[ "$install_iwd"       = true ] && PACKAGES="$PACKAGES iwd"
[ "$install_dropbear"  = true ] && PACKAGES="$PACKAGES dropbear"

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
if [ "$install_dbus" = true ]; then
    addgroup -S messagebus 2>/dev/null || true
    adduser -S -D -H -h /dev/null -s /sbin/nologin \
        -G messagebus -g messagebus messagebus 2>/dev/null || true
    echo "nitroctl up dbus" >> /etc/nitro/SYS/setup
fi

# iwd
if [ "$install_iwd" = true ]; then
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
for i in \$(seq $agetty_ttys); do
    ln -sf agetty@ /etc/nitro/agetty@tty\$i
done

# loadkmap
echo "zcat /etc/keymap/${keymap##* }.bmap.gz | loadkmap" >> /etc/nitro/loadkmap/setup

printf "\nexit 0\n" >> /etc/nitro/SYS/setup
ln -sf /usr/sbin/nitro /sbin/init

echo "" > /etc/motd
EOF

umount /mnt

clear
echo "installation is complete. please reboot."