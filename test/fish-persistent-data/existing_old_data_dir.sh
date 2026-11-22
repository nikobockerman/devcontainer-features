#!/bin/bash

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks-lib.sh
source "$(dirname "$0")/checks-lib.sh"

check_feature_setup

share=$HOME/.local/share
check "earlier data stays in fish-old" grep -qF 'from-earlier' "$share/fish-old/fish_history"
check "data dir is not moved into fish-old" test ! -e "$share/fish-old/fish"
check "existing data dir is kept aside as fish-old.1" grep -qF 'from-image' "$share/fish-old.1/fish_history"

on_create=/usr/local/share/github-nikobockerman/devcontainer-features/fish-persistent-data/onCreate.sh

# Creates a fixture home with fish data in its data dir.
create_fixture_home() {
    mkdir -p "$1/.local/share/fish"
    echo current >"$1/.local/share/fish/fish_history"
}

# Runs onCreate.sh with a fixture home and checks that its data dir is kept
# aside under the expected name.
check_kept_aside_as() {
    local home=$1 expected=$2 output status
    output=$(HOME=$home sh "$on_create" 2>&1) && status=0 || status=$?
    echo "$output"
    check "$home: onCreate succeeds" test "$status" -eq 0
    check "$home: data dir points to mountpoint" test "$(readlink "$home/.local/share/fish")" = "$mountpoint"
    check "$home: data dir is kept aside as $expected" grep -qF 'current' "$home/.local/share/$expected/fish_history"
}

fixtures=$(mktemp -d)

home=$fixtures/several-taken
create_fixture_home "$home"
mkdir "$home/.local/share/fish-old" "$home/.local/share/fish-old.1"
check_kept_aside_as "$home" fish-old.2

home=$fixtures/read-only-old
create_fixture_home "$home"
mkdir "$home/.local/share/fish-old"
chmod 555 "$home/.local/share/fish-old"
check_kept_aside_as "$home" fish-old.1

home=$fixtures/file-as-old
create_fixture_home "$home"
touch "$home/.local/share/fish-old"
check_kept_aside_as "$home" fish-old.1
check "$home: file named fish-old is kept" test -f "$home/.local/share/fish-old"

home=$fixtures/dangling-symlink-as-old
create_fixture_home "$home"
ln -s /nonexistent "$home/.local/share/fish-old"
check_kept_aside_as "$home" fish-old.1
check "$home: symlink named fish-old is kept" test -L "$home/.local/share/fish-old"

home=$fixtures/dir-symlink-as-old
create_fixture_home "$home"
mkdir "$fixtures/symlink-target"
ln -s "$fixtures/symlink-target" "$home/.local/share/fish-old"
check_kept_aside_as "$home" fish-old.1
check "$home: symlink named fish-old is kept" test -L "$home/.local/share/fish-old"
check "$home: nothing is moved into the symlink target" test -z "$(ls -A "$fixtures/symlink-target")"

# The real data dir from container creation is untouched by the other runs.
check_feature_setup

reportResults
