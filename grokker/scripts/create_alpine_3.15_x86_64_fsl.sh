#!/bin/bash
set -e

# Alpine Linux in a chroot: https://wiki.alpinelinux.org/wiki/Alpine_Linux_in_a_chroot
# fully-featured implementation: https://github.com/alpinelinux/alpine-chroot-install/

if (( $EUID != 0 )); then
    echo "failed: this script can only be run as root"
    exit
fi

GROKKER_DIRECTORY=$(cd "$(dirname "$0")"/.. && pwd)
CONTAINER_NAME=alpine_3.15_x86_64
SCRIPT_DIRECTORY=$GROKKER_DIRECTORY/scripts
TARGET_OVERLAY=$GROKKER_DIRECTORY/overlay_mounts/$CONTAINER_NAME
MIRROR_HOST_PATH=http://dl-cdn.alpinelinux.org/alpine
ALPINE_VERSION=v3.15
ALPINE_MAIN_REPOSITORY=$MIRROR_HOST_PATH/$ALPINE_VERSION/main
ALPINE_COMMUNITY_REPOSITORY=$MIRROR_HOST_PATH/$ALPINE_VERSION/community
APK_TOOLS=apk-tools-static-2.12.7-r3
APK_TEMP_DIRECTORY=$GROKKER_DIRECTORY/temp/${CONTAINER_NAME}_apk
APK_TOOLS_URL=$MIRROR_HOST_PATH/$ALPINE_VERSION/main/x86_64/$APK_TOOLS.apk
APK_TOOLS_ARCHIVE=$APK_TEMP_DIRECTORY/$APK_TOOLS.apk
APK_TOOLS_DIRECTORY=$APK_TEMP_DIRECTORY/$APK_TOOLS

echo "creating container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/create_container.sh -n $CONTAINER_NAME
echo "mounting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/mount_container.sh -n $CONTAINER_NAME
echo "creating temporary apk-tools directory: $APK_TEMP_DIRECTORY"
mkdir -p $APK_TEMP_DIRECTORY
echo "downloading alpine package management tool: $APK_TOOLS"
wget -P $APK_TEMP_DIRECTORY --show-progress $APK_TOOLS_URL
echo "creating alpine package management directory: $APK_TOOLS_DIRECTORY"
mkdir -p $APK_TOOLS_DIRECTORY
echo "extracting alpine package management tool..."
tar -xzf $APK_TOOLS_ARCHIVE -C $APK_TOOLS_DIRECTORY
echo "installing alpine-base from repository: $ALPINE_MAIN_REPOSITORY"
$APK_TOOLS_DIRECTORY/sbin/apk.static \
    --repository $ALPINE_MAIN_REPOSITORY \
    -U --allow-untrusted \
    -p $TARGET_OVERLAY \
    --initdb add alpine-base
echo "configuring OpenDNS name resolution"
echo -e 'nameserver 8.8.8.8\nnameserver 2620:0:ccc::2' > $TARGET_OVERLAY/etc/resolv.conf
echo "configuring alpine repositories: $ALPINE_MAIN_REPOSITORY,  $ALPINE_COMMUNITY_REPOSITORY"
mkdir -p $TARGET_OVERLAY/etc/apk
echo $ALPINE_MAIN_REPOSITORY > $TARGET_OVERLAY/etc/apk/repositories
echo $ALPINE_COMMUNITY_REPOSITORY >> $TARGET_OVERLAY/etc/apk/repositories
echo "creating system user coderunner with uid 1013"
chroot $TARGET_OVERLAY adduser --system --uid=1013 coderunner
echo "cleaning up temporary files directory: $APK_TEMP_DIRECTORY"
rm -rf $APK_TEMP_DIRECTORY
echo "unmounting container: $CONTAINER_NAME"
$SCRIPT_DIRECTORY/unmount_container.sh -n $CONTAINER_NAME

exit 0