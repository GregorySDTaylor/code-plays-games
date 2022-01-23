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

GROKKER_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
CONTAINER_DIRECTORY=$GROKKER_DIRECTORY/containers/$1

# Unmounts all filesystem under the specified directory tree.
cat /proc/mounts | cut -d' ' -f2 | grep "^$CONTAINER_DIRECTORY/" | sort -r | while read path; do
    echo "unmounting $path" >&2
    umount -fn "$path" || exit 1
done