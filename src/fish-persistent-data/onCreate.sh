#!/bin/sh
set -e

mount_point="/mnt/fish-persistent-data"
user_share_dir=$HOME/.local/share
user_fish_data_dir=$user_share_dir/fish


sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        command sudo "$@"
    fi
}

# Prepare mounted volume permissions
sudo chown "$(id -un)":"$(id -gn)" "$mount_point"

# Migrate fish data from location used in versions 1.0.* to new location
prev_fish_persistent_dir="$mount_point"/fish
if [ -d "$prev_fish_persistent_dir" ]; then
    echo "Migrating data from: $prev_fish_persistent_dir to $mount_point"
    mv "$prev_fish_persistent_dir"/* "$mount_point"
    rmdir "$prev_fish_persistent_dir"
fi

# Rename theoretical old fish data directory
if [ -d "$user_fish_data_dir" ]; then
    mv "$user_fish_data_dir" "$user_fish_data_dir-old"
fi

# Create new fish data directory as symlink to the mounted volume
mkdir -p "$user_share_dir"
ln -s "$mount_point" "$user_fish_data_dir"
