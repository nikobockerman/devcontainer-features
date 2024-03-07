#!/bin/sh
set -e

# Debug settings
echo "Enabling debug output to investigate why fish-persistent-data fails to install properly on VSCode Recovery Containers"
set -x

mount_point="/mnt/fish-persistent-data"
user_local_dir=$HOME/.local
user_share_dir=$user_local_dir/share
user_fish_data_dir=$user_share_dir/fish

env|sort || true
mount || true
umask || true
ls -la /mnt/ || true
ls -la "$mount_point" || true
ls -la "$HOME" || true
ls -la "$user_local_dir" || true
ls -la "$user_share_dir" || true
ls -la "$user_fish_data_dir" || true

sudo() {
    if [ "$USER" = root ]; then
        "$@"
    else
        command sudo "$@"
    fi
}

# Prepare mounted volume permissions
sudo chown "$USER":"$USER" "$mount_point"

# Migrate fish data from location used in versions 1.0.* to new location
prev_fish_persistent_dir="$mount_point"/fish
if [ -d "$prev_fish_persistent_dir" ]; then
    echo "Migrating data from: $prev_fish_persistent_dir to $mount_point"
    ls -la "$prev_fish_persistent_dir" || true
    mv "$prev_fish_persistent_dir"/* "$mount_point"
    ls -la "$mount_point" || true
    rmdir "$prev_fish_persistent_dir"
fi

# Rename theoretical old fish data directory
if [ -d "$user_fish_data_dir" ]; then
    mv "$user_fish_data_dir" "$user_fish_data_dir-old"
fi

# Create new fish data directory as symlink to the mounted volume
mkdir -p "$user_share_dir"
chown "$USER":"$USER" -R "$user_local_dir"
ln -s "$mount_point" "$user_fish_data_dir"
chown -h "$USER":"$USER" "$user_fish_data_dir"
