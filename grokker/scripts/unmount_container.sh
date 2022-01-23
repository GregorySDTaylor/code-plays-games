#!/bin/bash
set -e

CONTAINER_NAME=""
GROKKER_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)

# Get the options
while getopts "n:" option; do
   case $option in
      n) 
         if [ "$OPTARG" == "base" ] 
         then
            echo "failed: file system layer name reserved: $OPTARG"
            exit 1
         else
            CONTAINER_NAME=$OPTARG
         fi;;
   esac
done

if [ -z "$CONTAINER_NAME" ]
then
   echo "failed: container name required with -n"
   exit 1
fi

TEMP_DIRECTORY=$GROKKER_DIRECTORY/temp/$CONTAINER_NAME
OVERLAY_DIRECTORY=$GROKKER_DIRECTORY/overlay_mounts/$CONTAINER_NAME

# Unmounts all under the specified directory tree.
cat /proc/mounts | cut -d' ' -f2 | grep "^$OVERLAY_DIRECTORY" | sort -r | while read path; do
    echo "unmounting $path" >&2
    umount -fn "$path" || exit 1
done

echo "deleting temporary files directory: $TEMP_DIRECTORY"
rm -rf $TEMP_DIRECTORY

echo "deleting overlay directory: $OVERLAY_DIRECTORY"
rm -rf $OVERLAY_DIRECTORY

echo "container unmounted successfully: $CONTAINER_NAME"