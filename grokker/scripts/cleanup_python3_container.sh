#!/bin/bash

if (( $EUID != 0 )); then
    echo "failed: this script can only be run as root"
    exit
fi

if [ "$1" = "" ]
then
    echo "failed: this script requires a container name argument"
    exit
fi

CONTAINER_NAME=$1
GROKKER_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
SCRIPT_DIRECTORY=$GROKKER_DIRECTORY/scripts
TEMP_DIRECTORY=$GROKKER_DIRECTORY/temp/$CONTAINER_NAME
TARGET_FSL=$GROKKER_DIRECTORY/file_system_layers/$CONTAINER_NAME
OVERLAY_DIRECTORY=$GROKKER_DIRECTORY/overlay_mounts/$CONTAINER_NAME

$SCRIPT_DIRECTORY/cleanup_alpine_3.15_x86_64_container.sh $CONTAINER_NAME
echo "unmounting overlay: $OVERLAY_DIRECTORY"
umount -fn "$OVERLAY_DIRECTORY"
echo "deleting temporary files directory: $TEMP_DIRECTORY"
rm -rf $TEMP_DIRECTORY
echo "deleting container directory: $OVERLAY_DIRECTORY"
rm -rf $OVERLAY_DIRECTORY
echo "deleting file system layer directory: $TARGET_FSL"
rm -rf $TARGET_FSL