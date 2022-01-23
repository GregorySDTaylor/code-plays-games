#!/bin/bash
set -e

CONTAINER_NAME=""
LOWER_DIRECTORIES=""
GROKKER_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
BASE_LOWER_DIRECTORY="$GROKKER_DIRECTORY/file_system_layers/base"

# Get the options
while getopts "n:l:" option; do
   case $option in
      n) 
         if [ "$OPTARG" == "base" ] 
         then
            echo "failed: file system layer name reserved: $OPTARG"
            exit 1
         else
            CONTAINER_NAME=$OPTARG
         fi;;
      l) # Check if layer is missing
         LOWER_DIRECTORY="$GROKKER_DIRECTORY/file_system_layers/${OPTARG}:"
         if [ ! -d $LOWER_DIRECTORY ] 
         then
            echo "failed: lower file system layer missing: $LOWER_DIRECTORY"
            exit 1
         fi
         LOWER_DIRECTORIES+=$LOWER_DIRECTORY;;
   esac
done

if [ -z "$CONTAINER_NAME" ]
then
   echo "failed: container name required with -n"
   exit 1
fi

LOWER_DIRECTORIES+=$BASE_LOWER_DIRECTORY
TEMP_DIRECTORY=$GROKKER_DIRECTORY/temp/$CONTAINER_NAME
FSL_DIRECTORY=$GROKKER_DIRECTORY/file_system_layers/$CONTAINER_NAME
OVERLAY_DIRECTORY=$GROKKER_DIRECTORY/overlay_mounts/$CONTAINER_NAME

# ensure TEMP_DIRECTORY doesn't already exist
if [ -d $TEMP_DIRECTORY ] 
then
   echo "failed: temporary files directory already exists: $TEMP_DIRECTORY"
   exit 1
fi

# ensure FSL_DIRECTORY exists
if [ ! -d $FSL_DIRECTORY ] 
then
   echo "failed: file system layer missing: $FSL_DIRECTORY"
   exit 1
fi

# ensure OVERLAY_DIRECTORY doesn't already exist
if [ -d $OVERLAY_DIRECTORY ] 
then
   echo "failed: overlay directory already exists: $OVERLAY_DIRECTORY"
   exit 1
fi

echo "creating temporary files directory: $TEMP_DIRECTORY"
mkdir -p $TEMP_DIRECTORY

echo "creating overlay directory: $OVERLAY_DIRECTORY"
mkdir -p $OVERLAY_DIRECTORY

echo "creating overlay mount: $OVERLAY_DIRECTORY"
mount -t overlay overlay \
   -o lowerdir=$LOWER_DIRECTORIES,upperdir=$FSL_DIRECTORY,workdir=$TEMP_DIRECTORY \
   $OVERLAY_DIRECTORY

# https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch06.html#devDevicesAndSpecialFiles
echo "creating the devices and special files mount: $OVERLAY_DIRECTORY/dev"
mkdir -p $OVERLAY_DIRECTORY/dev
mount -o bind,ro /dev $OVERLAY_DIRECTORY/dev

# https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch06.html#procKernelAndProcessInformationVir
echo "creating the kernel and process information mount: $OVERLAY_DIRECTORY/proc"
mkdir -p $OVERLAY_DIRECTORY/proc
mount -t proc,ro none $OVERLAY_DIRECTORY/proc

# https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch06.html#sysKernelAndSystemInformation
echo "creating the kernel and system information mount: $OVERLAY_DIRECTORY/sys"
mkdir -p $OVERLAY_DIRECTORY/sys
mount -o bind,ro /sys $OVERLAY_DIRECTORY/sys

echo "container mounted successfully: $CONTAINER_NAME"