#!/bin/bash

# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=SCRIPTDIR/checks-lib.sh
source "$(dirname "$0")/checks-lib.sh"

check_feature_setup

file=$HOME/.local/share/man/man1/bandit.1
check "fixture: Dockerfile created $file" test -e "$file"
check "root-owned file is left untouched" test "$(stat -c '%U' "$file")" = root

reportResults
