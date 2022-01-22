#!/bin/bash

# Alpine Linux in a chroot: https://wiki.alpinelinux.org/wiki/Alpine_Linux_in_a_chroot
# fully-featured implementation: https://github.com/alpinelinux/alpine-chroot-install/

if (( $EUID != 0 )); then
    echo "failed: this script can only be run as root"
    exit
fi

PROJECT_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
OS_NAME=alpine
TARGET_FSL=$PROJECT_DIRECTORY/file_system_layers/$OS_NAME

# Unmounts all filesystem under the specified directory tree.
cat /proc/mounts | cut -d' ' -f2 | grep "^$TARGET_FSL" | sort -r | while read path; do
    echo "Unmounting $path" >&2
    umount -fn "$path" || exit 1
done
echo "deleteing file system layer directory: $TARGET_FSL"
rm -rf $TARGET_FSL