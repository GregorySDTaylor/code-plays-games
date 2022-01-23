#!/bin/bash
set -e

CONTAINER_NAME=$(cat /proc/sys/kernel/random/uuid)

# Get the options
while getopts "n:" option; do
   case $option in
      n) 
         if [ $OPTARG == "base" ] 
         then
            echo "failed: file system layer name reserved: $OPTARG"
            exit 1
         else
            CONTAINER_NAME=$OPTARG
         fi;;
   esac
done

GROKKER_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
FSL_DIRECTORY=$GROKKER_DIRECTORY/file_system_layers/$CONTAINER_NAME

# Check if FSL_DIRECTORY already exists
if [ -d $FSL_DIRECTORY ] 
then
   echo "failed: file system layer already exists: $FSL_DIRECTORY"
   exit 1
fi

echo "creating file system layer directory: $FSL_DIRECTORY"
mkdir -p $FSL_DIRECTORY
echo "container created: $CONTAINER_NAME"