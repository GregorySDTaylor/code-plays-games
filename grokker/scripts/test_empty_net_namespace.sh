#!/bin/bash
set -e

if (( $EUID != 0 )); then
    echo "failed: this script can only be run as root"
    exit
fi

GROKKER_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
CONTAINER_NAME=test_empty_net_namespace
SCRIPT_DIRECTORY=$GROKKER_DIRECTORY/scripts
OVERLAY_DIRECTORY=$GROKKER_DIRECTORY/overlay_mounts/$CONTAINER_NAME
CODERUNNER_HOME=home/coderunner

echo "creating container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/create_container.sh -n $CONTAINER_NAME
echo "mounting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/mount_container.sh -n $CONTAINER_NAME -l alpine_3.15_x86_64

echo "running ping as user"
unshare --ipc --mount --net --pid --cgroup --fork \
    --kill-child --mount-proc=$OVERLAY_DIRECTORY/proc \
    chroot --userspec=1013 $OVERLAY_DIRECTORY /bin/ash -c \
    "ping -c 4 www.google.com || ping -c 4 172.217.0.36 || ping -c 4 127.0.0.1"

echo "unmounting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/unmount_container.sh -n $CONTAINER_NAME

echo "deleting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/delete_container.sh -n $CONTAINER_NAME

exit 0