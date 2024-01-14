#!/bin/sh
set -e

echo "Activating feature 'fish-persistent-state'"
echo "User: ${_REMOTE_USER}"

if [ -z "$_REMOTE_USER" ]; then
    echo "**************************************************************"
    echo "*** Requires _REMOTE_USER to be set (by dev container CLI) ***"
    echo "**************************************************************"
    exit 1
fi

remote_user_home_source=
if [ -n "$_REMOTE_USER_HOME" ]; then
    remote_user_home_source=explicit
    remote_user_home=$_REMOTE_USER_HOME
else
    remote_user_home_source=introspection
    remote_user_home=$(getent passwd "$_REMOTE_USER" | cut -d: -f 6)
fi

echo "User home: $remote_user_home ($remote_user_home_source)"

if [ ! -d "$remote_user_home" ]; then
    echo "*****************************************************"
    echo "*** Requires _REMOTE_USER home directory to exist ***"
    echo "*****************************************************"
    exit 1
fi

set -x
mount_point="/mnt/fish-persistent-state"
fish_persistent_dir="$mount_point"/fish
user_local_dir=$remote_user_home/.local
user_share_dir=$user_local_dir/share
user_fish_state_dir=$user_share_dir/fish

if [ -d "$user_fish_state_dir" ]; then
    mv "$user_fish_state_dir" "$user_fish_state_dir-old"
else
    mkdir -p "$user_share_dir"
    chown "$_REMOTE_USER":"$_REMOTE_USER" -R "$user_local_dir"
fi
ln -s "$fish_persistent_dir" "$user_fish_state_dir"
chown -h "$_REMOTE_USER":"$_REMOTE_USER" "$user_fish_state_dir"
set +x
