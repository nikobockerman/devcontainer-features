#!/bin/bash

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks.sh
source "$(dirname "$0")/checks.sh"

check "scenario user's primary group differs from user name" test "$group" != "$user"

check_feature_setup

reportResults
