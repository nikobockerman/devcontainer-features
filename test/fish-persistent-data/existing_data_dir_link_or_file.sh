#!/bin/bash

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks-lib.sh
source "$(dirname "$0")/checks-lib.sh"

check_feature_setup

on_create=/usr/local/share/github-nikobockerman/devcontainer-features/fish-persistent-data/onCreate.sh

# Runs onCreate.sh with a fixture home and checks that it links the data dir
# to the mountpoint. Leaves the output of onCreate.sh in $output.
check_on_create_links_data_dir() {
    local home=$1 status
    output=$(HOME=$home sh "$on_create" 2>&1) && status=0 || status=$?
    echo "$output"
    check "$home: onCreate succeeds" test "$status" -eq 0
    check "$home: data dir points to mountpoint" test "$(readlink "$home/.local/share/fish")" = "$mountpoint"
}

fixtures=$(mktemp -d)
mkdir "$fixtures/target-dir"
echo current >"$fixtures/target-dir/fish_history"
echo current >"$fixtures/target-file"

home=$fixtures/symlink-to-mountpoint
mkdir -p "$home/.local/share"
ln -s "$mountpoint" "$home/.local/share/fish"
check_on_create_links_data_dir "$home"
check "$home: nothing is kept aside" test "$(ls -A "$home/.local/share")" = fish
check "$home: reports the existing link" grep -qF "$home/.local/share/fish already points to $mountpoint" <<<"$output"

# The link that versions 1.0.* created at image build time, left dangling
# after an earlier migration
home=$fixtures/v1-symlink
mkdir -p "$home/.local/share"
ln -s "$mountpoint/fish" "$home/.local/share/fish"
check_on_create_links_data_dir "$home"
check "$home: nothing is kept aside" test "$(ls -A "$home/.local/share")" = fish
check "$home: reports removing the v1 link" grep -qF "Removing symlink $home/.local/share/fish -> $mountpoint/fish left by version 1.0.*" <<<"$output"

# The same link with 1.0.* data still on the volume
home=$fixtures/v1-symlink-with-data
mkdir -p "$home/.local/share"
ln -s "$mountpoint/fish" "$home/.local/share/fish"
v1_file=v1-probe-$RANDOM
mkdir "$mountpoint/fish"
echo v1 >"$mountpoint/fish/$v1_file"
check_on_create_links_data_dir "$home"
check "$home: nothing is kept aside" test "$(ls -A "$home/.local/share")" = fish
check "$home: v1 data is migrated" grep -qxF v1 "$mountpoint/$v1_file"
check "$home: v1 data dir is removed" test ! -e "$mountpoint/fish"
check "$home: reports removing the v1 link" grep -qF "Removing symlink $home/.local/share/fish -> $mountpoint/fish left by version 1.0.*" <<<"$output"
rm -f "$mountpoint/$v1_file"
rm -rf "$mountpoint/fish"

home=$fixtures/symlink-to-dir
mkdir -p "$home/.local/share"
ln -s "$fixtures/target-dir" "$home/.local/share/fish"
check_on_create_links_data_dir "$home"
check "$home: symlink is kept aside as fish-old" test "$(readlink "$home/.local/share/fish-old")" = "$fixtures/target-dir"
check "$home: reports keeping the symlink aside" grep -qF "Moving existing symlink $home/.local/share/fish -> $fixtures/target-dir to $home/.local/share/fish-old" <<<"$output"
check "$home: symlink target is untouched" test "$(ls -A "$fixtures/target-dir")" = fish_history

home=$fixtures/dangling-symlink
mkdir -p "$home/.local/share"
ln -s /nonexistent "$home/.local/share/fish"
check_on_create_links_data_dir "$home"
check "$home: symlink is kept aside as fish-old" test "$(readlink "$home/.local/share/fish-old")" = /nonexistent
check "$home: reports keeping the symlink aside" grep -qF "Moving existing symlink $home/.local/share/fish -> /nonexistent to $home/.local/share/fish-old" <<<"$output"

home=$fixtures/symlink-to-file
mkdir -p "$home/.local/share"
ln -s "$fixtures/target-file" "$home/.local/share/fish"
check_on_create_links_data_dir "$home"
check "$home: symlink is kept aside as fish-old" test "$(readlink "$home/.local/share/fish-old")" = "$fixtures/target-file"
check "$home: symlink target is untouched" grep -qxF current "$fixtures/target-file"
check "$home: reports keeping the symlink aside" grep -qF "Moving existing symlink $home/.local/share/fish -> $fixtures/target-file to $home/.local/share/fish-old" <<<"$output"

home=$fixtures/regular-file
mkdir -p "$home/.local/share"
echo current >"$home/.local/share/fish"
check_on_create_links_data_dir "$home"
check "$home: file is kept aside as fish-old" grep -qxF current "$home/.local/share/fish-old"
check "$home: reports keeping the file aside" grep -qF "Moving existing $home/.local/share/fish to $home/.local/share/fish-old" <<<"$output"

# The real data dir from container creation is untouched by the other runs.
check_feature_setup

reportResults
