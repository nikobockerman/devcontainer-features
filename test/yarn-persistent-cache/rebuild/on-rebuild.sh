#!/bin/bash

# shellcheck source=SCRIPTDIR/../../../scripts/rebuild-lib.sh
source "$(dirname "$0")/rebuild-lib.sh"

export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
cd project || exit 1
# Prints the cached archive of is-number version $1.0.0.
cached() {
    find "$YARN_CACHE_FOLDER" -name "is-number-npm-$1.0.0-*.zip" -exec stat -c '%i %Y %n' {} +
}
# Each rebuild adds an older is-number under an alias: 6.0.0 after rebuild
# 1, 5.0.0 after rebuild 2, and so on.
major() {
    echo $((7 - $1))
}

check "cache from before the first rebuild is present" \
    test "$(cat "$YARN_CACHE_FOLDER/rebuild-token")" = "$REBUILD_TOKEN"
check "cached package is the same file" test "$(cached 7)" = "$(cat ../zip-before)"
for ((step = 1; step < REBUILD_STEP; step++)); do
    check "package added after rebuild $step is cached" test -n "$(cached "$(major "$step")")"
done
# Yarn also keeps a copy of what it downloads in its mirror in the home
# directory. The new container starts without it, so an install without
# network can only take the packages from the cache volume.
check "Yarn's mirror is not there in the new container" test ! -e "$HOME/.yarn/berry/cache"
check "yarn install takes every package from the cache" \
    env YARN_ENABLE_NETWORK=0 corepack yarn install --immutable

major=$(major "$REBUILD_STEP")
check "yarn adds a package after rebuild $REBUILD_STEP" \
    corepack yarn add "is-number-v$major@npm:is-number@$major.0.0"
check "the added package is in the cache" test -n "$(cached "$major")"

report_results
