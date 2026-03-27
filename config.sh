#!/bin/sh

# credentials
username="user"
user_password="userpass"
root_password="rootpass"

# system
hostname="alpine"
kernel="lts" #  lts, virt, stable, rpi, openpax
bootloader="limine" # grub, syslinux, *limine*
keymap="us us"
timezone="UTC"

# disk
disk="/dev/sda"
root_filesystem="ext4" #ext[2-4], btrfs, xfs, *f2fs*
swap="0" # 0 to disable

# repository
repository="1" # 1 = cdn, f = fastest, r = random
version="edge"

# services
AGETTY_TTYS=6           # number of virtual consoles to activate
INSTALL_DBUS=true
INSTALL_BLUETOOTH=true  # requires INSTALL_DBUS=true; installs: bluez
INSTALL_IWD=true        # requires INSTALL_DBUS=true; installs: iwd
INSTALL_DROPBEAR=true   # SSH; installs: dropbear
INSTALL_ACPID=true