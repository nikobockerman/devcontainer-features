#!/bin/bash

# shellcheck source=SCRIPTDIR/../../../scripts/rebuild-lib.sh
source "$(dirname "$0")/rebuild-lib.sh"

fish -c "history append 'echo from-v1-$REBUILD_TOKEN'"

# 1.x keeps fish data in a 'fish' subdirectory of the volume.
check "1.x writes history to its own layout" \
    grep -qF -- "echo from-v1-$REBUILD_TOKEN" /mnt/fish-persistent-data/fish/fish_history

report_results
