#!/bin/bash
set -e

if (( $EUID != 0 )); then
    echo "failed: this script can only be run as root"
    exit
fi

GROKKER_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
BUILD_CONTAINER_NAME=rust_build_test
BUILD_OVERLAY_DIRECTORY=$GROKKER_DIRECTORY/overlay_mounts/$BUILD_CONTAINER_NAME
CONTAINER_NAME=rust_test
PROJECT_NAME=hello_rust
SCRIPT_DIRECTORY=$GROKKER_DIRECTORY/scripts
OVERLAY_DIRECTORY=$GROKKER_DIRECTORY/overlay_mounts/$CONTAINER_NAME
CARGO_DIR=/root/.cargo/bin

echo "creating container: $BUILD_CONTAINER_NAME"
$SCRIPT_DIRECTORY/create_container.sh -n $BUILD_CONTAINER_NAME
echo "mounting container: $BUILD_CONTAINER_NAME"
$SCRIPT_DIRECTORY/mount_container.sh -n $BUILD_CONTAINER_NAME -l rust -l alpine_3.15_x86_64

echo "creating container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/create_container.sh -n $CONTAINER_NAME
echo "mounting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/mount_container.sh -n $CONTAINER_NAME -l alpine_3.15_x86_64

unshare --ipc --mount --net --pid --user --cgroup --fork \
    --map-root-user --kill-child --mount-proc=$BUILD_OVERLAY_DIRECTORY/proc \
    chroot $BUILD_OVERLAY_DIRECTORY \
    $CARGO_DIR/cargo new $PROJECT_NAME --vcs none

cat $SCRIPT_DIRECTORY/resources/hello.rs > $BUILD_OVERLAY_DIRECTORY/$PROJECT_NAME/src/main.rs

unshare --ipc --mount --net --pid --user --cgroup --fork \
    --map-root-user --kill-child --mount-proc=$BUILD_OVERLAY_DIRECTORY/proc \
    chroot $BUILD_OVERLAY_DIRECTORY /bin/ash -c \
    "cd /$PROJECT_NAME && $CARGO_DIR/cargo build --release"

cp $BUILD_OVERLAY_DIRECTORY/$PROJECT_NAME/target/release/$PROJECT_NAME $OVERLAY_DIRECTORY

unshare --ipc --mount --net --pid --user --cgroup --fork \
    --map-root-user --kill-child --mount-proc=$OVERLAY_DIRECTORY/proc \
    chroot $OVERLAY_DIRECTORY \
    /$PROJECT_NAME

echo "unmounting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/unmount_container.sh -n $CONTAINER_NAME
echo "deleting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/delete_container.sh -n $CONTAINER_NAME

echo "unmounting container: $BUILD_CONTAINER_NAME"
$SCRIPT_DIRECTORY/unmount_container.sh -n $BUILD_CONTAINER_NAME
echo "deleting container: $BUILD_CONTAINER_NAME"
$SCRIPT_DIRECTORY/delete_container.sh -n $BUILD_CONTAINER_NAME

exit 0