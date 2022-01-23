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

FSL_DIRECTORY=$GROKKER_DIRECTORY/file_system_layers/$CONTAINER_NAME

echo "deleting file system layer directory: $FSL_DIRECTORY"
rm -rf $FSL_DIRECTORY

echo "container deleted successfully: $CONTAINER_NAME"