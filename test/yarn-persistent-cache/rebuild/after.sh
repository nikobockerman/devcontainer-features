#!/bin/bash

# shellcheck source=SCRIPTDIR/../../../scripts/rebuild-lib.sh
source "$(dirname "$0")/rebuild-lib.sh"

check "cache from before the rebuild is present" \
    test "$(cat "$YARN_CACHE_FOLDER/rebuild-token")" = "$REBUILD_TOKEN"

report_results
