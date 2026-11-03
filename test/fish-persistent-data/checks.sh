#!/bin/bash

# Assertions shared by test.sh and the scenario scripts. Source this after
# dev-container-features-test-lib, which provides 'check'.

user=$(id -un)
group=$(id -gn)
mountpoint=/mnt/fish-persistent-data
datadir=$HOME/.local/share/fish

check_owned_by_user() {
    local label=$1 path=$2
    check "$label user" test "$(stat -c '%U' "$path")" = "$user"
    check "$label group" test "$(stat -c '%G' "$path")" = "$group"
    local perm
    perm=$(stat -c '%a' "$path")
    check "$label permissions" test "${perm:0:1}" = 7
}

check_feature_setup() {
    echo "User: $user, group: $group"
    stat "$mountpoint" "$datadir"

    check "mount exists" grep -q " $mountpoint " /proc/mounts
    check "data dir is a symlink" test -L "$datadir"
    check "data dir points to mountpoint" test "$(readlink "$datadir")" = "$mountpoint"

    check_owned_by_user "mountpoint" "$mountpoint"
    local dir=$datadir
    while [ "$dir" != "$HOME" ]; do
        check_owned_by_user "$dir" "$dir"
        dir=$(dirname "$dir")
    done

    local probe
    probe=write-probe-$RANDOM
    check "user can write through data dir" touch "$datadir/$probe"
    check "write lands on the volume" test -f "$mountpoint/$probe"
    rm -f "$mountpoint/$probe"
}
