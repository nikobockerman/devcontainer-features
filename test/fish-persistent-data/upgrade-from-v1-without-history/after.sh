#!/bin/bash

# shellcheck source=SCRIPTDIR/../../../scripts/rebuild-lib.sh
source "$(dirname "$0")/rebuild-lib.sh"

mountpoint=/mnt/fish-persistent-data

check "1.x subdirectory is removed" test ! -e "$mountpoint/fish"
check "fish data dir links to the volume root" \
    test "$(readlink "$HOME/.local/share/fish")" = "$mountpoint"
check "fish writes history to the volume" \
    fish -c "history append 'echo after-upgrade-$REBUILD_TOKEN'"
check "history has the entry from after the upgrade" \
    grep -qF -- "echo after-upgrade-$REBUILD_TOKEN" "$mountpoint/fish_history"

report_results
