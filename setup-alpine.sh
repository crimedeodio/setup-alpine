#!/bin/sh
set -e

patch /usr/sbin/setup-disk setup-disk.patch

ROOTFS="f2fs" \
BOOTLOADER="limine" \
DISKOPTS="-k stable -m sys -s 0" \
setup-alpine