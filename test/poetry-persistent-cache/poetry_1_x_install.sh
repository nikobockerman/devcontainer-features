#!/bin/bash

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks-lib.sh
source "$(dirname "$0")/checks-lib.sh"

check_feature_setup
check_poetry_install 'poetry<2'

reportResults
