#!/bin/bash

# shellcheck source=SCRIPTDIR/../../../scripts/rebuild-lib.sh
source "$(dirname "$0")/rebuild-lib.sh"

history=$HOME/.local/share/fish/fish_history
entry() {
    echo "echo after-rebuild-$1-$REBUILD_TOKEN"
}

check "history from before the first rebuild is present" \
    grep -qF -- "echo before-rebuild-$REBUILD_TOKEN" "$history"
for ((step = 1; step < REBUILD_STEP; step++)); do
    check "history from after rebuild $step is present" \
        grep -qF -- "$(entry "$step")" "$history"
done
check "fish appends to the restored history" \
    fish -c "history append '$(entry "$REBUILD_STEP")'"
check "history keeps the entry from before the first rebuild" \
    grep -qF -- "echo before-rebuild-$REBUILD_TOKEN" "$history"
check "history has the entry from after rebuild $REBUILD_STEP" \
    grep -qF -- "$(entry "$REBUILD_STEP")" "$history"

report_results
