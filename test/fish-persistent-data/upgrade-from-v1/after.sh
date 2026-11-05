#!/bin/bash

# shellcheck source=SCRIPTDIR/../../../scripts/rebuild-lib.sh
source "$(dirname "$0")/rebuild-lib.sh"

mountpoint=/mnt/fish-persistent-data
history=$HOME/.local/share/fish/fish_history

check "1.x subdirectory is removed" test ! -e "$mountpoint/fish"
check "fish data dir links to the volume root" \
    test "$(readlink "$HOME/.local/share/fish")" = "$mountpoint"
check "history from 1.x is present" \
    grep -qF -- "echo from-v1-$REBUILD_TOKEN" "$history"
check "fish appends to the migrated history" \
    fish -c "history append 'echo after-upgrade-$REBUILD_TOKEN'"
check "history has the entry from after the upgrade" \
    grep -qF -- "echo after-upgrade-$REBUILD_TOKEN" "$mountpoint/fish_history"

report_results
