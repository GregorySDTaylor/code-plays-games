#!/bin/bash
set -e

if (( $EUID != 0 )); then
    echo "failed: this script can only be run as root"
    exit
fi

GROKKER_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
CONTAINER_NAME=rust
SCRIPT_DIRECTORY=$GROKKER_DIRECTORY/scripts
OVERLAY_DIRECTORY=$GROKKER_DIRECTORY/overlay_mounts/$CONTAINER_NAME
CODERUNNER_HOME=home/coderunner

echo "creating container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/create_container.sh -n $CONTAINER_NAME
echo "mounting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/mount_container.sh -n $CONTAINER_NAME -l alpine_3.15_x86_64

chroot $OVERLAY_DIRECTORY apk add --no-cache gcc
cp $SCRIPT_DIRECTORY/resources/install_rust.sh $OVERLAY_DIRECTORY/$CODERUNNER_HOME/install_rust.sh
chroot --userspec=1013 $OVERLAY_DIRECTORY /bin/ash -c \
    "cd /$CODERUNNER_HOME && export HOME=/$CODERUNNER_HOME && ./install_rust.sh"
rm $OVERLAY_DIRECTORY/$CODERUNNER_HOME/install_rust.sh

echo "unmounting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/unmount_container.sh -n $CONTAINER_NAME

exit 0