#!/bin/bash

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks.sh
source "$(dirname "$0")/checks.sh"

check_feature_setup

first="echo first-$RANDOM"
second="echo second-$RANDOM"
check "fish resolves its data dir to the symlink" \
    test "$(fish -c "echo \$__fish_user_data_dir")" = "$datadir"
check "fish records history" fish -c "history append '$first'"
check "history is stored on the volume" grep -qF -- "$first" "$mountpoint/fish_history"

# fish rewrites the history file via a temporary file and rename, so a second
# process must keep the first entry and leave the symlinked data dir in place.
check "another fish process records history" fish -c "history append '$second'"
check "history keeps earlier entries" grep -qF -- "$first" "$mountpoint/fish_history"
check "history has the new entry" grep -qF -- "$second" "$mountpoint/fish_history"
check "data dir is still a symlink" test -L "$datadir"

reportResults
