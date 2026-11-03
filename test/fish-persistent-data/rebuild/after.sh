#!/bin/bash

# shellcheck source=SCRIPTDIR/../../../scripts/rebuild-lib.sh
source "$(dirname "$0")/rebuild-lib.sh"

history=$HOME/.local/share/fish/fish_history

check "history from before the rebuild is present" \
    grep -qF -- "echo before-rebuild-$REBUILD_TOKEN" "$history"
check "fish appends to the restored history" \
    fish -c "history append 'echo after-rebuild-$REBUILD_TOKEN'"
check "history keeps the entry from before the rebuild" \
    grep -qF -- "echo before-rebuild-$REBUILD_TOKEN" "$history"
check "history has the entry from after the rebuild" \
    grep -qF -- "echo after-rebuild-$REBUILD_TOKEN" "$history"

report_results
