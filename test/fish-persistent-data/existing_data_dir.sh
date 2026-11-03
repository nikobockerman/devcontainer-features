#!/bin/bash

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks.sh
source "$(dirname "$0")/checks.sh"

check_feature_setup

check "existing data dir is kept aside" test -d "$datadir-old"
check "existing data is preserved" grep -qF 'from-image' "$datadir-old/fish_history"

reportResults
