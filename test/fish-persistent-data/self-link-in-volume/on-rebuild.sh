#!/bin/bash

# shellcheck source=SCRIPTDIR/../../../scripts/rebuild-lib.sh
source "$(dirname "$0")/rebuild-lib.sh"

mountpoint=/mnt/fish-persistent-data
history=$HOME/.local/share/fish/fish_history
entry="echo after-rebuild-$REBUILD_TOKEN"

check "self-link in the volume is removed" test ! -L "$mountpoint/fish"
check "nothing is left in its place" test ! -e "$mountpoint/fish"
check "fish data dir links to the volume root" \
    test "$(readlink "$HOME/.local/share/fish")" = "$mountpoint"
check "history from before the rebuild is present" \
    grep -qF -- "echo before-rebuild-$REBUILD_TOKEN" "$history"
check "fish appends to the history" fish -c "history append '$entry'"
check "history has the entry from after the rebuild" \
    grep -qF -- "$entry" "$mountpoint/fish_history"

report_results
