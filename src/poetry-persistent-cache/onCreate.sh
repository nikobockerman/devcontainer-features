#!/bin/sh
set -e

mount_point="/mnt/poetry-persistent-cache"

sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        command sudo "$@"
    fi
}

# Prepare mounted volume permissions
sudo chown "$(id -un)":"$(id -gn)" "$mount_point"
