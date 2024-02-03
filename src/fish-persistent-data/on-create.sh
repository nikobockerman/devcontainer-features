#!/bin/sh
set -e

echo "Activating feature 'fish-persistent-data'"

user=$(id -un)
echo "User: $user"

mount_point="/mnt/fish-persistent-data"

if ! grep -q "$mount_point" /proc/mounts >/dev/null; then
    echo "******************************************"
    echo "*** Requires mount point to be mounted ***"
    echo "******************************************"
    exit 1
fi

if [ ! -d "$mount_point" ]; then
    echo "*************************************"
    echo "*** Requires mount point to exist ***"
    echo "*************************************"
    exit 1
fi

fish_persistent_dir="$mount_point"/fish
if [ -d "$fish_persistent_dir" ]; then
    echo "Already exists: $fish_persistent_dir"
    exit 0
fi

if [ "$user" = root ]; then
    mkdir "$fish_persistent_dir"
    chown "$user":"$user" "$fish_persistent_dir"
else
    sudo mkdir "$fish_persistent_dir"
    sudo chown "$user":"$user" "$fish_persistent_dir"
fi
