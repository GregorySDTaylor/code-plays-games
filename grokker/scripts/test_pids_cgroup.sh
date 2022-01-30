#!/bin/bash
set -e

if (( $EUID != 0 )); then
    echo "failed: this script can only be run as root"
    exit
fi

GROKKER_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
CONTAINER_NAME=test_pids_cgroup
SCRIPT_DIRECTORY=$GROKKER_DIRECTORY/scripts
OVERLAY_DIRECTORY=$GROKKER_DIRECTORY/overlay_mounts/$CONTAINER_NAME
CODERUNNER_HOME=home/coderunner

echo "creating container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/create_container.sh -n $CONTAINER_NAME
echo "mounting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/mount_container.sh -n $CONTAINER_NAME -l python3 -l alpine_3.15_x86_64

echo "copying processbomb.py script to run container"
cp $SCRIPT_DIRECTORY/resources/processbomb.py $OVERLAY_DIRECTORY/$CODERUNNER_HOME

echo "changing processbomb.py script ownership to coderunner"
chroot $OVERLAY_DIRECTORY chown coderunner $CODERUNNER_HOME/processbomb.py

echo "running processbomb.py as user"
unshare --ipc --mount --net --pid --cgroup --fork \
    --kill-child --mount-proc=$OVERLAY_DIRECTORY/proc \
    chroot --userspec=1013 $OVERLAY_DIRECTORY \
    python3 /$CODERUNNER_HOME/processbomb.py

echo "unmounting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/unmount_container.sh -n $CONTAINER_NAME

echo "deleting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/delete_container.sh -n $CONTAINER_NAME

exit 0