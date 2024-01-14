#!/bin/sh
set -e

echo "Activating feature 'fish-persistent-data'"
echo "User: ${_REMOTE_USER}"

if [ -z "$_REMOTE_USER" ]; then
    echo "**************************************************************"
    echo "*** Requires _REMOTE_USER to be set (by dev container CLI) ***"
    echo "**************************************************************"
    exit 1
fi

home_source=
if [ -n "$_REMOTE_USER_HOME" ]; then
    home_source=explicit
    home=$_REMOTE_USER_HOME
else
    home_source=introspection
    home=$(getent passwd "$_REMOTE_USER" | cut -d: -f 6)
fi

echo "User home: $home ($home_source)"

if [ ! -d "$home" ]; then
    echo "*****************************************************"
    echo "*** Requires _REMOTE_USER home directory to exist ***"
    echo "*****************************************************"
    exit 1
fi

# Actual initialization starts here

set -x
# Prepare on-create script
on_create_script=/usr/local/share/feature_fish-persistent-data_on-create.sh
cp on-create.sh "$on_create_script"
chmod +x "$on_create_script"

# Make fish local data dir
mount_point="/mnt/fish-persistent-data"
fish_persistent_dir="$mount_point"/fish
user_local_dir=$home/.local
user_share_dir=$user_local_dir/share
user_fish_data_dir=$user_share_dir/fish

if [ -d "$user_fish_data_dir" ]; then
    mv "$user_fish_data_dir" "$user_fish_data_dir-old"
else
    mkdir -p "$user_share_dir"
    chown "$_REMOTE_USER":"$_REMOTE_USER" -R "$user_local_dir"
fi
ln -s "$fish_persistent_dir" "$user_fish_data_dir"
chown -h "$_REMOTE_USER":"$_REMOTE_USER" "$user_fish_data_dir"
set +x
