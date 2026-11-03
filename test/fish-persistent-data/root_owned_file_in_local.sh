#!/bin/bash

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks.sh
source "$(dirname "$0")/checks.sh"

check_feature_setup

check "root-owned file is left untouched" \
    test "$(stat -c '%U' "$HOME/.local/share/man/man1/bandit.1")" = root

reportResults
