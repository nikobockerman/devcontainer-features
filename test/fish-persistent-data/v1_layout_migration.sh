#!/bin/bash

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks.sh
source "$(dirname "$0")/checks.sh"

check_feature_setup

check "1.x data is moved to the volume root" grep -qF 'from-v1' "$mountpoint/fish_history"
check "1.x subdirectory is removed" test ! -e "$mountpoint/fish"

reportResults
