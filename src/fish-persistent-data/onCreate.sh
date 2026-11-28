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

# Fail early with a clear message if the user cannot create the data dir symlink
user=$(id -un)
fail() {
    {
        echo "fish-persistent-data: $1"
        echo "The feature needs to create $user_fish_data_dir as $user."
        shift
        printf '%s\n' "$@"
    } >&2
    exit 1
}
dir_to_write=$user_share_dir
while [ ! -e "$dir_to_write" ] && [ ! -L "$dir_to_write" ]; do
    dir_to_write=$(dirname "$dir_to_write")
done
if [ ! -d "$dir_to_write" ]; then
    if [ -L "$dir_to_write" ]; then
        problem="$dir_to_write is a symlink to $(readlink "$dir_to_write"), which is not a directory."
    else
        problem="$dir_to_write is not a directory."
    fi
    fail "$problem" \
        "Something in the image created it. Replace it with a directory that $user can write to."
elif [ ! -w "$dir_to_write" ]; then
    owner=$(stat -L -c '%U' "$dir_to_write")
    if [ "$owner" = root ]; then
        fail "$dir_to_write is not writable by $user (owner: root)." \
            "Something in the image, such as a feature or Dockerfile step that runs as root, created it." \
            "Create it as $user or chown it to $user in the image."
    else
        fail "$dir_to_write is not writable by $user (owner: $owner, mode: $(stat -L -c '%A' "$dir_to_write"))." \
            "Make it writable by $user in the image."
    fi
fi

# Prepare mounted volume permissions
sudo chown "$(id -un)":"$(id -gn)" "$mount_point"

# Migrate from versions 1.0.*: move fish data from the old location to the new
# one and remove the old data dir symlink
prev_fish_persistent_dir="$mount_point"/fish
# Versions 2.0.0 to 2.0.3 left a symlink to the mount point at that path
# when their onCreate ran three times against the same data dir path, for
# example when it was rerun by hand or the home directory is persisted.
# That is not 1.0.* data: following it would move the volume's contents
# onto themselves.
if [ -L "$prev_fish_persistent_dir" ] && [ "$(readlink "$prev_fish_persistent_dir")" = "$mount_point" ]; then
    echo "Removing symlink $prev_fish_persistent_dir -> $mount_point left by versions 2.0.0 to 2.0.3"
    rm "$prev_fish_persistent_dir"
fi
if [ -d "$prev_fish_persistent_dir" ] && [ ! -L "$prev_fish_persistent_dir" ]; then
    echo "Migrating data from: $prev_fish_persistent_dir to $mount_point"
    # The patterns also match dotfiles. A pattern that matches nothing stays
    # as literal text, which the existence test skips.
    for entry in "$prev_fish_persistent_dir"/* "$prev_fish_persistent_dir"/.[!.]* "$prev_fish_persistent_dir"/..?*; do
        if [ -e "$entry" ] || [ -L "$entry" ]; then
            mv "$entry" "$mount_point"
        fi
    done
    rmdir "$prev_fish_persistent_dir"
fi
if [ -L "$user_fish_data_dir" ] && [ "$(readlink "$user_fish_data_dir")" = "$prev_fish_persistent_dir" ]; then
    echo "Removing symlink $user_fish_data_dir -> $prev_fish_persistent_dir left by version 1.0.*"
    rm "$user_fish_data_dir"
fi

if [ -L "$user_fish_data_dir" ] && [ "$(readlink "$user_fish_data_dir")" = "$mount_point" ]; then
    echo "$user_fish_data_dir already points to $mount_point"
else
    # Keep whatever is at the fish data directory path aside under the first
    # free name
    if [ -e "$user_fish_data_dir" ] || [ -L "$user_fish_data_dir" ]; then
        aside_path=$user_fish_data_dir-old
        n=0
        while [ -e "$aside_path" ] || [ -L "$aside_path" ]; do
            n=$((n + 1))
            aside_path=$user_fish_data_dir-old.$n
        done
        if [ -L "$user_fish_data_dir" ]; then
            echo "Moving existing symlink $user_fish_data_dir -> $(readlink "$user_fish_data_dir") to $aside_path"
        else
            echo "Moving existing $user_fish_data_dir to $aside_path"
        fi
        mv "$user_fish_data_dir" "$aside_path"
    fi

    # Create new fish data directory as symlink to the mounted volume
    mkdir -p "$user_share_dir"
    ln -s "$mount_point" "$user_fish_data_dir"
fi
