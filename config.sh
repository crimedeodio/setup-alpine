#!/bin/sh

# credentials
username="user"
user_password="userpass"
root_password="rootpass"

# system
hostname="alpine"
kernel="lts"            #  lts, virt, stable, rpi, openpax
bootloader="limine"     # grub, syslinux, *limine*
keymap="us us"
timezone="UTC"

# disk
disk="/dev/sda"
root_filesystem="ext4"  # ext[2-4], btrfs, xfs, *f2fs*
swap="0"                # 0 to disable

# repository
repository="1"          # 1 = cdn, f = fastest, r = random
version="edge"

# services
agetty_ttys=6           # number of virtual consoles to activate
install_dbus=true
install_bluetooth=true  # requires install_dbus=true; installs: bluez
install_iwd=true        # requires install_dbus=true; installs: iwd
install_dropbear=true   # SSH; installs: dropbear
install_acpid=true