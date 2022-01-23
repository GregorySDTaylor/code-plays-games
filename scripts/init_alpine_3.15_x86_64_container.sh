#!/bin/bash

# Alpine Linux in a chroot: https://wiki.alpinelinux.org/wiki/Alpine_Linux_in_a_chroot
# fully-featured implementation: https://github.com/alpinelinux/alpine-chroot-install/

if (( $EUID != 0 )); then
    echo "failed: this script can only be run as root"
    exit
fi

if [ "$1" = "" ]
then
    echo "failed: this script requires a container name argument"
    exit
fi

PROJECT_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
CONTAINER_DIRECTORY=$PROJECT_DIRECTORY/containers/$1

# https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch06.html#devDevicesAndSpecialFiles
echo "creating the devices and special files mount..."
mount -o bind,ro /dev $CONTAINER_DIRECTORY/dev
# https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch06.html#procKernelAndProcessInformationVir
echo "creating the kernel and process information mount..."
mount -t proc,ro none $CONTAINER_DIRECTORY/proc
# https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch06.html#sysKernelAndSystemInformation
echo "creating the kernel and system information mount..."
mount -o bind,ro /sys $CONTAINER_DIRECTORY/sys