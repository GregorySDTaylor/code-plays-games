#!/bin/bash

# Alpine Linux in a chroot: https://wiki.alpinelinux.org/wiki/Alpine_Linux_in_a_chroot
# fully-featured implementation: https://github.com/alpinelinux/alpine-chroot-install/

if (( $EUID != 0 )); then
    echo "failed: this script can only be run as root"
    exit
fi

PROJECT_DIRECTORY=`dirname "$0"`/..
OS_NAME=alpine
SCRIPT_DIRECTORY=$PROJECT_DIRECTORY/scripts
TEMP_DIRECTORY=$SCRIPT_DIRECTORY/${OS_NAME}_temp
TARGET_FSL=$PROJECT_DIRECTORY/file_system_layers/$OS_NAME
MIRROR_HOST_PATH=http://dl-cdn.alpinelinux.org/alpine
ALPINE_VERSION=v3.15
ALPINE_REPOSITORY=$MIRROR_HOST_PATH/$ALPINE_VERSION/main
APK_TOOLS=apk-tools-static-2.12.7-r3
APK_TOOLS_URL=$MIRROR_HOST_PATH/$ALPINE_VERSION/main/x86_64/$APK_TOOLS.apk
APK_TOOLS_ARCHIVE=$TEMP_DIRECTORY/$APK_TOOLS.apk
APK_TOOLS_DIRECTORY=$TEMP_DIRECTORY/$APK_TOOLS

echo "creating temporary files directory: $TEMP_DIRECTORY"
mkdir -p $TEMP_DIRECTORY
echo "creating file system layer directory: $TARGET_FSL"
mkdir -p $TARGET_FSL
echo "downloading alpine package management tool: $APK_TOOLS"
wget -P $TEMP_DIRECTORY --show-progress $APK_TOOLS_URL
echo "creating alpine package management directory: $APK_TOOLS_DIRECTORY"
mkdir -p $APK_TOOLS_DIRECTORY
echo "extracting alpine package management tool..."
tar -xzf $APK_TOOLS_ARCHIVE -C $APK_TOOLS_DIRECTORY
echo "installing alpine-base from repository: $ALPINE_REPOSITORY"
$APK_TOOLS_DIRECTORY/sbin/apk.static \
    --repository $ALPINE_REPOSITORY \
    -U --allow-untrusted \
    -p $TARGET_FSL \
    --initdb add alpine-base
# https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch06.html#devDevicesAndSpecialFiles
echo "creating the devices and special files mount..."
mount -o bind,ro /dev $TARGET_FSL/dev
# https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch06.html#procKernelAndProcessInformationVir
echo "creating the kernel and process information mount..."
mount -t proc,ro none $TARGET_FSL/proc
# https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch06.html#sysKernelAndSystemInformation
echo "creating the kernel and system information mount..."
mount -o bind,ro /sys $TARGET_FSL/sys
echo "configuring OpenDNS name resolution"
echo -e 'nameserver 8.8.8.8\nnameserver 2620:0:ccc::2' > $TARGET_FSL/etc/resolv.conf
echo "configuring alpine repository: $ALPINE_REPOSITORY"
mkdir -p ${chroot_dir}/etc/apk
echo "$ALPINE_REPOSITORY" > ${chroot_dir}/etc/apk/repositories
echo "cleaning up temporary files directory: $TEMP_DIRECTORY"
rm -rf $TEMP_DIRECTORY