#!/bin/bash

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks-lib.sh
source "$(dirname "$0")/checks-lib.sh"

check_feature_setup

on_create=/usr/local/share/github-nikobockerman/devcontainer-features/fish-persistent-data/onCreate.sh

# Runs onCreate.sh with a fixture home, setting $status and $output (stderr).
run_on_create() {
    output=$(HOME=$1 sh "$on_create" 2>&1 >/dev/null) && status=0 || status=$?
    echo "$output"
}

# Checks that onCreate.sh fails for a fixture home with an error that names
# the problem directory and, after it, the expected lines.
check_fails_clearly() {
    local home=$1 dir=$2 line
    shift 2
    run_on_create "$home"
    check "$home: onCreate fails" test "$status" -ne 0
    check "$home: error names the directory" grep -qF "fish-persistent-data: $dir " <<<"$output"
    for line; do
        check "$home: error says '$line'" grep -qF "$line" <<<"$output"
    done
}

root_cause="feature or Dockerfile step that runs as root"

# Created as root by the Dockerfile
home=/opt/broken-homes/share
check "fixture: Dockerfile created $home/.local/share as root" test "$(stat -c '%U' "$home/.local/share")" = root
check_fails_clearly "$home" "$home/.local/share" \
    "not writable by $user (owner: root)" "$root_cause" "chown it to $user"
check "$home: existing data dir is not moved" test -d "$home/.local/share/fish"
check "$home: no fish-old is created" test ! -e "$home/.local/share/fish-old"

home=/opt/broken-homes/local
check "fixture: Dockerfile created $home/.local as root" test "$(stat -c '%U' "$home/.local")" = root
check_fails_clearly "$home" "$home/.local" \
    "not writable by $user (owner: root)" "$root_cause"
check "$home: share dir is not created" test ! -e "$home/.local/share"

# Created by the user, so that they are owned by the user as they are in a
# real home directory
fixtures=$(mktemp -d)

home=$fixtures/read-only-share
mkdir -p "$home/.local/share"
chmod 555 "$home/.local/share"
check_fails_clearly "$home" "$home/.local/share" \
    "not writable by $user (owner: $user, mode: dr-xr-xr-x)" "Make it writable by $user"
check "$home: error does not blame root" test "$(grep -cF "$root_cause" <<<"$output")" = 0

home=$fixtures/dangling-symlink
mkdir -p "$home/.local"
ln -s /nonexistent "$home/.local/share"
check_fails_clearly "$home" "$home/.local/share" \
    "symlink to /nonexistent, which is not a directory"

home=$fixtures/file-as-share
mkdir -p "$home/.local"
touch "$home/.local/share"
check_fails_clearly "$home" "$home/.local/share" "is not a directory"

home=$fixtures/missing-share
mkdir -p "$home/.local"
run_on_create "$home"
check "$home: onCreate succeeds when share dir is missing" test "$status" -eq 0
check "$home: data dir points to mountpoint" test "$(readlink "$home/.local/share/fish")" = "$mountpoint"

# The real data dir from container creation is untouched by the other runs.
check_feature_setup

reportResults
