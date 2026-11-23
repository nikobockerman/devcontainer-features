#!/bin/bash

# shellcheck source=SCRIPTDIR/../../../scripts/rebuild-lib.sh
source "$(dirname "$0")/rebuild-lib.sh"

# fish is never run here: 1.x creates its 'fish' subdirectory of the volume
# even then, and leaves it empty.
check "1.x creates its data dir" test -d /mnt/fish-persistent-data/fish
check "1.x leaves its data dir empty" \
    test -z "$(ls -A /mnt/fish-persistent-data/fish)"

report_results
