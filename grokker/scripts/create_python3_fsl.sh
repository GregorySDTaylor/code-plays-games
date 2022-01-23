#!/bin/bash
GROKKER_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
LAYER_NAME=python3
SCRIPT_DIRECTORY=$GROKKER_DIRECTORY/scripts
TEMP_DIRECTORY=$GROKKER_DIRECTORY/temp/$LAYER_NAME
TARGET_FSL=$GROKKER_DIRECTORY/file_system_layers/$LAYER_NAME
OVERLAY_DIRECTORY=$GROKKER_DIRECTORY/overlay_mounts/$LAYER_NAME
ALPINE_FSL=$GROKKER_DIRECTORY/file_system_layers/alpine_3.15_x86_64

echo "creating temporary files directory: $TEMP_DIRECTORY"
mkdir -p $TEMP_DIRECTORY
echo "creating file system layer directory: $TARGET_FSL"
mkdir -p $TARGET_FSL
echo "creating container directory: $OVERLAY_DIRECTORY"
mkdir -p $OVERLAY_DIRECTORY
echo "creating overlay mount: $OVERLAY_DIRECTORY"
mount -t overlay overlay \
    -o lowerdir=$ALPINE_FSL,upperdir=$TARGET_FSL,workdir=$TEMP_DIRECTORY \
    $OVERLAY_DIRECTORY
$SCRIPT_DIRECTORY/init_alpine_3.15_x86_64_container.sh $LAYER_NAME
chroot $OVERLAY_DIRECTORY apk add --no-cache python3 py3-pip
$SCRIPT_DIRECTORY/cleanup_alpine_3.15_x86_64_container.sh $LAYER_NAME
echo "unmounting overlay: $OVERLAY_DIRECTORY"
umount -fn "$OVERLAY_DIRECTORY"
echo "deleting temporary files directory: $TEMP_DIRECTORY"
rm -rf $TEMP_DIRECTORY
echo "deleting container directory: $OVERLAY_DIRECTORY"
rm -rf $OVERLAY_DIRECTORY