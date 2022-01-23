#!/bin/bash

CONTAINER_NAME=$(cat /proc/sys/kernel/random/uuid)
PROJECT_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
SCRIPT_DIRECTORY=$PROJECT_DIRECTORY/scripts
TEMP_DIRECTORY=$PROJECT_DIRECTORY/temp/$CONTAINER_NAME
TARGET_FSL=$PROJECT_DIRECTORY/file_system_layers/$CONTAINER_NAME
CONTAINER_DIRECTORY=$PROJECT_DIRECTORY/containers/$CONTAINER_NAME
PYTHON3_FSL=$PROJECT_DIRECTORY/file_system_layers/python3
ALPINE_FSL=$PROJECT_DIRECTORY/file_system_layers/alpine_3.15_x86_64

echo "creating temporary files directory: $TEMP_DIRECTORY"
mkdir -p $TEMP_DIRECTORY
echo "creating file system layer directory: $TARGET_FSL"
mkdir -p $TARGET_FSL
echo "creating container directory: $CONTAINER_DIRECTORY"
mkdir -p $CONTAINER_DIRECTORY
echo "creating overlay mount: $CONTAINER_DIRECTORY"
mount -t overlay overlay \
    -o lowerdir=$PYTHON3_FSL:$ALPINE_FSL,upperdir=$TARGET_FSL,workdir=$TEMP_DIRECTORY \
    $CONTAINER_DIRECTORY
$SCRIPT_DIRECTORY/init_alpine_3.15_x86_64_container.sh $CONTAINER_NAME
echo "container created: $CONTAINER_NAME"