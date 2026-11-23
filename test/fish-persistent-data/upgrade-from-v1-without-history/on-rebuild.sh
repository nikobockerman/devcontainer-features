#!/bin/bash

# shellcheck source=SCRIPTDIR/../../../scripts/rebuild-lib.sh
source "$(dirname "$0")/rebuild-lib.sh"

mountpoint=/mnt/fish-persistent-data
entry() {
    echo "echo after-upgrade-$1-$REBUILD_TOKEN"
}

check "1.x subdirectory is removed" test ! -e "$mountpoint/fish"
check "fish data dir links to the volume root" \
    test "$(readlink "$HOME/.local/share/fish")" = "$mountpoint"
for ((step = 1; step < REBUILD_STEP; step++)); do
    check "history from after upgrade $step is present" \
        grep -qF -- "$(entry "$step")" "$mountpoint/fish_history"
done
check "fish writes history to the volume" \
    fish -c "history append '$(entry "$REBUILD_STEP")'"
check "history has the entry from after upgrade $REBUILD_STEP" \
    grep -qF -- "$(entry "$REBUILD_STEP")" "$mountpoint/fish_history"

report_results
