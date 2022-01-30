#!/bin/bash
set -e

CONTAINER_NAME=""
LOWER_DIRECTORIES=""
GROKKER_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
BASE_LOWER_DIRECTORY="$GROKKER_DIRECTORY/file_system_layers/base"

# Get the options
while getopts "n:l:" option; do
   case $option in
      n) # Validate name not base
         if [ "$OPTARG" == "base" ] 
         then
            echo "failed: file system layer name reserved: $OPTARG"
            exit 1
         else
            CONTAINER_NAME=$OPTARG
         fi;;
      l) # Check if layer is missing
         LOWER_DIRECTORY="$GROKKER_DIRECTORY/file_system_layers/${OPTARG}"
         if [ ! -d $LOWER_DIRECTORY ] 
         then
            echo "failed: lower file system layer missing: $LOWER_DIRECTORY"
            exit 1
         fi
         LOWER_DIRECTORIES+="${LOWER_DIRECTORY}:";;
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

echo "creating fsl base if not already exist: $FSL_BASE_DIRECTORY"
mkdir -p $BASE_LOWER_DIRECTORY

echo "creating temporary files directory: $TEMP_DIRECTORY"
mkdir -p $TEMP_DIRECTORY

echo "creating overlay directory: $OVERLAY_DIRECTORY"
mkdir -p $OVERLAY_DIRECTORY

echo "creating overlay mount: $OVERLAY_DIRECTORY
with lower layers: $LOWER_DIRECTORIES"
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

echo "creating memory cgroup: $OVERLAY_DIRECTORY/cgroups/memory/$CONTAINER_NAME"
mkdir -p $OVERLAY_DIRECTORY/cgroups/memory
mount -t cgroup -o memory none $OVERLAY_DIRECTORY/cgroups/memory
mkdir -p $OVERLAY_DIRECTORY/cgroups/memory/$CONTAINER_NAME
echo "104857600" > $OVERLAY_DIRECTORY/cgroups/memory/$CONTAINER_NAME/memory.limit_in_bytes
echo "104857600" > $OVERLAY_DIRECTORY/cgroups/memory/$CONTAINER_NAME/memory.memsw.limit_in_bytes
echo "setting pid $PPID in $CONTAINER_NAME memory cgroup"
echo $PPID > $OVERLAY_DIRECTORY/cgroups/memory/$CONTAINER_NAME/tasks

echo "creating pids cgroup: $OVERLAY_DIRECTORY/cgroups/pids/$CONTAINER_NAME"
mkdir -p $OVERLAY_DIRECTORY/cgroups/pids
mount -t cgroup -o pids none $OVERLAY_DIRECTORY/cgroups/pids
mkdir -p $OVERLAY_DIRECTORY/cgroups/pids/$CONTAINER_NAME
echo "64" > $OVERLAY_DIRECTORY/cgroups/pids/$CONTAINER_NAME/pids.max
echo "setting pid $PPID in $CONTAINER_NAME pids cgroup"
echo $PPID > $OVERLAY_DIRECTORY/cgroups/pids/$CONTAINER_NAME/tasks

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/resource_management_guide/sec-cpu
echo "creating cpu cgroup: $OVERLAY_DIRECTORY/cgroups/cpu/$CONTAINER_NAME"
mkdir -p $OVERLAY_DIRECTORY/cgroups/cpu
mount -t cgroup -o cpu none $OVERLAY_DIRECTORY/cgroups/cpu
mkdir -p $OVERLAY_DIRECTORY/cgroups/cpu/$CONTAINER_NAME
echo "100000" > $OVERLAY_DIRECTORY/cgroups/cpu/$CONTAINER_NAME/cpu.cfs_period_us
echo "50000" > $OVERLAY_DIRECTORY/cgroups/cpu/$CONTAINER_NAME/cpu.cfs_quota_us
echo "setting pid $PPID in $CONTAINER_NAME cpu cgroup"
echo $PPID > $OVERLAY_DIRECTORY/cgroups/cpu/$CONTAINER_NAME/tasks

echo "container mounted successfully: $CONTAINER_NAME"

exit 0