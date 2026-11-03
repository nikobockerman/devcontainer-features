#!/bin/bash

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks.sh
source "$(dirname "$0")/checks.sh"

check "scenario runs as root" test "$(id -u)" = 0
check "scenario image has no sudo" test -z "$(command -v sudo)"

check_feature_setup

reportResults
